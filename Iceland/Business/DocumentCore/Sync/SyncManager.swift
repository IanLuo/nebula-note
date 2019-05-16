//
//  SyncManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

// https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/DocumentBasedAppPGiOS/ResolveVersionConflicts/ResolveVersionConflicts.html

public enum SyncError: Error {
    case syncIsNotEnabled
    case iCloudIsNotAvailable
}

public class SyncManager {
    public enum iCloudStatus: String {
        case unknown // on first launch
        case on
        case off
    }
    
    public enum iCloudAccountStatus {
        case closed
        case open
        case changed
    }
    
    public static private(set) var iCloudRoot: URL? {
        get { return UserDefaults.standard.url(forKey: "_savediCloudFolderRoot") }
        set { UserDefaults.standard.set(newValue, forKey: "_savediCloudFolderRoot") }
    }
    
    public static var iCloudDocumentRoot: URL? {
        return SyncManager.iCloudRoot?.appendingPathComponent("files")
    }
    
    public static var iCloudAttachmentRoot: URL? {
        return self.iCloudRoot?.appendingPathComponent("attachments")
    }
    
    public static var iCloudKeyValueStoreRoot: URL? {
        return self.iCloudRoot?.appendingPathComponent("keyValueStore")
    }
    
    public static var isicloudOn: Bool = false
        
    private let _eventObserver: EventObserver
    
    public init(eventObserver: EventObserver) {
        self._eventObserver = eventObserver
        
//        NotificationCenter.default.addObserver(self, selector: #selector(_iCloudAvailabilityChanged(_:)), name: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil)
    }
    
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//
//    @objc private func _iCloudAvailabilityChanged(_ notification: Notification) {
//
//    }
    
    public func updateCurrentiCloudAccountStatus() -> iCloudAccountStatus {
        let key = "ubiquityIdentityToken"
        let token = FileManager.default.ubiquityIdentityToken
        let savedTokenData = UserDefaults.standard.data(forKey: key)
        
        switch (token, savedTokenData) {
        case (nil, _):
            return .closed
        case let (token?, nil):
            let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
            UserDefaults.standard.setValue(tokenData, forKey: key)
            UserDefaults.standard.synchronize()
            return .open
        case let(token?, oldTokenData?):
            let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
            if tokenData == oldTokenData {
                return .open
            } else {
                let tokenData = NSKeyedArchiver.archivedData(withRootObject: token)
                UserDefaults.standard.setValue(tokenData, forKey: key)
                UserDefaults.standard.synchronize()
                return .changed
            }
        }
    }
    
    public var iCloudAccountStatus: iCloudAccountStatus {
        return updateCurrentiCloudAccountStatus()
    }
    
    public func geticloudContainerURL(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)

            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
    
    public func swithiCloud(on willBeOn: Bool, completion: @escaping (Error?) -> Void) {
        // 1. get the iCloud folder url
        self.geticloudContainerURL { [weak self] url in
            guard let strongSelf = self else { return }
            
            SyncManager.iCloudRoot = url
            
            guard strongSelf.iCloudAccountStatus != .closed else {
                completion(SyncError.iCloudIsNotAvailable)
                return
            }
            
            // 2. move file from/to iCloud folder
            if willBeOn {
                switch strongSelf.status {
                case .unknown: fallthrough
                case .off:
                    strongSelf.moveLocalFilesToIcloud { [weak strongSelf] in
                        // 3. notify to update all url from/to iCloud folder in memory
                        strongSelf?._eventObserver.emit(iCloudOpeningStatusChangedevent(isiCloudEnabled: true))
                        completion($0)
                        strongSelf?.status = .on
                    }
                case .on: break
                }
            } else {
                SyncManager.iCloudRoot = nil
                
                switch strongSelf.status {
                case .off: break
                case .unknown: fallthrough
                case .on:
                    strongSelf.moveiCloudFilesToLocal { [weak strongSelf] in
                        // 3. notify to update all url from/to iCloud folder in memory
                        strongSelf?._eventObserver.emit(iCloudOpeningStatusChangedevent(isiCloudEnabled: false))
                        completion($0)
                        strongSelf?.status = .off
                    }
                }
            }

        }
    }
    
    public var status: iCloudStatus {
        get { return iCloudStatus(rawValue: UserDefaults.standard.string(forKey: "iCloudStatus") ?? "off")! }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "iCloudStatus") }
    }
    
    public func moveLocalFilesToIcloud(completion: @escaping (Error?) -> Void) {

        guard let icloudDocumentRoot = SyncManager.iCloudDocumentRoot,
            let icloudAttachmentRoot = SyncManager.iCloudAttachmentRoot,
        let icloudKeyValueStoreRoot = SyncManager.iCloudKeyValueStoreRoot else {
            completion(SyncError.syncIsNotEnabled)
            return
        }
        
        let queue = DispatchQueue(label: "moveLocalFilesToIcloud")

        let group = DispatchGroup()
        
        queue.async {
            group.enter()
            icloudDocumentRoot.deleteIfExists(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            icloudAttachmentRoot.deleteIfExists(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            icloudKeyValueStoreRoot.deleteIfExists(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), isDirectory: true, completion: { _ in
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background)) {
            do {
                try FileManager.default.setUbiquitous(true, itemAt: URL.documentBaseURL, destinationURL: icloudDocumentRoot)
                try FileManager.default.setUbiquitous(true, itemAt: URL.attachmentURL, destinationURL: icloudAttachmentRoot)
                try FileManager.default.setUbiquitous(true, itemAt: URL.keyValueStore, destinationURL: icloudKeyValueStoreRoot)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func moveiCloudFilesToLocal(completion: @escaping (Error?) -> Void) {
        
        guard let icloudDocumentRoot = SyncManager.iCloudDocumentRoot,
            let icloudAttachmentRoot = SyncManager.iCloudAttachmentRoot,
            let icloudKeyValueStoreRoot = SyncManager.iCloudKeyValueStoreRoot else {
                completion(SyncError.syncIsNotEnabled)
                return
        }
        
        let group = DispatchGroup()
        
        let queue = DispatchQueue(label: "moveLocalFilesToIcloud")
        
        queue.async {
            group.enter()
            URL.documentBaseURL.deleteIfExists(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            URL.attachmentURL.deleteIfExists(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            URL.keyValueStore.deleteIfExists(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background), isDirectory: true, completion: { _ in
                group.leave()
            })
        }
        
        group.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background)) {
            do {
                try FileManager.default.setUbiquitous(false, itemAt: icloudDocumentRoot, destinationURL: URL.documentBaseURL)
                try FileManager.default.setUbiquitous(false, itemAt: icloudAttachmentRoot, destinationURL: URL.attachmentURL)
                try FileManager.default.setUbiquitous(false, itemAt: icloudKeyValueStoreRoot, destinationURL: URL.keyValueStore)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
