//
//  DocumentManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public struct DocumentManager {
    public static let contentKey: String = "content.org"
    public static let coverKey: String = "cover.jpg"
    public static let logsKey: String = "logs.log"
    
    public init(editorContext: EditorContext, eventObserver: EventObserver, syncManager: SyncManager) {
        self._editorContext = editorContext
        self._eventObserver = eventObserver
        self._syncManager = syncManager
        URL.documentBaseURL.createDirectoryIfNeeded(completion: nil)
    }
    
    private let _editorContext: EditorContext
    private let _eventObserver: EventObserver
    private let _syncManager: SyncManager
    
    public var recentFiles: [RecentDocumentInfo] {
        return self._editorContext.recentFilesManager.recentFiles
    }
    
    public func getFileLocationComplete(_ completion: @escaping (URL?) -> Void) {
        if SyncManager.status == .on {
            self._syncManager.geticloudContainerURL {
                completion($0)
            }
        } else {
            completion(URL.localDocumentBaseURL)
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
            return try FileManager.default.contentsOfDirectory(at: folder,
                                                               includingPropertiesForKeys: nil,
                                                               options: .skipsHiddenFiles)
                .filter { $0.pathExtension == Document.fileExtension }
        }
    }
    
    public func setCover(_ image: UIImage?, url: URL) {
        let service = self._editorContext.request(url: url)
        service.open { [service] _ in
            service.cover = image
            
            service.save(completion: { _ in
                self._eventObserver.emit(ChangeDocumentCoverEvent(url: url, image: image))
            })
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
            var newURL = newURL
            var incrementaor: Int = 1
            let copyOfNewURL = newURL
            // 如果对应的文件名已经存在，则在文件名后添加数字，并以此增大
            while FileManager.default.fileExists(atPath: newURL.path) {
                let name = copyOfNewURL.deletingPathExtension().lastPathComponent + "\(incrementaor)"
                newURL = copyOfNewURL.deletingPathExtension().deletingLastPathComponent().appendingPathComponent(name).appendingPathExtension(Document.fileExtension)
                incrementaor += 1
            }
            
            self._editorContext._editingQueue.async {
                let document = Document.init(fileURL: newURL)
                document.updateContent(content ?? "") // 新文档的内容为空字符串
                document.save(to: newURL, for: UIDocument.SaveOperation.forCreating) { [document] success in
                    DispatchQueue.main.async {
                        if success {
                            self._eventObserver.emit(AddDocumentEvent(url: newURL))
                            completion?(newURL)
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
    
    public func delete(url: URL, completion: ((Error?) -> Void)? = nil) {
        let fm = FileManager.default
        let subFolder = url.convertoFolderURL
        var isDir = ObjCBool(true)
        // 如果有子文件, 先删除子文件
        if fm.fileExists(atPath: subFolder.path, isDirectory: &isDir) {
            // 关闭文件夹下的文件
            self._editorContext.closeIfOpen(dir: subFolder) {
                // 先删除子文件中的文件
                subFolder.delete(queue: self._editorContext._editingQueue) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            completion?(error)
                        }
                    } else {
                        self._eventObserver.emit(DeleteDocumentEvent(url: subFolder))
                        
                        // 然后在删除此文件
                        self._editorContext.closeIfOpen(url: url, complete: {
                            url.delete(queue: self._editorContext._editingQueue) { error in
                                DispatchQueue.main.async {
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
                url.delete(queue: self._editorContext._editingQueue) { error in
                    DispatchQueue.main.async {
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
                    DispatchQueue.main.async {
                        failure(error)
                    }
                } else {
                    // 修改子文件夹名字
                    let subdocumentFolder = url.convertoFolderURL
                    var isDir = ObjCBool(true)
                    if FileManager.default.fileExists(atPath: subdocumentFolder.path, isDirectory: &isDir) {
                        subdocumentFolder.rename(queue: self._editorContext._editingQueue, url: newURL.convertoFolderURL) { error in
                            if let error = error {
                                DispatchQueue.main.async {
                                    failure(error)
                                }
                            } else {
                                // 通知文件名更改
                                DispatchQueue.main.async {
                                    completion(newURL)
                                    self._eventObserver.emit(RenameDocumentEvent(oldUrl: url, newUrl: newURL))
                                }
                            }
                        }
                    } else {
                        // 通知文件名更改
                        DispatchQueue.main.async {
                            completion(newURL)
                            self._eventObserver.emit(RenameDocumentEvent(oldUrl: url, newUrl: newURL))
                        }
                    }
                }
            }
        }
        
        if let below = below {
            self._createFolderIfNeeded(url: below) { folderURL in
                let newURL = folderURL.appendingPathComponent(to).appendingPathExtension(Document.fileExtension)
                
                renameAction(newURL)
            }
        } else {
            var newURL = newURL.deletingLastPathComponent()
            newURL = newURL.appendingPathComponent(to).appendingPathExtension(Document.fileExtension)
            
            renameAction(newURL)
        }
    }
    
    public func duplicate(url: URL, copyExt: String, complete: @escaping (URL) -> Void, failure: @escaping (Error) -> Void) {
        url.duplicate(queue: self._editorContext._editingQueue, copyExt: copyExt) { url, error in
            DispatchQueue.main.async {
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
