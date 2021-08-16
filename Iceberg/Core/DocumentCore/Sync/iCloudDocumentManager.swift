//
//  SyncManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/DocumentBasedAppPGiOS/ResolveVersionConflicts/ResolveVersionConflicts.html

public enum SyncError: Error {
    case syncIsNotEnabled
    case iCloudIsNotAvailable
}

public class iCloudDocumentManager: NSObject {
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
        return iCloudDocumentManager.iCloudRoot?.appendingPathComponent("Documents").appendingPathComponent("files")
    }
    
    public static var iCloudAttachmentRoot: URL? {
        return iCloudDocumentManager.iCloudRoot?.appendingPathComponent("attachments")
    }
    
    public static var iCloudKeyValueStoreRoot: URL? {
        return iCloudDocumentManager.iCloudRoot?.appendingPathComponent("keyValueStore")
    }
    
    public lazy var onDownloadingUpdates: Observable<[URL: Int]> = {
        return _onDownloadingUpdates
            .observe(on: OperationQueueScheduler(operationQueue: OperationQueue()))
            .throttle(RxTimeInterval.seconds(1), scheduler: SerialDispatchQueueScheduler(qos: .background))
    }()
    public let _onDownloadingUpdates: BehaviorRelay<[URL: Int]> = BehaviorRelay(value: [:])
    
    public lazy var onDownloadingCompletes: Observable<URL> = {
        return _onDownloadingCompletes
            .throttle(RxTimeInterval.seconds(1), scheduler: SerialDispatchQueueScheduler(qos: .background))
            .observe(on: OperationQueueScheduler(operationQueue: OperationQueue()))
    }()
    private let _onDownloadingCompletes: PublishSubject<URL> = PublishSubject()

    public var isThereAnyFileUploading: Bool {
        return self.uploadingItemsCache.count > 0
    }
    
    public var isThereAnyFileDownloading: Bool {
        return self.downloadingItemsCache.count > 0
    }
    
    public var isThereAnyFileSyncing: Bool {
        return self.isThereAnyFileUploading || self.isThereAnyFileDownloading
    }
    
    private var uploadingItemsCache: [URL: Any] = [:]
    private var downloadingItemsCache: SyncedDictionary<URL, Any> = [:]
    
    private let _eventObserver: EventObserver
    private lazy var _metadataQuery: NSMetadataQuery = {
        let query = NSMetadataQuery()
        query.delegate = self
        
        query.operationQueue = OperationQueue()
        let predicate = NSPredicate(format: "%K like '*'", NSMetadataItemFSNameKey)
        query.predicate = predicate
        
        query.searchScopes = [NSMetadataQueryUbiquitousDataScope, NSMetadataQueryUbiquitousDocumentsScope]
        return query
    }()
    
    private var metadataQueueUpdateObserver: Any!
    private var metadataQueueStartObserver: Any!
    private var metadataQueueFinishObserver: Any!
    private var metadataQueueProgressObserver: Any!
    private let metadataHandlingQueue: OperationQueue = OperationQueue()
    private let iCloudeDispatchQueue = DispatchQueue(label: "iCloud Queue", qos: DispatchQoS.background, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
    
    public init(eventObserver: EventObserver) {
        self._eventObserver = eventObserver
        
        super.init()
        
        // 这个通知暂时不处理，貌似收不到
//        NotificationCenter.default.addObserver(self, selector: #selector(_iCloudAvailabilityChanged(_:)), name: NSNotification.Name.NSUbiquityIdentityDidChange, object: nil)
        
        self.metadataHandlingQueue.underlyingQueue = self.iCloudeDispatchQueue

        self.metadataQueueUpdateObserver
            = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate,
                                                     object:self._metadataQuery,
                                                     queue: metadataHandlingQueue,
                                                     using: { notification in
                                                        self._metadataQueryDidUpdate(notification)
                                                     })
        
        self.metadataQueueStartObserver
            = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidStartGathering,
                                                     object:self._metadataQuery,
                                                     queue: metadataHandlingQueue,
                                                     using: { notification in
                                                        self._metadataQueryDidStart(notification)
                                                     })
        
        self.metadataQueueFinishObserver
            = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                                                     object:self._metadataQuery,
                                                     queue: metadataHandlingQueue,
                                                     using: { notification in
                                                        self._metadataQueryDidFinish(notification)
                                                     })
        
        self.metadataQueueProgressObserver
            = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryGatheringProgress,
                                                     object:self._metadataQuery,
                                                     queue: metadataHandlingQueue,
                                                     using: { notification in
                                                        self._metadataQueryProgress(notification)
                                                     })
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self.metadataQueueUpdateObserver)
        NotificationCenter.default.removeObserver(self.metadataQueueStartObserver)
        NotificationCenter.default.removeObserver(self.metadataQueueFinishObserver)
        NotificationCenter.default.removeObserver(self.metadataQueueProgressObserver)
    }
