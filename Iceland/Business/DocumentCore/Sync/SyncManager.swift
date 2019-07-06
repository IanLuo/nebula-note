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

public class SyncManager: NSObject {
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
        return SyncManager.iCloudRoot?.appendingPathComponent("files").resolvingSymlinksInPath()
    }
    
    public static var iCloudAttachmentRoot: URL? {
        return self.iCloudRoot?.appendingPathComponent("attachments").resolvingSymlinksInPath()
    }
    
    public static var iCloudKeyValueStoreRoot: URL? {
        return self.iCloudRoot?.appendingPathComponent("keyValueStore").resolvingSymlinksInPath()
    }
    
    private let _eventObserver: EventObserver
    private lazy var _metadataQuery: NSMetadataQuery = {
        let query = NSMetadataQuery()
        query.delegate = self
        
        let predicate = NSPredicate(format: "%K like '*'", NSMetadataItemFSNameKey)
        query.predicate = predicate
        
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope]
        return query
    }()
    
    public init(eventObserver: EventObserver) {
        self._eventObserver = eventObserver
        
        super.init()
        
        // 这个通知暂时不处理，貌似收不到
//        NotificationCenter.default.addObserver(self, selector: #selector(_iCloudAvailabilityChanged(_:)), name: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(_metadataQueryDidUpdate(_ :)),
                                               name: NSNotification.Name.NSMetadataQueryDidUpdate, object: self._metadataQuery)
        NotificationCenter.default.addObserver(self, selector: #selector(_metadataQueryDidStart(_ :)),
                                               name: NSNotification.Name.NSMetadataQueryDidStartGathering, object: self._metadataQuery)
        NotificationCenter.default.addObserver(self, selector: #selector(_metadataQueryDidFinish(_ :)),
                                               name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: self._metadataQuery)
        NotificationCenter.default.addObserver(self, selector: #selector(_metadataQueryProgress(_ :)),
                                               name: NSNotification.Name.NSMetadataQueryGatheringProgress, object: self._metadataQuery)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
