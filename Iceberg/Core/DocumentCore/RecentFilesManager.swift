//
//  RecentFiles.swift
//  Business
//
//  Created by ian luo on 2019/1/26.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class RecentDocumentInfo: DocumentInfo, Codable {
    public let lastRequestTime: Date
    public let location: Int
    
    public init(lastRequestTime: Date, location: Int, wrapperURL: URL) {
        self.lastRequestTime = lastRequestTime
        self.location = location
        super.init(wrapperURL: wrapperURL)
    }
    
    private enum _CodingKeys: CodingKey {
        case lastRequestTime
        case path
        case location
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _CodingKeys.self)
        
        self.lastRequestTime = try container.decode(Date.self, forKey: _CodingKeys.lastRequestTime)
        self.location = try container.decode(Int.self, forKey: _CodingKeys.location)
        let relatedPath = try container.decode(String.self, forKey: _CodingKeys.path)

        super.init(wrapperURL: URL.documentBaseURL.appendingPathComponent(relatedPath))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: _CodingKeys.self)
        try container.encode(self.lastRequestTime, forKey: _CodingKeys.lastRequestTime)
        try container.encode(self.location, forKey: _CodingKeys.location)
        try container.encode(url.documentRelativePath, forKey: _CodingKeys.path)
    }
}

public class RecentFilesManager {
    public static let recentFilesPlistFileName: String = "recent_files"
    
    private let eventObserver: EventObserver
    public init(eventObserver: EventObserver) {
        self.eventObserver = eventObserver
        
        self.eventObserver.registerForEvent(on: self,
                                            eventType: DeleteDocumentEvent.self,
                                            queue: .main) { [weak self] (deleteDocumentEvent: DeleteDocumentEvent) -> Void in
                                                self?.onDocumentDelete(event: deleteDocumentEvent)
        }
        
        self.eventObserver.registerForEvent(on: self,
                                            eventType: RenameDocumentEvent.self,
                                            queue: .main) { [weak self] (event: RenameDocumentEvent) -> Void in
            self?.onDocumentNameChange(event: event)
        }
    }
    
    deinit {
        self.eventObserver.unregister(for: self, eventType: nil)
    }
    
    /// 当文件名修改了之后，更改保存的最近文件的文件名
    @objc internal func onDocumentNameChange(event: RenameDocumentEvent) {
        let oldPath = event.oldUrl.documentRelativePath
        let plist = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom(RecentFilesManager.recentFilesPlistFileName)))
        
        self.recentFiles.forEach { documentInfo in
            if documentInfo.url.documentRelativePath == oldPath {
                let openDate = self.recentFile(url: event.oldUrl.documentRelativePath, plist: plist)?.lastRequestTime ?? Date()
                self.removeRecentFile(url: event.oldUrl) {
                    self.addRecentFile(url: event.newUrl, lastLocation: 0, date: openDate) { [weak self] in
                        self?.clearFilesDoesNotExists({})
                        self?.eventObserver.emit(RecentDocumentRenamedEvent(renameDocumentEvent: event))
                    }
                }
            }
        }
        
        self.clearFilesDoesNotExists({})
    }
    
    @objc private func onDocumentDelete(event: DeleteDocumentEvent) {
        self.recentFiles.forEach { savedDocument in
            if savedDocument.url.documentRelativePath.contains(event.url.documentRelativePath) {
                self.removeRecentFile(url: savedDocument.url) {}
            }
        }
    }
    
    /// 删除最近文件
    public func removeRecentFile(url: URL, completion: @escaping () -> Void) {
        let plist = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom(RecentFilesManager.recentFilesPlistFileName)))
        
        plist.remove(key: url.lastPathComponent) {
            DispatchQueue.runOnMainQueueSafely {
                completion()
            }
        }
    }
    
    public func recentFile(url: String, plist: KeyValueStore) -> RecentDocumentInfo? {
        if let json = plist.get(key: url) as? String {
            if let data = json.data(using: .utf8) {
                let jsonDecoder = JSONDecoder()
                do {
                    return try jsonDecoder.decode(RecentDocumentInfo.self, from: data)
                } catch {
                    log.error(error)
                }
            }
        }
        
        return nil
    }
    
    /// 最近使用文件
    public func addRecentFile(url: URL, lastLocation: Int, date: Date = Date(), completion: @escaping () -> Void) {
        
        // ignore files from trash
        guard !url.packageName.hasPrefix(SyncCoordinator.Prefix.deleted.rawValue) else { return }
        
        let recentDocumentInfo = RecentDocumentInfo(lastRequestTime: date, location: lastLocation, wrapperURL: url)
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(recentDocumentInfo)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            let plist = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom(RecentFilesManager.recentFilesPlistFileName)))
            
            plist.set(value: jsonString, key: url.lastPathComponent) {
                completion()
            }
        } catch {
            log.error(error)
        }
    }
    
    public func clearFilesDoesNotExists(_ completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        DispatchQueue.global().async {
            let plist = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom(RecentFilesManager.recentFilesPlistFileName)))
            plist.allKeys().forEach { key in
                if let recentDocumentInfo = self.recentFile(url: key, plist: plist) {
                    
                    // 清除不存在的文件
                    var isDir = ObjCBool(true)
                    if !FileManager.default.fileExists(atPath: recentDocumentInfo.url.path, isDirectory: &isDir) {
                        group.enter()
                        plist.remove(key: key, completion: {
                            group.leave()
                        })
                    }
                }
            }
            
            group.notify(queue: DispatchQueue.main) {
                completion()
            }
        }
    }
    
    /// 返回保存文件的相对路径列表
    public var recentFiles: [RecentDocumentInfo] {
        var documentInfos: [RecentDocumentInfo] = []
        let plist = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom(RecentFilesManager.recentFilesPlistFileName)))
        
        plist.allKeys().forEach { key in
            if let recentDocumentInfo = self.recentFile(url: key, plist: plist) {
                documentInfos.append(recentDocumentInfo)
            }
        }

        documentInfos.sort { documentInfo1, documentInfo2 -> Bool in
            documentInfo1.lastRequestTime.timeIntervalSince1970 >= documentInfo2.lastRequestTime.timeIntervalSince1970
        }
        
        return documentInfos
    }
}
