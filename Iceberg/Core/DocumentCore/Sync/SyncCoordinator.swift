//
//  DocumentSyncCoordinator.swift
//  Business
//
//  Created by ian luo on 2019/11/27.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public protocol SyncManagerProtocol {
    var isReadyToUse: Bool { get }
    var remoteRoot: URL? { get }
    var remoteFileRelativePaths: [String] { get }
    func `switch`(_ on: Bool, complete: @escaping (Bool) -> Void)
    func urlForRelativePath(_ path: String) -> URL?
}

public protocol Syncable {
    var lastModifyOrCreateTimeStamp: TimeInterval { get }
}

extension URL: Syncable {
    public var lastModifyOrCreateTimeStamp: TimeInterval {
        // if modifed date not there, use create, if none there, use distant past
        guard let resources = try? self.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey, URLResourceKey.creationDateKey]),
            let modifyDateTimeInterval = (resources.contentModificationDate ?? resources.creationDate)
            else { return Date.distantPast.timeIntervalSince1970 }
        
        return modifyDateTimeInterval.timeIntervalSince1970
    }
    
    public var lastModifyTimeStamp: TimeInterval? {
        guard let resources = try? self.resourceValues(forKeys: [URLResourceKey.contentModificationDateKey, URLResourceKey.creationDateKey]) else { return nil }
        return resources.contentModificationDate?.timeIntervalSince1970 ?? resources.creationDate?.timeIntervalSince1970
    }
    
    public var lastOpenedStamp: TimeInterval? {
        guard let resources = try? self.resourceValues(forKeys: [URLResourceKey.contentAccessDateKey, .creationDateKey]) else { return nil }
        return resources.contentAccessDate?.timeIntervalSince1970 ?? resources.creationDate?.timeIntervalSince1970
    }
}

public class SyncCoordinator {
    public enum Prefix: String {
        case deleted = ".Deleted__"
        case renamed = "Renamed__"
        
        public func createURL(for url: URL) -> URL {
            return url.deletingLastPathComponent().appendingPathComponent((self.rawValue + url.lastPathComponent))
        }
    }
    
    /// add a empty file with the renamed file, to incidator the old file is renamed, used for sync
//    public static func createRenamedIndicatorFile(for url: URL) {
//        try! Data().write(to: Prefix.renamed.createURL(for: url))
//    }

    public struct SyncStatus {
        let successURLs: [URL]
        let failureURLs: [URL]
    }
    
    public struct SyncResult {
        let syncUp: SyncStatus
        let syncDown: SyncStatus
    }
        
    private let availableSyncDestinations: [SyncManagerProtocol]
    private let _eventObserver: EventObserver
    
    public init(eventObserver: EventObserver) {
        self._eventObserver = eventObserver
        self.availableSyncDestinations = [iCloudSyncManager(iCloudDocumentManager: iCloudDocumentManager(eventObserver: eventObserver))]
        
        eventObserver.registerForEvent(on: self,
                                        eventType: iCloudOpeningStatusChangedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                            self?.sync()
        })
        
