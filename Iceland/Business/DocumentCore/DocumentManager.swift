//
//  DocumentManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

public struct DocumentManagerNotification {
    public static let didChangeDocumentName = Notification.Name(rawValue: "didChangeDocumentName")
    public static let keyDidChangeDocumentNameOld = "old-url"
    public static let keyDidChangeDocumentNameNew = "new-url"
    
    public static let didChangeDocumentCover = Notification.Name(rawValue: "didChangeDocumentCover")
    public static let keyDidChangeDocumentCover = "url"
    public static let keyNewCover = "new-cover"
    
    public static let didDeleteDocument = Notification.Name(rawValue: "didDeleteDocument")
    public static let keyDidDelegateDocumentURL = "url"
}

public struct DocumentManager {
    public struct Constants {
        static let filesFolderName = "files"
        static let filesFolder = File.Folder.document(filesFolderName)
    }

    public init() {
        Constants.filesFolder.createFolderIfNeeded()
    }
    
    public var recentFiles: [RecentDocumentInfo] {
        return OutlineEditorServer.instance.recentFilesManager.recentFiles
    }
    
    public func removeRecentFile(url: URL) {
        OutlineEditorServer.instance.recentFilesManager.removeRecentFile(url: url) {}
    }
    
    public func closeFile(url: URL, last selectionLocation: Int) {
        OutlineEditorServer.instance.recentFilesManager.addRecentFile(url: url, lastLocation: selectionLocation) {}
    }
    
    /// 查找指定目录下的 iceland 文件包
    public func query(in folder: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: folder,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            .filter { $0.pathExtension == Document.fileExtension }
    }
    
    public func setCover(_ image: UIImage?, url: URL) {
        let service = OutlineEditorServer.request(url: url)
        service.open { [service] _ in
            service.cover = image
            
            NotificationCenter.default.post(name: DocumentManagerNotification.didChangeDocumentCover,
                                            object: nil,
                                            userInfo: [DocumentManagerNotification.keyDidChangeDocumentCover: url,
                                                       DocumentManagerNotification.keyNewCover: image as Any])
        }
    }
    
    public func cover(url: URL) -> UIImage? {
        return UIImage(contentsOfFile: url.coverURL.path)
    }
    
    private func createFolderIfNeeded(url: URL) -> URL {
        let folderURL = url.convertoFolderURL
        var isDIR = ObjCBool(true)
        if !Foundation.FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDIR) {
            do { try Foundation.FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil) }
            catch { print("Error when touching dir for path: \(folderURL.path): error") }
        }
        return folderURL
    }
    
    /// 如果有 below，则创建成 below 的子文件，否则在根目录创建
    public func add(title: String,
                        below: URL?,
                        completion: ((URL?) -> Void)? = nil) {
        var newURL: URL = URL.documentBaseURL.appendingPathComponent(title).appendingPathExtension(Document.fileExtension)
        if let below = below {
            let folderURL = self.createFolderIfNeeded(url: below)
            newURL = folderURL.appendingPathComponent(title).appendingPathExtension(Document.fileExtension)
        }
        
        var incrementaor: Int = 1
        let copyOfNewURL = newURL
        while FileManager.default.fileExists(atPath: newURL.path) {
            let name = copyOfNewURL.deletingPathExtension().lastPathComponent + "\(incrementaor)"
            newURL = copyOfNewURL.deletingPathExtension().deletingLastPathComponent().appendingPathComponent(name).appendingPathExtension(Document.fileExtension)
            incrementaor += 1
        }
        
        let document = Document.init(fileURL: newURL)
        document.string = "" // 新文档的内容为空字符串
        document.save(to: newURL, for: UIDocument.SaveOperation.forCreating) { [document] success in
            if success {
                completion?(newURL)
            } else {
                completion?(nil)
            }
            
            document.close(completionHandler: nil)
        }
    }
    
    public func delete(url: URL, completion: ((Error?) -> Void)? = nil) {
        let fm = FileManager.default
        let subFolder = url.convertoFolderURL
        var isDir = ObjCBool(true)
        // 如果有子文件, 先删除子文件
        if fm.fileExists(atPath: subFolder.path, isDirectory: &isDir) {
            OutlineEditorServer.closeIfOpen(dir: subFolder) {
                subFolder.delete { error in
                    if let error = error {
                        completion?(error)
                    } else {
                        OutlineEditorServer.closeIfOpen(url: url, complete: {
                            url.delete { error in
                                // 执行回调
                                completion?(error)
                                
                                // 如果没有失败，则通知外部，此文件已删除
                                if error == nil {
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: DocumentManagerNotification.didDeleteDocument, object: nil, userInfo: [DocumentManagerNotification.keyDidDelegateDocumentURL: url])
                                    }
                                }
                            }
                        })
                    }
                }
            }
        // 如果没有子文件夹，直接删除
        } else {
            OutlineEditorServer.closeIfOpen(url: url) {
                url.delete { error in
                    // 执行回调
                    completion?(error)
                    
                    // 如果没有失败，则通知外部，此文件已删除
                    if error == nil {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: DocumentManagerNotification.didDeleteDocument, object: nil, userInfo: [DocumentManagerNotification.keyDidDelegateDocumentURL: url])
                        }
                    }
                }
            }
        }
    }
    
    public func rename(url: URL,
                to: String,
                below: URL?,
                completion: @escaping (URL) -> Void,
                failure: @escaping (Error) -> Void) {
        var newURL: URL = url
        if let below = below {
            let folderURL = self.createFolderIfNeeded(url: below)
            newURL = folderURL.appendingPathComponent(to).appendingPathExtension(Document.fileExtension)
        } else {
            newURL.deleteLastPathComponent()
            newURL = newURL.appendingPathComponent(to).appendingPathExtension(Document.fileExtension)
        }
        url.rename(url: newURL) { error in
            if let error = error {
                failure(error)
            } else {
                // 修改子文件夹名字
                let subdocumentFolder = url.convertoFolderURL
                var isDir = ObjCBool(true)
                if FileManager.default.fileExists(atPath: subdocumentFolder.path, isDirectory: &isDir) {
                    subdocumentFolder.rename(url: newURL.convertoFolderURL) { error in
                        if let error = error {
                            failure(error)
                        } else {
                            // 通知文件名更改
                            NotificationCenter.default.post(name: DocumentManagerNotification.didChangeDocumentName,
                                                            object: nil,
                                                            userInfo: [DocumentManagerNotification.keyDidChangeDocumentNameNew : newURL,
                                                                       DocumentManagerNotification.keyDidChangeDocumentNameOld : url])
                            completion(newURL)
                        }
                    }
                } else {
                    // 通知文件名更改
                    NotificationCenter.default.post(name: DocumentManagerNotification.didChangeDocumentName,
                                                    object: nil,
                                                    userInfo: [DocumentManagerNotification.keyDidChangeDocumentNameNew : newURL,
                                                               DocumentManagerNotification.keyDidChangeDocumentNameOld : url])
                    completion(newURL)
                }
            }
        }
    }
    
    public func duplicate(url: URL, complete: @escaping (URL) -> Void, failure: @escaping (Error) -> Void) {
        url.duplicate { url, error in
            if error == nil {
                complete(url!)
            } else {
                failure(error!)
            }
        }
    }
}

// MARK: - URL extension
