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
}

public class SyncManager {
    
    public enum iCloudStatus: String {
        case neverUsed
        case on
        case offWithOldData
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
    }
    
    public func geticloudContainerURL(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        
            SyncManager.iCloudRoot = url
        
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
    
    public func swithiCloud(on willBeOn: Bool, completion: @escaping (Error?) -> Void) {
        if willBeOn {
            switch self.status {
            case .offWithOldData: fallthrough
            case .neverUsed:
                self.moveLocalFilesToIcloud { [weak self] in
                    self?._eventObserver.emit(NowUsingiCloudDocumentsEvent())
                    completion($0)
                }
            case .on: break
            }
        } else {
            switch self.status {
            case .offWithOldData: break
            case .neverUsed: break
            case .on:
                self.moveiCloudFilesToLocal { [ weak self] in
                    self?._eventObserver.emit(NowUsingLocalDocumentsEvent())
                    completion($0)
                }
            }
        }
    }
    
    public var status: iCloudStatus {
        get { return iCloudStatus(rawValue: UserDefaults.standard.string(forKey: "iCloudStatus") ?? "neverUsed")! }
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
        
        queue.async { [unowned queue] in
            group.enter()
            icloudDocumentRoot.deleteIfExists(queue: queue, isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            icloudAttachmentRoot.deleteIfExists(queue: queue, isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            icloudKeyValueStoreRoot.deleteIfExists(queue: queue, isDirectory: true, completion: { _ in
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
        
        queue.async { [unowned queue] in
            group.enter()
            URL.documentBaseURL.deleteIfExists(queue: queue, isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            URL.attachmentURL.deleteIfExists(queue: queue, isDirectory: true, completion: { _ in
                group.leave()
            })
            
            group.enter()
            URL.keyValueStore.deleteIfExists(queue: queue, isDirectory: true, completion: { _ in
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