        eventObserver.registerForEvent(on: self,
                                        eventType: NewDocumentPackageDownloadedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
                                            self?.sync()
        })
        
        eventObserver.registerForEvent(on: self,
                                        eventType: DocumentRemovedFromiCloudEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: DocumentRemovedFromiCloudEvent) in
                                            self?.handleRemoveFileFromCloud(url: event.url)
        })
        
        eventObserver.registerForEvent(on: self,
                                        eventType: DeleteDocumentEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: DeleteDocumentEvent) in
                                            self?.handleRemoveFileFromLocal(url: event.url)
        })
    }
    
    public func syncUp(completion: @escaping (SyncStatus) -> Void) {
        let fileManager = FileManager.default
        
        var successfuleSyncDownURLs: [URL] = []
        var failureSyncDownURLs: [URL] = []
        var doCopyToRemote: (([String]) -> Void)!
        
        for syncManager in availableSyncDestinations {
            
            let relativeFilesToSyncUp = self.findRelativeFilePathsToSyncUp(remoteSyncManager: syncManager, localFiles: self.loadLocalFiles())
            
            log.info("found files to upload to iCloud: \(relativeFilesToSyncUp)")
            
            guard let remoteRootURL = syncManager.remoteRoot else { continue }
            
            doCopyToRemote = { relativeFilePaths in
                
                guard let relativeFilePath = relativeFilePaths.first else { completion(SyncStatus(successURLs: successfuleSyncDownURLs, failureURLs: failureSyncDownURLs)); return }
                
                let localFileURL = URL.localRootURL.appendingPathComponent(relativeFilePath)
                let copyToURL = remoteRootURL.appendingPathComponent(relativeFilePath)
                
                let dir = copyToURL.deletingLastPathComponent()
                dir.createDirectoryIfNeeded { error in
                    do {
                        if fileManager.fileExists(atPath: copyToURL.path, isDirectory: nil) {
                            _ = try fileManager.replaceItemAt(copyToURL, withItemAt: localFileURL)
                        } else {
                            try fileManager.copyItem(at: localFileURL, to: copyToURL)
                        }
                        successfuleSyncDownURLs.append(localFileURL)
                        doCopyToRemote!(Array(relativeFilePaths.suffix(from: 1)))
                    } catch {
                        log.error(error)
                        failureSyncDownURLs.append(localFileURL)
                        doCopyToRemote!(Array(relativeFilePaths.suffix(from: 1)))
                    }
                }
            }
            
            doCopyToRemote(relativeFilesToSyncUp)
        }
    }
    
    public func syncDown(completion: @escaping (SyncStatus) -> Void) {
        let fileManager = FileManager.default
        
        var successfuleSyncDownURLs: [URL] = []
        var failureSyncDownURLs: [URL] = []
        var doCopyToLocal: (([String]) -> Void)!
        
        for syncManager in availableSyncDestinations {
            
            guard let remoteRoot = syncManager.remoteRoot else { continue }
            
            let relativeFilePathsToSyncDown = self.findRelativeFilePathsToSyncDown(remoteSyncManager: syncManager, localFiles: self.loadLocalFiles())
            
            log.info("found files to download from iCloud: \(relativeFilePathsToSyncDown)")
            
            doCopyToLocal = { relativeFilePathsToSyncDown in
                
                guard let relativeFilePath = relativeFilePathsToSyncDown.first else { completion(SyncStatus(successURLs: successfuleSyncDownURLs, failureURLs: failureSyncDownURLs)); return }
                
                let remoteURL = remoteRoot.appendingPathComponent(relativeFilePath)
                let copyToURL = URL.localRootURL.appendingPathComponent(relativeFilePath)
                
                let dir = copyToURL.deletingLastPathComponent()
                dir.createDirectoryIfNeeded { error in
                    do {
                        if fileManager.fileExists(atPath: copyToURL.path, isDirectory: nil) {
                            _ = try fileManager.replaceItemAt(copyToURL, withItemAt: remoteURL)
                        } else {
                            try fileManager.copyItem(at: remoteURL, to: copyToURL)
                        }
                        successfuleSyncDownURLs.append(remoteURL)
                        doCopyToLocal!(Array(relativeFilePathsToSyncDown.suffix(from: 1)))
                    } catch {
                        log.error(error)
                        failureSyncDownURLs.append(remoteURL)
                        doCopyToLocal!(Array(relativeFilePathsToSyncDown.suffix(from: 1)))
                    }
                }
            }
            
            doCopyToLocal(relativeFilePathsToSyncDown)
        }
    }
    
    private var isSyncing = false
    public func sync(completion: ((SyncResult) -> Void)? = nil) {
        
        if isSyncing {
            isSyncing = true
            return
        }
        
        log.info("syncing start")
        DispatchQueue(label: "sync").async {
            
            self.syncDown { syncDownResult in
                self.syncUp { syncUpResult in
                    completion?(SyncResult(syncUp: syncUpResult, syncDown: syncDownResult))
                    self._eventObserver.emit(NewFilesAvailableEvent())
                    self.isSyncing = false
                    log.info("syncing complete")
                }
                
            }
        }
    }
    
    private func loadLocalFiles() -> [URL] {
        return URL.localRootURL.allPackagesInside
    }
    
    public func findRelativeFilePathsToSyncDown(remoteSyncManager: SyncManagerProtocol, localFiles: [URL]) -> [String] {
        var relativefilePathsToCopyFromRemoteToLocal: [String] = []
        var remoteRelativePaths = remoteSyncManager.remoteFileRelativePaths
        let count = remoteRelativePaths.count
        for (index, remoteFileRelativePath) in remoteSyncManager.remoteFileRelativePaths.reversed().enumerated() {

            for localFile in localFiles {
                if remoteFileRelativePath == localFile.containerRelativePath {
                    remoteRelativePaths.remove(at: count - index - 1)
                    
                    guard let remoteURL = remoteSyncManager.urlForRelativePath(remoteFileRelativePath) else { continue }
                    
                    if remoteURL.lastModifyOrCreateTimeStamp < localFile.lastModifyOrCreateTimeStamp {
                        // copy remote file to local
                        relativefilePathsToCopyFromRemoteToLocal.append(remoteFileRelativePath)
                    }
                    break
                }
            }
        }
        
        // append remaining remote file paths, those are not contained in local
        relativefilePathsToCopyFromRemoteToLocal.append(contentsOf: remoteRelativePaths)
        
        return relativefilePathsToCopyFromRemoteToLocal
    }
    
    public func findRelativeFilePathsToSyncUp(remoteSyncManager: SyncManagerProtocol, localFiles: [URL]) -> [String] {
        var relativefilePathsToCopyFromLocalToRemote: [String] = []
        
        var localRelativePaths = localFiles.map { $0.containerRelativePath.removingPercentEncoding! }
        let count = localRelativePaths.count
        
        for (index, localFile) in localFiles.reversed().enumerated() {

            let localRelativeFilePath = localFile.containerRelativePath.removingPercentEncoding!
            
            for remoteFileRelativePath in remoteSyncManager.remoteFileRelativePaths {
                
                guard let remoteFile = remoteSyncManager.urlForRelativePath(remoteFileRelativePath) else { continue }
                
                if remoteFileRelativePath == localFile.containerRelativePath {
                    
                    localRelativePaths.remove(at: count - index - 1) // remove matched local path
                    
                    if remoteFile.lastModifyOrCreateTimeStamp < localFile.lastModifyOrCreateTimeStamp {
                        // copy remote file to local
                        relativefilePathsToCopyFromLocalToRemote.append(localRelativeFilePath)
                    }
                    break
                }
            }
        }
        
        // append remaining local paths, those are not contained in remote
        relativefilePathsToCopyFromLocalToRemote.append(contentsOf: localRelativePaths)
        
        return relativefilePathsToCopyFromLocalToRemote
    }
    
    private func handleRemoveFileFromCloud(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            log.error(url)
        }
    }
    
    private func handleRemoveFileFromLocal(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            log.error(url)
        }
    }
}