//
//    @objc private func _iCloudAvailabilityChanged(_ notification: Notification) {
//          self.startMonitoringiCloudFileUpdateIfNeeded()
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
            SyncManager.iCloudRoot = url
            DispatchQueue.main.async {
                completion(url)
            }
        }
    }
    
    public func startMonitoringiCloudFileUpdateIfNeeded() {
        self._metadataQuery.start()
    }
    
    public func stopMonitoringiCloudFildUpdateIfNeeded() {
        self._metadataQuery.stop()
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
                switch SyncManager.status {
                case .unknown: fallthrough
                case .off:
                    strongSelf.moveLocalFilesToIcloud { [weak strongSelf] error in
                        // 3. notify to update all url from/to iCloud folder in memory
                        if let error = error {
                            log.error(error)
                            completion(error)
                        } else {
                            completion(nil)
                            strongSelf?._eventObserver.emit(iCloudOpeningStatusChangedEvent(isiCloudEnabled: true))
                            SyncManager.status = .on
                            strongSelf?.startMonitoringiCloudFileUpdateIfNeeded()
                        }
                    }
                case .on:
                    completion(nil)
                }
            } else {
                switch SyncManager.status {
                case .off:
                    completion(nil)
                case .unknown: fallthrough
                case .on:
                    strongSelf.moveiCloudFilesToLocal { [weak strongSelf] error in
                        // 3. notify to update all url from/to iCloud folder in memory
                        if let error = error {
                            log.error(error)
                            completion(error)
                        } else {
                            completion(nil)
                            strongSelf?._eventObserver.emit(iCloudOpeningStatusChangedEvent(isiCloudEnabled: false))
                            SyncManager.status = .off
                            strongSelf?.stopMonitoringiCloudFildUpdateIfNeeded()
                        }
                    }
                }
            }

        }
    }
    
    public static var status: iCloudStatus {
        get { return iCloudStatus(rawValue: UserDefaults.standard.string(forKey: "iCloudStatus") ?? "unknown")! }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "iCloudStatus") }
    }
    
    /// move local files to iCloud folder, if there already old file exists, overrid it
    public func moveLocalFilesToIcloud(completion: @escaping (Error?) -> Void) {

        // if there's no root folders for documents, attachment, and key value store folder, means sync is not enabled, ignore
        guard let icloudDocumentRoot = SyncManager.iCloudDocumentRoot,
            let icloudAttachmentRoot = SyncManager.iCloudAttachmentRoot,
        let icloudKeyValueStoreRoot = SyncManager.iCloudKeyValueStoreRoot else {
            completion(SyncError.syncIsNotEnabled)
            return
        }
        
        // the queue for perform moving files action
        let queue = DispatchQueue(label: "move local files to iCloud")

        queue.async {
            do {
                var isDir = ObjCBool(true)
                
                // move local documents folder to icloud document folder, and keep the files in it's place in local
                if FileManager.default.fileExists(atPath: URL.localDocumentBaseURL.path, isDirectory: &isDir) {
                    for path in try self._allPaths(in: URL.localDocumentBaseURL) {
                        
                        // use the documents folder related path, of all contents inside documents file, combine to iCloud base folder, to get a destination of move to iCloud action destination url
                        let destination = icloudDocumentRoot.appendingPathComponent(path)
                        
                        // in case the file is not at root of iCloud documents folder, and the parent's folder not created, then create it
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        // do the moving action
                        try FileManager.default.setUbiquitous(true,
                                                              itemAt: URL.localDocumentBaseURL.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                // move local attachments to iCloud attachment folder
                if FileManager.default.fileExists(atPath: URL.localAttachmentURL.path, isDirectory: &isDir) {
                    for path in try self._allPaths(in: URL.localAttachmentURL) {
                        let destination = icloudAttachmentRoot.appendingPathComponent(path)
                        
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.setUbiquitous(true,
                                                              itemAt: URL.localAttachmentURL.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                // move local key values store files to iCloud key value store folder
                if FileManager.default.fileExists(atPath: URL.localKeyValueStoreURL.path, isDirectory: &isDir) {
                    for path in try self._allPaths(in: URL.localKeyValueStoreURL) {
                        let destination = icloudKeyValueStoreRoot.appendingPathComponent(path)
                        
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.setUbiquitous(true,
                                                              itemAt: URL.localKeyValueStoreURL.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    /// move iCloud files to local folder
    public func moveiCloudFilesToLocal(completion: @escaping (Error?) -> Void) {
        
        // if there's no root folders for documents, attachment, and key value store folder, means sync is not enabled, ignore
        guard let icloudDocumentRoot = SyncManager.iCloudDocumentRoot,
            let icloudAttachmentRoot = SyncManager.iCloudAttachmentRoot,
            let icloudKeyValueStoreRoot = SyncManager.iCloudKeyValueStoreRoot else {
                completion(SyncError.syncIsNotEnabled)
                return
        }
        
        let queue = DispatchQueue(label: "move iCloud file to local")
        
        queue.async {
            do {
                var isDir = ObjCBool(true)
                
                if FileManager.default.fileExists(atPath: icloudDocumentRoot.path, isDirectory: &isDir) {
                    for path in try self._allPaths(in: icloudDocumentRoot) {
                        let destination = URL.localDocumentBaseURL.appendingPathComponent(path)
                        
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.setUbiquitous(false,
                                                              itemAt: icloudDocumentRoot.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                if FileManager.default.fileExists(atPath: icloudAttachmentRoot.path, isDirectory: &isDir) {
                    for path in try self._allPaths(in: icloudAttachmentRoot) {
                        let destination = URL.localAttachmentURL.appendingPathComponent(path)

                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.setUbiquitous(false,
                                                              itemAt: icloudAttachmentRoot.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                if FileManager.default.fileExists(atPath: icloudKeyValueStoreRoot.path, isDirectory: &isDir) {
                    for path in try self._allPaths(in: icloudKeyValueStoreRoot) {
                        let destination = URL.localKeyValueStoreURL.appendingPathComponent(path)
                        // create intermiea folder if needed
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.setUbiquitous(false,
                                                              itemAt: icloudKeyValueStoreRoot.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    private func _createIntermiaFoldersIfNeeded(url: URL) throws {
        let folder = url.deletingLastPathComponent()
        var isDir = ObjCBool(true)
        if !FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDir) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    /// find all file paths under the specifiled url (which is a folder)
    private func _allPaths(in folder: URL) throws -> [String] {
        var urls: [String] = []
        let keys: [URLResourceKey] = [.isPackageKey, .isDirectoryKey]
        let enumerator = FileManager.default.enumerator(at: folder,
                                       includingPropertiesForKeys: keys,
                                       options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: nil)
        
        while let url = enumerator?.nextObject() as? URL {
            // if the url is a symbolic link, resove it
            let url = url.resolvingSymlinksInPath()
            // get the file resource properties, including 'isPackageKey' and 'isDirectoryKey'
            let resouece = try url.resourceValues(forKeys: Set(keys))
            // if the url is a directory, and the path extension is document's extension, which means a wrapped document, skip the contents, and add the url to return
            if resouece.isDirectory! && url.pathExtension == Document.fileExtension {
                enumerator?.skipDescendants()
                // before return, remove the first part of url only keep the related path to the passed in folder
                urls.append(url.path.replacingOccurrences(of: folder.path, with: ""))
                
            // add attachment wrapped director to return, ignore it's contents
            } else if resouece.isDirectory! && url.pathExtension == AttachmentDocument.fileExtension {
                enumerator?.skipDescendants()
                // before return, remove the first part of url only keep the related path to the passed in folder
                urls.append(url.path.replacingOccurrences(of: folder.path, with: ""))
                
            // any file that's not a directory, add to return
            } else if resouece.isDirectory == false {
                // before return, remove the first part of url only keep the related path to the passed in folder
                urls.append(url.path.replacingOccurrences(of: folder.path, with: ""))
            }
        }
        
        return urls
    }
}

extension SyncManager: NSMetadataQueryDelegate {
   
    @objc private func _metadataQueryDidUpdate(_ notification: Notification) {
        self._metadataQuery.disableUpdates()
        
        let handleItemsAction: ([NSMetadataItem]) -> Void = { items in
            for item in items {
                guard let url = item.url else { continue }
                
                self._tryToDownload(item: item)
                
                if let isUploading = item.isUploading, isUploading == true,
                    let uploadPercent = item.uploadPercentage,
                    let uploadSize = item.uploadingSize {
                    log.info("uploading \(url) (\(uploadPercent)%) (\(uploadSize))")
                }
                
                if let downloadingError = item.downloadingError {
                    log.error("downloading error: \(downloadingError)")
                }
                
                if let uploadingError = item.uploadingError {
                    log.error("uploadingError error: \(uploadingError)")
                }
            }
        }
        
        if let addedItems = notification.userInfo?["kMDQueryUpdateAddedItems"] as? [NSMetadataItem] {
            log.info("found \(addedItems.count) added items")
            handleItemsAction(addedItems)
        }
        
        if let removedItems = notification.userInfo?["kMDQueryUpdateRemovedItems"] as? [NSMetadataItem] {
            log.info("found  \(removedItems.count) removed items")
            handleItemsAction(removedItems)
        }
        
        if let changedItems = notification.userInfo?["kMDQueryUpdateChangedItems"] as? [NSMetadataItem] {
            log.info("found \(changedItems) changed items")
            handleItemsAction(changedItems)
        }
        
        self._metadataQuery.enableUpdates()
    }
    
    @objc private func _metadataQueryDidStart(_ notification: Notification) {
        log.info("_metadataQueryDidStart")
    }
    
    @objc private func _metadataQueryDidFinish(_ notification: Notification) {
        log.info("_metadataQueryDidFinish")
        for item in ((notification.object as? NSMetadataQuery)?.results) ?? [] {
            
            if let item = item as? NSMetadataItem {
                self._tryToDownload(item: item)
            }
        }
    }
    
    @objc private func _metadataQueryProgress(_ notification: Notification) {
        log.info("_metadataQueryProgress")
    }
    
    private func _tryToDownload(item: NSMetadataItem) {
        guard let url = item.url else { return }
        
        if item.isDownloadingRequested == false && item.downloadingStatus == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded {
            do {
                log.info("begin to download: \(url)")
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            } catch {
                log.error("failed to download: \(url)")
            }
        }
        
        if item.downloadingStatus == NSMetadataUbiquitousItemDownloadingStatusDownloaded {
            if item.isDownloading == true && item.downloadPercentage == 100 {
                if url.pathExtension == Document.fileExtension {
                    self._eventObserver.emit(NewDocumentPackageDownloadedEvent(url: url))
                } else if url.pathExtension == "plist" {
                    if let fileName = item.fileName {
                        switch fileName {
                        case CaptureService.plistFileName + ".plist":
                            self._eventObserver.emit(NewCaptureListDownloadedEvent(url: url))
                        case RecentFilesManager.recentFilesPlistFileName + ".plist":
                            self._eventObserver.emit(NewRecentFilesListDownloadedEvent(url: url))
                        default: break
                        }
                    }
                } else if url.pathExtension == AttachmentDocument.fileExtension {
                    self._eventObserver.emit(NewAttachmentDownloadedEvent(url: url))
                }
            }
        }
        
        if let isDownloading = item.isDownloading, isDownloading == true,
            let downloadPercent = item.downloadPercentage,
            let downloadSize = item.downloadingSize {
            log.info("downloading \(url) (\(downloadPercent)%), (\(downloadSize))")
        }
        
    }
}

