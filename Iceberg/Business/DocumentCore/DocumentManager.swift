//
//  DocumentManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public enum DocumentError: Error {
    case failedToCreateDocument
}

public struct DocumentManager {
    public static let contentKey: String = "content.org"
    public static let coverKey: String = "cover.jpg"
    public static let logsKey: String = "logs.log"
    
    public init(editorContext: EditorContext, eventObserver: EventObserver, syncManager: iCloudDocumentManager) {
        self._editorContext = editorContext
        self._eventObserver = eventObserver
        self._syncManager = syncManager
//        URL.documentBaseURL.createDirectoryIfNeeded(completion: nil)
    }
    
    private let _editorContext: EditorContext
    private let _eventObserver: EventObserver
    private let _syncManager: iCloudDocumentManager
    
    public var recentFiles: [RecentDocumentInfo] {
        return self._editorContext.recentFilesManager.recentFiles
    }
    
    public func getFileLocationComplete(_ completion: @escaping (URL?) -> Void) {
        if iCloudDocumentManager.status == .on {
            self._syncManager.geticloudContainerURL {
                completion($0)
            }
        } else {
            completion(URL.localRootURL)
        }
    }
    
    public func removeRecentFile(url: URL) {
        self._editorContext.recentFilesManager.removeRecentFile(url: url) {}
    }
        
    /// 查找指定目录下的 iceland 文件包
    public func query(in folder: URL, recursively: Bool = false) throws -> [URL] {
        
        if recursively {
            var urls: [URL] = []
            
            for url in try self.query(in: folder) {
                urls.append(url)
                
                var isDir = ObjCBool(true)
                let subFolder = url.convertoFolderURL
                if FileManager.default.fileExists(atPath: subFolder.path, isDirectory: &isDir) {
                    let sub = try self.query(in: subFolder, recursively: true)
                    urls.append(contentsOf: sub)
                }
            }

            return urls
        } else {
            let urls = try FileManager.default.contentsOfDirectory(at: folder,
                                                               includingPropertiesForKeys: [],
                                                               options: .skipsHiddenFiles)
                .filter { $0.pathExtension == Document.fileExtension }
            return urls
        }
    }
    
    public func setCover(_ image: UIImage?, url: URL, completion: @escaping (URL) -> Void) {
        let service = self._editorContext.request(url: url)
        service.onReadyToUse = { s in
            s.open { [weak service] _ in
                service?.cover = image?.resize(upto: CGSize(width: 1024, height: 1024))
                
                service?.save(completion: { _ in
                    completion(url)
                    self._eventObserver.emit(ChangeDocumentCoverEvent(url: url, image: image))
                })
            }
        }
    }
    
    public func cover(url: URL) -> UIImage? {
        return UIImage(contentsOfFile: url.coverURL.path)
    }
    
