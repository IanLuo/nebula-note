//
//  RecentFiles.swift
//  Business
//
//  Created by ian luo on 2019/1/26.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Storage

public struct RecentFileChangedNotification {
    public static let openFile = NSNotification.Name(rawValue: "openFile")
    public static let fileInfoChanged = NSNotification.Name(rawValue: "fileInfoChanged")
}

public class RecentDocumentInfo: DocumentInfo, Codable {
    public let lastRequestTime: Date
    public let location: Int
    
    public init(lastRequestTime: Date, location: Int, wrapperURL: URL) {
        self.lastRequestTime = lastRequestTime
        self.location = location
        super.init(wrapperURL: wrapperURL)
    }
    
    private enum CodingKeys: CodingKey {
        case lastRequestTime
        case path
        case location
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.lastRequestTime = try container.decode(Date.self, forKey: CodingKeys.lastRequestTime)
        self.location = try container.decode(Int.self, forKey: CodingKeys.location)
        let relatedPath = try container.decode(String.self, forKey: CodingKeys.path)

        super.init(wrapperURL: URL.documentBaseURL.appendingPathComponent(relatedPath))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.lastRequestTime, forKey: CodingKeys.lastRequestTime)
        try container.encode(self.location, forKey: CodingKeys.location)
        try container.encode(url.documentRelativePath, forKey: CodingKeys.path)
    }
}

public class RecentFilesManager {
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDocumentNameChange(notification:)), name: DocumentManagerNotification.didChangeDocumentName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDocumentDelete(notification:)), name: DocumentManagerNotification.didDeleteDocument, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private let plist = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom("recent_files")))
    
    /// 当文件名修改了之后，更改保存的最近文件的文件名
    @objc internal func handleDocumentNameChange(notification: Notification) {
        if let oldURL = notification.userInfo?[DocumentManagerNotification.keyDidChangeDocumentNameOld] as? URL,
            let newURL = notification.userInfo?[DocumentManagerNotification.keyDidChangeDocumentNameNew] as? URL {
            
            let oldPath = oldURL.path
            let oldSubfolderPath = oldURL.convertoFolderURL.documentRelativePath
            let plist = KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom("recent_files")))
            
            self.recentFiles.forEach { documentInfo in
                let documentCurrentPath = documentInfo.url.path
                if documentCurrentPath == oldPath {
                    let openDate = self.recentFile(url: oldURL.documentRelativePath, plist: plist)?.lastRequestTime ?? Date()
                    self.removeRecentFile(url: oldURL) {
                        self.addRecentFile(url: newURL, lastLocation: 0, date: openDate) {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: RecentFileChangedNotification.fileInfoChanged,
                                                                object: nil,
                                                                userInfo: ["oldURL" : oldURL, "newURL" : newURL])
                            }
                        }
                    }
                } else if documentCurrentPath.contains(oldSubfolderPath) { // 子文件
                    let openDate = self.recentFile(url: documentInfo.url.documentRelativePath, plist: plist)?.lastRequestTime ?? Date()
                    self.removeRecentFile(url: documentInfo.url) {
                        // 替换已修改的父文件目录
                        let newPath = documentCurrentPath.replacingOccurrences(of: oldSubfolderPath,
                                                                               with: newURL.convertoFolderURL.documentRelativePath)
                        
                        let newSubURL = URL(fileURLWithPath: newPath)
                        self.addRecentFile(url: newSubURL, lastLocation: 0, date: openDate) {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: RecentFileChangedNotification.fileInfoChanged,
                                                                object: nil,
                                                                userInfo: ["renamed": ["oldURL" : documentInfo.url,
                                                                                       "newURL" : newSubURL]])
                            }
                        }
                    }                    
                }
            }
        }
    }
    
    @objc private func handleDocumentDelete(notification: Notification) {
        if let url = notification.userInfo?[DocumentManagerNotification.keyDidDelegateDocumentURL] as? URL {
            self.recentFiles.forEach { savedDocument in
                if savedDocument.url.documentRelativePath.contains(url.documentRelativePath) {
                    log.info(">>> removing \(savedDocument.url.documentRelativePath)")
                    self.removeRecentFile(url: savedDocument.url) {
                        log.info("<<< removed \(savedDocument.url.documentRelativePath)")
                        NotificationCenter.default.post(name: RecentFileChangedNotification.fileInfoChanged,
                                                        object: nil,
                                                        userInfo: ["deleted" : url])
                    }
                }
            }
        }
    }
    
    /// 删除最近文件
    public func removeRecentFile(url: URL, completion: @escaping () -> Void) {
        self.plist.remove(key: url.documentRelativePath) {
            DispatchQueue.main.async {
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
        let recentDocumentInfo = RecentDocumentInfo(lastRequestTime: date, location: lastLocation, wrapperURL: url)
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(recentDocumentInfo)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            self.plist.set(value: jsonString, key: url.documentRelativePath) {
                completion()
            }
        } catch {
            log.error(error)
        }
    }
    
    /// 返回保存文件的相对路径列表
    public var recentFiles: [RecentDocumentInfo] {
        var documentInfos: [RecentDocumentInfo] = []
        
        self.plist.allKeys().forEach {
            if let recentDocumentInfo = self.recentFile(url: $0, plist: plist) {
                documentInfos.append(recentDocumentInfo)
            }
        }

        documentInfos.sort { documentInfo1, documentInfo2 -> Bool in
            documentInfo1.lastRequestTime.timeIntervalSince1970 >= documentInfo2.lastRequestTime.timeIntervalSince1970
        }
        
        return documentInfos
    }
}