//
//    @objc private func _iCloudAvailabilityChanged(_ notification: Notification) {
//          self.startMonitoringiCloudFileUpdateIfNeeded()
//    }
    
    public var allFilesLocal: [URL] {
        let enumerator = FileManager.default.enumerator(at: URL.documentBaseURL, includingPropertiesForKeys: nil)
        var urls: [URL] = []
        
        while let nextObject = enumerator?.nextObject() as? URL {
            urls.append(nextObject)
        }
        
        return urls
    }
    
    public func refreshCurrentiCloudAccountStatus() -> iCloudAccountStatus {
        let key = "ubiquityIdentityToken"
        let token = FileManager.default.ubiquityIdentityToken
        let savedTokenData = UserDefaults.standard.data(forKey: key)
        
        do {
            switch (token, savedTokenData) {
            case (nil, _):
                return .closed
            case let (token?, nil):
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                UserDefaults.standard.setValue(tokenData, forKey: key)
                UserDefaults.standard.synchronize()
                return .open
            case let(token?, oldTokenData?):
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                if tokenData == oldTokenData {
                    return .open
                } else {
                    let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                    UserDefaults.standard.setValue(tokenData, forKey: key)
                    UserDefaults.standard.synchronize()
                    return .changed
                }
            }
        } catch {
            log.error(error)
            return .closed
        }
    }
    
    public var iCloudAccountStatus: iCloudAccountStatus {
        return refreshCurrentiCloudAccountStatus()
    }
    
    public func geticloudContainerURL() -> URL? {
        let url = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        iCloudDocumentManager.iCloudRoot = url
        return url
    }
    
    public func startMonitoringiCloudFileUpdateIfNeeded() {
        self._metadataQuery.operationQueue?.addOperation {
            self._metadataQuery.start()
        }
        
    }
    
    public func stopMonitoringiCloudFildUpdateIfNeeded() {
        self._metadataQuery.operationQueue?.addOperation {
            self._metadataQuery.stop()
        }
    }
    
    /// turn on, move local to iCloud, otherwise, move iCloud to local
    public func swithiCloud(on willBeOn: Bool, completion: @escaping (Error?) -> Void) {
        // 1. get the iCloud folder url
        let url = self.geticloudContainerURL()
        
        iCloudDocumentManager.iCloudRoot = url
        
        guard self.iCloudAccountStatus != .closed else {
            completion(SyncError.iCloudIsNotAvailable)
            return
        }
        
        // 2. move file from/to iCloud folder
        if willBeOn {
            switch iCloudDocumentManager.status {
            case .unknown: fallthrough
            case .off:
                self.moveLocalFilesToIcloud { [weak self] error in
                    // 3. notify to update all url from/to iCloud folder in memory
                    if let error = error {
                        log.error(error)
                        completion(error)
                    } else {
                        completion(nil)
                        iCloudDocumentManager.status = .on
                        self?.startMonitoringiCloudFileUpdateIfNeeded()
                        self?._eventObserver.emit(iCloudOpeningStatusChangedEvent(isiCloudEnabled: true))
                    }
                }
            case .on:
                completion(nil)
            }
        } else {
            switch iCloudDocumentManager.status {
            case .off:
                completion(nil)
            case .unknown: fallthrough
            case .on:
                self.moveiCloudFilesToLocal { [weak self] error in
                    // 3. notify to update all url from/to iCloud folder in memory
                    if let error = error {
                        log.error(error)
                        completion(error)
                    } else {
                        completion(nil)
                        iCloudDocumentManager.status = .off
                        self?.stopMonitoringiCloudFildUpdateIfNeeded()
                        self?._eventObserver.emit(iCloudOpeningStatusChangedEvent(isiCloudEnabled: false))
                    }
                }
            }
            
        }
    }
    
    public static var status: iCloudStatus {
        get { return iCloudStatus(rawValue: UserDefaults.standard.string(forKey: "iCloudStatus") ?? "unknown")! }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "iCloudStatus")
            UserDefaults.standard.synchronize()
            StoreContainer.shared.reset()
        }
    }
    
    /// move local files to iCloud folder, if there already old file exists, overrid it
    public func moveLocalFilesToIcloud(completion: @escaping (Error?) -> Void) {

        // if there's no root folders for documents, attachment, and key value store folder, means sync is not enabled, ignore
        guard let icloudDocumentRoot = iCloudDocumentManager.iCloudDocumentRoot,
            let icloudAttachmentRoot = iCloudDocumentManager.iCloudAttachmentRoot,
        let icloudKeyValueStoreRoot = iCloudDocumentManager.iCloudKeyValueStoreRoot else {
            completion(SyncError.syncIsNotEnabled)
            return
        }
        
        // the queue for perform moving files action
        let queue = DispatchQueue(label: "move local files to iCloud")

        queue.async {
            self.stopMonitoringiCloudFildUpdateIfNeeded()
            
            do {
                var isDir = ObjCBool(true)
                
                log.info("start moving from local to iCloud(\(icloudDocumentRoot))...")
                // move local documents folder to icloud document folder, and keep the files in it's place in local
                if FileManager.default.fileExists(atPath: URL.localDocumentBaseURL.path, isDirectory: &isDir) {
                    for path in try self.allPaths(in: URL.localDocumentBaseURL) {
                        
                        // use the documents folder related path, of all contents inside documents file, combine to iCloud base folder, to get a destination of move to iCloud action destination url
                        let destination = icloudDocumentRoot.appendingPathComponent(path)
                        
                        if FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDir) {
                            log.info("there's an old file existed, replace it")
                            try FileManager.default.removeItem(at: destination)
                        }
                        
                        log.info("moving \(path) to \(destination)")
                        
                        // in case the file is not at root of iCloud documents folder, and the parent's folder not created, then create it
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        // do the moving action
                        try FileManager.default.setUbiquitous(true,
                                                              itemAt: URL.localDocumentBaseURL.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                log.info("start moving from local to iCloud(\(icloudAttachmentRoot))...")
                // move local attachments to iCloud attachment folder
                if FileManager.default.fileExists(atPath: URL.localAttachmentURL.path, isDirectory: &isDir) {
                    for path in try self.allPaths(in: URL.localAttachmentURL) {
                        let destination = icloudAttachmentRoot.appendingPathComponent(path)
                        
                        if FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDir) {
                            log.info("there's an old file existed, replace it")
                            try FileManager.default.removeItem(at: destination)
                        }
                        
                        log.info("moving \(path) to \(destination)")
                        
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.setUbiquitous(true,
                                                              itemAt: URL.localAttachmentURL.appendingPathComponent(path),
                                                              destinationURL: destination)
                    }
                }
                
                log.info("start moving from local to iCloud(\(icloudKeyValueStoreRoot))...")
                // move local key values store files to iCloud key value store folder
                if FileManager.default.fileExists(atPath: URL.localKeyValueStoreURL.path, isDirectory: &isDir) {
                    for path in try self.allPaths(in: URL.localKeyValueStoreURL) {
                        var isDir: ObjCBool = ObjCBool(false)
                        let destination = icloudKeyValueStoreRoot.appendingPathComponent(path)
                        
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        log.info("moving \(path) to \(destination)")
                        
                        if FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDir) {
                            log.info("there's an old file existed for \(destination.path), merge it")
                            let originalFile: URL = URL.localKeyValueStoreURL.appendingPathComponent(path)
                            let mergedFileURL: URL = mergePlistFiles(name: originalFile.deletingPathExtension().lastPathComponent.removeFirstSplashIfThereIsAny, url1: originalFile, url2: destination)
                            _ = try FileManager.default.replaceItemAt(originalFile, withItemAt: mergedFileURL)
                            _ = try FileManager.default.removeItem(at: destination)
                            try FileManager.default.setUbiquitous(true,
                                                                  itemAt: originalFile,
                                                                  destinationURL: destination)
                        } else {
                            try FileManager.default.setUbiquitous(true,
                                                                  itemAt: URL.localKeyValueStoreURL.appendingPathComponent(path),
                                                                  destinationURL: destination)
                        }
                    }
                }
                
                self.startMonitoringiCloudFileUpdateIfNeeded()
                completion(nil)
            } catch {
                self.startMonitoringiCloudFileUpdateIfNeeded()
                completion(error)
            }
        }
    }
    
    /// move iCloud files to local folder
    public func moveiCloudFilesToLocal(completion: @escaping (Error?) -> Void) {
        
        // if there's no root folders for documents, attachment, and key value store folder, means sync is not enabled, ignore
        guard let icloudDocumentRoot = iCloudDocumentManager.iCloudDocumentRoot,
            let icloudAttachmentRoot = iCloudDocumentManager.iCloudAttachmentRoot,
            let icloudKeyValueStoreRoot = iCloudDocumentManager.iCloudKeyValueStoreRoot else {
                completion(SyncError.syncIsNotEnabled)
                return
        }
        
        let queue = DispatchQueue(label: "move iCloud file to local")
        
        queue.async {
            
            do {
                var isDir = ObjCBool(true)
                
                log.info("start moving from iCloud(\(icloudDocumentRoot)) to local...")
                if FileManager.default.fileExists(atPath: icloudDocumentRoot.path, isDirectory: &isDir) {
                    for path in try self.allPaths(in: icloudDocumentRoot) {
                        let destination = URL.localDocumentBaseURL.appendingPathComponent(path)

                        if FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDir) {
                            log.info("there's an old file existed, replace it")
                            try FileManager.default.removeItem(at: destination)
                        }
                        
                        log.info("moving \(path) to \(destination)")

                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.copyItem(at: icloudDocumentRoot.appendingPathComponent(path),
                                                         to: destination)
                        
                    }
                }
                
                log.info("start moving from iCloud(\(icloudAttachmentRoot)) to local...")
                if FileManager.default.fileExists(atPath: icloudAttachmentRoot.path, isDirectory: &isDir) {
                    for path in try self.allPaths(in: icloudAttachmentRoot) {
                        let destination = URL.localAttachmentURL.appendingPathComponent(path)

                        if FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDir) {
                            log.info("there's an old file existed, replace it")
                            try FileManager.default.removeItem(at: destination)
                        }
                        
                        log.info("moving \(path) to \(destination)")
                        
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        try FileManager.default.copyItem(at: icloudAttachmentRoot.appendingPathComponent(path),
                                                         to: destination)
                    }
                }
                
                log.info("start moving from iCloud(\(icloudKeyValueStoreRoot)) to local...")
                if FileManager.default.fileExists(atPath: icloudKeyValueStoreRoot.path, isDirectory: &isDir) {
                    for path in try self.allPaths(in: icloudKeyValueStoreRoot) {
                        let destination = URL.localKeyValueStoreURL.appendingPathComponent(path)
                        // create intermiea folder if needed
                        try self._createIntermiaFoldersIfNeeded(url: destination)
                        
                        log.info("moving \(path) to \(destination)")
                        if FileManager.default.fileExists(atPath: destination.path) {
                            log.info("there's an old file existed for \(destination.path), merge it")
                            let originalFile: URL = icloudKeyValueStoreRoot.appendingPathComponent(path)
                            let mergedFileURL: URL = mergePlistFiles(name: originalFile.deletingPathExtension().lastPathComponent.removeFirstSplashIfThereIsAny, url1: originalFile, url2: destination)
                            _ = try FileManager.default.replaceItemAt(originalFile, withItemAt: mergedFileURL)
                            try FileManager.default.removeItem(at: destination)
                            try FileManager.default.copyItem(at: icloudKeyValueStoreRoot.appendingPathComponent(path), to: destination)
                        } else {
                            
                            try FileManager.default.copyItem(at: icloudKeyValueStoreRoot.appendingPathComponent(path), to: destination)
                        }
                        
                    }
                }
                
                if FileManager.default.fileExists(atPath: icloudDocumentRoot.path) {
                    try FileManager.default.removeItem(at: icloudDocumentRoot)
                }
                
                if FileManager.default.fileExists(atPath: icloudAttachmentRoot.path) {
                    try FileManager.default.removeItem(at: icloudAttachmentRoot)
                }
                
                if FileManager.default.fileExists(atPath: icloudKeyValueStoreRoot.path) {
                    try FileManager.default.removeItem(at: icloudKeyValueStoreRoot)
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
    public func allPaths(in folder: URL) throws -> [String] {
        let folder = folder.resolvingSymlinksInPath()
        var urls: [String] = []
        let keys: [URLResourceKey] = [.isPackageKey, .isDirectoryKey]
        let enumerator = FileManager.default.enumerator(at: folder,
                                       includingPropertiesForKeys: keys,
                                       options: [.skipsPackageDescendants], errorHandler: nil)
        
        while let url = enumerator?.nextObject() as? URL {
            log.info("found url: \(url)")
            
            let name = url.lastPathComponent
            
            if name.hasPrefix(".") && !name.hasPrefix(SyncCoordinator.Prefix.deleted.rawValue) {
                continue
            }
            
            // if the url is a symbolic link, resove it
            let url = url.resolvingSymlinksInPath()
            // get the file resource properties, including 'isPackageKey' and 'isDirectoryKey'
            let resouece = try url.resourceValues(forKeys: Set(keys))
            // if the url is a directory, and the path extension is document's extension, which means a wrapped document, skip the contents, and add the url to return
            if resouece.isDirectory! && url.pathExtension == Document.fileExtension {
                enumerator?.skipDescendants()
                // before return, remove the first part of url only keep the related path to the passed in folder
                urls.append(url.path.replacingOccurrences(of: folder.path, with: "").removeFirstSplashIfThereIsAny)
                
            // add attachment wrapped director to return, ignore it's contents
            } else if resouece.isDirectory! && url.pathExtension == AttachmentDocument.fileExtension {
                enumerator?.skipDescendants()
                // before return, remove the first part of url only keep the related path to the passed in folder
                urls.append(url.path.replacingOccurrences(of: folder.path, with: "").removeFirstSplashIfThereIsAny)
                
            // any file that's not a directory, add to return
            } else if resouece.isDirectory == false {
                // before return, remove the first part of url only keep the related path to the passed in folder
                urls.append(url.path.replacingOccurrences(of: folder.path, with: "").removeFirstSplashIfThereIsAny)
            }
        }
        
        return urls
    }
}

extension String {
    var removeFirstSplashIfThereIsAny: String {
        if self.hasPrefix("/") {
            return self.nsstring.substring(from: 1)
        } else {
            return self
        }
    }
}

extension iCloudDocumentManager: NSMetadataQueryDelegate {
   
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
                    
                    // add to uploading cache
                    if self.uploadingItemsCache[url] == nil {
                        self.uploadingItemsCache[url] = url
                    }
                }
                
                if item.isUploaded == true && self.uploadingItemsCache[url] != nil {
                    self.uploadingItemsCache[url] = nil
                    log.info("uploading complete: \(url)")
                }
                
                if let downloadingError = item.downloadingError {
                    log.error("downloading error: \(downloadingError)")
                }
                
                if let uploadingError = item.uploadingError {
                    log.error("uploadingError error: \(uploadingError)")
                }
            }
        }
        
        if let addedItems = notification.userInfo?["kMDQueryUpdateAddedItems"] as? [NSMetadataItem], addedItems.count > 0 {
            log.info("found \(addedItems.count) added items")
            handleItemsAction(addedItems)
        }
        
        if let removedItems = notification.userInfo?["kMDQueryUpdateRemovedItems"] as? [NSMetadataItem], removedItems.count > 0 {
            log.info("found \(removedItems.count) removed items (\(removedItems.map { $0.url }))")
            
            for item in removedItems {
                if let url = item.url {
                    self._eventObserver.emit(DocumentRemovedFromiCloudEvent(url: url))
                }
            }
        }
        
        if let changedItems = notification.userInfo?["kMDQueryUpdateChangedItems"] as? [NSMetadataItem], changedItems.count > 0 {
//            log.info("found \(changedItems.count) changed items")
            handleItemsAction(changedItems)
        }
        
        self._metadataQuery.enableUpdates()
    }
    
    @objc private func _metadataQueryDidStart(_ notification: Notification) {
        log.info("_metadataQueryDidStart")
    }
    
    @objc private func _metadataQueryDidFinish(_ notification: Notification) {
        log.info("_metadataQueryDidFinish")
        let items: [NSMetadataItem] = ((notification.object as? NSMetadataQuery)?.results as? [NSMetadataItem]) ?? []
        for item in items {
        
            self._tryToDownload(item: item)
            
            // check if there's any file need to add to cache
            // 1. add to uploading cache
            // 2. downloading cache is handled above '_tryToDownload(item:)'
            if let url = item.url, item.isUploading == true {
                self.uploadingItemsCache[url] = url
            }
            
            self.handleConflictIfNeeded(item: item)
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
        
        let handleDocumentDownloadCompletion: () -> Void = {
            
            guard self.downloadingItemsCache[url] != nil else { return }
            
            self.downloadingItemsCache[url] = nil
            self._onDownloadingCompletes.onNext(url)
            
            self.handleConflictIfNeeded(item: item)
            
            log.info("** complete download: \(item.fileName ?? "") size:(\(item.fileSize ?? 0)) **")
            if url.pathExtension == Document.fileExtension {
                self._eventObserver.emit(NewDocumentPackageDownloadedEvent(url: url))
            } else if url.pathExtension == "plist" {
                if let fileName = item.fileName {
                    switch fileName {
                    case CaptureService.plistFileName + ".plist":
                        self._eventObserver.emit(NewCaptureListDownloadedEvent(url: url))
                    default: break
                    }
                }
            } else if url.pathExtension == AttachmentDocument.fileExtension {
                self._eventObserver.emit(NewAttachmentDownloadedEvent(url: url))
            }
        }
        
        if item.isDownloaded == true && self.downloadingItemsCache[url] != nil {
            handleDocumentDownloadCompletion()
        }
        
        if let isDownloading = item.isDownloading, isDownloading == true,
            let downloadPercent = item.downloadPercentage,
            let downloadSize = item.downloadingSize {
            log.info("downloading \(url) (\(downloadPercent)%), (\(downloadSize))")
            
            var downloadingItems: [URL: Int] = self._onDownloadingUpdates.value

            if item.downloadPercentage == 100 {
                handleDocumentDownloadCompletion()
            } else {
                downloadingItems[url] = downloadPercent
            }
            
            if self.downloadingItemsCache[url] == nil {
                self.downloadingItemsCache[url] = url
            }
            
            self._onDownloadingUpdates.accept(downloadingItems)
        }
                
    }
    
    private func handleConflictIfNeeded(item: NSMetadataItem) {
        if item.isInConflict == true {
            if let url = item.url {
                // only handle plist
                guard url.pathExtension == "plist" else { return }
                
                let version = NSFileVersion.currentVersionOfItem(at: url)
                let name = url.deletingPathExtension().lastPathComponent
                if let otherVersions = NSFileVersion.otherVersionsOfItem(at: url) {
                    for v in otherVersions {
                        let temp = mergePlistFiles(name: name, url1: url, url2: v.url)
                        try? v.remove()
                        do {
                            _ = try FileManager.default.replaceItemAt(url, withItemAt: temp)
                        } catch {
                            print(error)
                        }
                    }
                }
                
                version?.isResolved = true
            }
        }
    }
}