    private func _createFolderIfNeeded(url: URL, completion: @escaping (URL) -> Void) {
        let folderURL = url.convertoFolderURL
        var isDIR = ObjCBool(true)
        
        if Foundation.FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDIR) {
            completion(folderURL)
        } else {
            let fileCoordinator = NSFileCoordinator()
            let intent = NSFileAccessIntent.writingIntent(with: URL(fileURLWithPath: folderURL.path), options: NSFileCoordinator.WritingOptions.forMoving)
            let queue = OperationQueue()
            queue.qualityOfService = .background
            fileCoordinator.coordinate(with: [intent], queue: queue) { error in
                do {
                    try Foundation.FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
                    
                    completion(folderURL)
                }
                catch { print("Error when touching dir for path: \(folderURL.path): error") }
            }
        }

    }
    
    /// 如果有 below，则创建成 below 的子文件，否则在根目录创建
    public func add(title: String,
                        below: URL?,
                        content: String? = nil,
                        completion: ((URL?) -> Void)? = nil) {
        let newURL: URL = URL.documentBaseURL.appendingPathComponent(title).appendingPathExtension(Document.fileExtension)
        
        let addDocumentAction: (URL) -> Void = { newURL in
            let newURL = newURL.uniqueURL

            self._editorContext._editingQueue.async {
                let document = Document.init(fileURL: newURL)
                document.updateContent(content ?? "") // 新文档的内容为空字符串
                document.save(to: newURL, for: UIDocument.SaveOperation.forCreating) { [document] success in
                    DispatchQueue.runOnMainQueueSafely {
                        if success {
                            completion?(newURL)
                            self._eventObserver.emit(AddDocumentEvent(url: newURL))
                        } else {
                            completion?(nil)
                        }
                    }
                    
                    document.close(completionHandler: nil)
                }
            }
        }
        
        if let below = below {
            self._createFolderIfNeeded(url: below) { folderURL in
                let newURL = folderURL.appendingPathComponent(title).appendingPathExtension(Document.fileExtension)
                addDocumentAction(newURL)
            }
        } else {
            URL.documentBaseURL.createDirectoryIfNeeded { error in
                if let error = error {
                    log.error(error)
                    completion?(nil)
                } else {
                    addDocumentAction(newURL)
                }
            }
        }
    }
    
    /// 删除首先是修改文件名，改为 .Deleteg开头，加上原文件名。
    public func delete(url: URL, completion: ((Error?) -> Void)? = nil) {
        let fm = FileManager.default
        let subFolder = url.convertoFolderURL
        var isDir = ObjCBool(true)
        // 如果有子文件, 先删除子文件
        if fm.fileExists(atPath: subFolder.path, isDirectory: &isDir) {
            // 关闭文件夹下的文件
            self._editorContext.closeIfOpen(dir: subFolder) {
                // 先删除子文件中的文件
                subFolder.rename(queue: self._editorContext._editingQueue, url: SyncCoordinator.Prefix.deleted.createURL(for: subFolder).uniqueURL) { error in
                    if let error = error {
                        DispatchQueue.runOnMainQueueSafely {
                            completion?(error)
                        }
                    } else {
                        self._eventObserver.emit(DeleteDocumentEvent(url: subFolder))
                        
                        // 然后再删除此文件
                        self._editorContext.closeIfOpen(url: url, complete: {
                            url.rename(queue: self._editorContext._editingQueue, url: SyncCoordinator.Prefix.deleted.createURL(for: url).uniqueURL) { error in
                                DispatchQueue.runOnMainQueueSafely {
                                    // 执行回调
                                    completion?(error)
                                    // 如果没有失败，则通知外部，此文件已删除
                                    if error == nil {
                                        self._eventObserver.emit(DeleteDocumentEvent(url: url))
                                    }
                                }
                            }
                        })
                    }
                }
            }
        // 如果没有子文件夹，直接删除
        } else {
            self._editorContext.closeIfOpen(url: url) {
                url.rename(queue: self._editorContext._editingQueue, url: SyncCoordinator.Prefix.deleted.createURL(for: url).uniqueURL) { error in
                    DispatchQueue.runOnMainQueueSafely {
                        // 执行回调
                        completion?(error)
                        if error == nil {
                            // 如果没有失败，则通知外部，此文件已删除
                            self._eventObserver.emit(DeleteDocumentEvent(url: url))
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
        let newURL: URL = url
        
        let renameAction: (URL) -> Void = { newURL in
            
            url.rename(queue: self._editorContext._editingQueue, url: newURL) { error in
                if let error = error {
                    DispatchQueue.runOnMainQueueSafely {
                        failure(error)
                    }
                } else {
                    // 修改子文件夹名字
                    let subdocumentFolder = url.convertoFolderURL
                    var isDir = ObjCBool(true)
                    if FileManager.default.fileExists(atPath: subdocumentFolder.path, isDirectory: &isDir) {
                        subdocumentFolder.rename(queue: self._editorContext._editingQueue, url: newURL.convertoFolderURL) { error in
                            if let error = error {
                                DispatchQueue.runOnMainQueueSafely {
                                    failure(error)
                                }
                            } else {
                                // 通知文件名更改
                                DispatchQueue.runOnMainQueueSafely {
                                    completion(newURL)
                                    self._eventObserver.emit(RenameDocumentEvent(oldUrl: url, newUrl: newURL))
                                }
                            }
                        }
                    } else {
                        // 通知文件名更改
                        DispatchQueue.runOnMainQueueSafely {
                            completion(newURL)
                            self._eventObserver.emit(RenameDocumentEvent(oldUrl: url, newUrl: newURL))
                        }
                    }
                }
            }
        }
        
        if let below = below {
            self._createFolderIfNeeded(url: below) { folderURL in
                var newURL = folderURL.appendingPathComponent(to).appendingPathExtension(Document.fileExtension)
                newURL = newURL.uniqueURL
                renameAction(newURL)
            }
        } else {
            var newURL = newURL.deletingLastPathComponent()
            newURL = newURL.appendingPathComponent(to).appendingPathExtension(Document.fileExtension)
            
            newURL = newURL.uniqueURL
            renameAction(newURL)
        }
    }
    
    public func duplicate(url: URL, copyExt: String, complete: @escaping (URL) -> Void, failure: @escaping (Error) -> Void) {
        url.duplicate(queue: self._editorContext._editingQueue, copyExt: copyExt) { url, error in
            DispatchQueue.runOnMainQueueSafely {
                if error == nil {
                    complete(url!)
                    self._eventObserver.emit(AddDocumentEvent(url: url!))
                } else {
                    failure(error!)
                }
            }
        }
    }
}
