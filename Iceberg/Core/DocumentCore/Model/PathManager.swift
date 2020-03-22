//
//  FileManager.swift
//  Business
//
//  Created by ian luo on 2019/1/28.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public enum URLLocation {
    case document
    case library
    case temporary
    case cache
    
    fileprivate var url: URL {
        switch self {
        case .document:
            return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        case .library:
            return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
        case .cache:
            return URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])
        case .temporary:
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }
}

private var fileCoordinatorCache: [URL: NSFileCoordinator] = [:]
private let _fileCoordinatorLock: NSRecursiveLock = NSRecursiveLock()
private let fetchFileCoordinator: (URL) -> NSFileCoordinator = { url in
    if let existingFileCoordinator = fileCoordinatorCache[url] {
        return existingFileCoordinator
    } else {
        let fileCoordinator = NSFileCoordinator()
        _fileCoordinatorLock.lock()
        fileCoordinatorCache[url] = fileCoordinator
        _fileCoordinatorLock.unlock()
        return fileCoordinator
    }
}

private let removeFileCoordinatorFromCache: (URL) -> Void = { url in
    _fileCoordinatorLock.lock()
    fileCoordinatorCache[url] = nil
    _fileCoordinatorLock.unlock()
}

extension URL {
    public static var localDocumentBaseURL: URL {
        return URL.directory(location: URLLocation.document, relativePath: "files")
    }
    
    public static var localAttachmentURL: URL {
        return URL.directory(location: URLLocation.document, relativePath: "attachments")
    }
    
    public static var localKeyValueStoreURL: URL {
        return URL.directory(location: URLLocation.document, relativePath: "keyValueStore")
    }
    
    public static var localRootURL: URL {
        return URLLocation.document.url
    }
    
    public static var documentBaseURL: URL {
        if iCloudDocumentManager.status == .on {
            return iCloudDocumentManager.iCloudDocumentRoot!
        } else {
            return URL.localDocumentBaseURL
        }
    }
    
    public static var attachmentURL: URL {
        if iCloudDocumentManager.status == .on {
            return iCloudDocumentManager.iCloudAttachmentRoot!
        } else {
            return URL.localAttachmentURL
        }
    }
    
    public static var keyValueStoreURL: URL {
        if iCloudDocumentManager.status == .on {
            return iCloudDocumentManager.iCloudKeyValueStoreRoot!
        } else {
            return URL.localKeyValueStoreURL
        }
    }
    
    public static var imageCacheURL: URL {
        return URL.directory(location: URLLocation.cache, relativePath: "image")
    }
    
    public static var sketchCacheURL: URL {
        return URL.directory(location: URLLocation.cache, relativePath: "sketch")
    }
    
    public static var audioCacheURL: URL {
        return URL.directory(location: URLLocation.cache, relativePath: "audio")
    }
    
    public func writeBlock(queue q: DispatchQueue, accessor: @escaping (Error?) -> Void) {
        let directory = self.deletingLastPathComponent()
        
        directory.createDirectoryIfNeeded { error in
            if let error = error {
                accessor(error)
            } else {
                let fileCoordinator = fetchFileCoordinator(self)
                let intent = NSFileAccessIntent.writingIntent(with: self, options: [])
                let queue = OperationQueue()
                queue.underlyingQueue = q
                fileCoordinator.coordinate(with: [intent], queue: queue) { error in
                    accessor(error)
                    removeFileCoordinatorFromCache(self)
                }
            }
        }
    }
    
    public func write(queue q: DispatchQueue, data: Data, completion: @escaping (Error?) -> Void) {
        self.writeBlock(queue: q) { error  in
            if let error = error {
                completion(error)
            } else {
                do {
                    try data.write(to: self)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    public func read(completion: @escaping (Data) -> Void,
                     failure: ((Error) -> Void)? = nil) {
        let fileCoordinator = fetchFileCoordinator(self)
        var error: NSError?
        
        fileCoordinator.coordinate(readingItemAt: self,
                                   options: [.withoutChanges],
                                   error: &error) { (url) in
                                    do {
                                        completion(try Data(contentsOf: url))
                                        removeFileCoordinatorFromCache(self)
                                    } catch {
                                        failure?(error)
                                        removeFileCoordinatorFromCache(self)
                                    }
        }
        
        if let error = error {
            failure?(error)
            removeFileCoordinatorFromCache(self)
        }
    }
    
    public static func read(urls: [URL], each: (URL, String) -> Void) {
        let fileCoordinator = NSFileCoordinator()
        
        var error: NSError?
        
        fileCoordinator.prepare(forReadingItemsAt: urls, options: [], writingItemsAt: [], options: [], error: &error) { accessor in
            for url in urls {
                do {
                    try each(url, String(contentsOf: url))
                } catch {
                    log.error(error)
                }
            }
        }
    }
        
    public func deleteIfExists(queue q: DispatchQueue,
                               isDirectory: Bool,
                               completion: @escaping (Error?) -> Void) {
        var isDirectory = ObjCBool(isDirectory)
        
        if FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory) {
            self.delete(queue: q, completion: completion)
        } else {
            completion(nil)
        }
    }
}

extension URL {
    public var allPackagesInside: [URL] {
        let fileManager = FileManager.default
        
        var isDir = ObjCBool(true)
        guard fileManager.fileExists(atPath: self.path, isDirectory: &isDir) else { return [] }
        
        var urls: [URL] = []
        let properties: Set<URLResourceKey> = [.contentModificationDateKey, .isHiddenKey, .isPackageKey, .creationDateKey, .isDirectoryKey]
        let enumerator = fileManager.enumerator(at: self, includingPropertiesForKeys: Array(properties),
                               options: [], errorHandler: nil)
        
        while let url = enumerator?.nextObject() as? URL {
            do {
                let resources = try url.resourceValues(forKeys: properties)
                
                if resources.isDirectory == true || resources.isPackage == true {
                    if url.pathExtension == Document.fileExtension || url.pathExtension == AttachmentDocument.fileExtension {
                        urls.append(url)
                        enumerator?.skipDescendants()
                    }
                } else if resources.isHidden == false {
                    urls.append(url)
                }
            } catch {
                log.error(error)
            }
        }
        
        return urls
    }
}

extension URL {
    public static func directory(location: URLLocation) -> URL {
        return location.url
    }
    
    public static func directory(location: URLLocation, relativePath: String) -> URL {
        return location.url.appendingPathComponent(relativePath)
    }
    
    public static func directory(relativeDirectory: URL, relativePath: String) -> URL {
        return relativeDirectory.appendingPathComponent(relativePath)
    }
    
    public static func file(directory: URL, name: String, extension ext: String) -> URL {
        return directory.appendingPathComponent(name).appendingPathExtension(ext)
    }
    
    public func concatingToFileName(_ string: String) -> URL {
        let ext = self.pathExtension
        let string = string.escaped
        return URL(string: self.deletingPathExtension().deletingLastSplashIfThereIs.appending(string))!.appendingPathExtension(ext)
    }
    
    public var deletingLastSplashIfThereIs: String {
        let absString = self.absoluteString
        if absString.hasSuffix("/") {
            return absString.nsstring.substring(with: NSRange(location: 0, length: absString.nsstring.length - 1))
        } else {
            return absString
        }
    }
    
    public var pathDeletingFirstSplashIfThereIs: String {
        let path = self.path
        if path.hasPrefix("/") {
            return path.nsstring.substring(with: NSRange(location: 1, length: path.nsstring.length - 1))
        } else {
            return path
        }
    }
}

private struct DocumentConstants {
    fileprivate static let documentDirSuffix: String = ""
}

extension String {
    public var escaped: String {
        return self.replacingOccurrences(of: " ", with: "%20")
    }
    
    public var unescaped: String {
        return self.replacingOccurrences(of: "%20", with: " ")
    }
}

extension URL {
    /// 一个文件，可以包含子文件，方法是，创建一个以该文件同名的文件夹(不包含 ice 后缀)，放在同一目录
    /// 将当前文件的 URL 转为当前文件子文件夹的 URL
    public var convertoFolderURL: URL {
        return URL(string: self.deletingPathExtension().deletingLastSplashIfThereIs + DocumentConstants.documentDirSuffix + "/")!
    }
        
    public var parentDocumentURL: URL? {
        var url = self.deletingPathExtension().deletingLastPathComponent()
        let fileName = url.lastPathComponent.replacingOccurrences(of: DocumentConstants.documentDirSuffix, with: "")
        url = url.deletingLastPathComponent()
        let parentURL = url.appendingPathComponent(fileName).appendingPathExtension(Document.fileExtension)
        
        if FileManager.default.fileExists(atPath: parentURL.path) {
            return parentURL
        }
        
        return nil
    }
        
    public var hasSubDocuments: Bool {
        let subDocumentFolderURL = self.convertoFolderURL
        let subDocumentFolder = subDocumentFolderURL.path
        var isDir = ObjCBool(true)
        let fm = FileManager.default
        return fm.fileExists(atPath: subDocumentFolder, isDirectory: &isDir) &&
            ((try? fm.contentsOfDirectory(at: subDocumentFolderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []).count > 0
    }
    
    public var hasSubDocumentFolder: Bool {
        let subDocumentFolderURL = self.convertoFolderURL
        let subDocumentFolder = subDocumentFolderURL.path
        var isDir = ObjCBool(true)
        let fm = FileManager.default
        return fm.fileExists(atPath: subDocumentFolder, isDirectory: &isDir)
    }
    
    public var isEmptyFolder: Bool {
        return ((try? FileManager.default.contentsOfDirectory(at: self,
                                                              includingPropertiesForKeys: nil,
                                                              options: [.skipsHiddenFiles])) ?? []).count == 0
    }
        
    public var packageName: String {
        return self.wrapperURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "/", with: "").unescaped
    }
    
    public var wrapperURL: URL {
        /// 如果文件是 org, cover, logs 文件，则使用所在的 .ice 目录
        var url = self
        if url.path.hasSuffix(Document.contentFileExtension)
            || url.path.hasSuffix(Document.coverFileExtension)
            || url.path.hasSuffix(Document.logsFileExtension) {
            url = url.deletingLastPathComponent()
        }
        
        return url
    }
    
    public var containerRelativePath: String {
        let path = self.path.removingPrefixIfNeeded()
        let rootPath = URL.localRootURL.path.removingPrefixIfNeeded()
        if path == rootPath {
            return ""
        } else {
            return path.replacingOccurrences(of: rootPath, with: "", options: [], range: nil).removingPercentEncoding!
        }
    }
    
    public var documentRelativePath: String {
        let path = self.path.removingPrefixIfNeeded()
        let rootPath = URL.documentBaseURL.path.removingPrefixIfNeeded()
        if path == rootPath {
            return ""
        } else {
            let separator = rootPath + "/" // 在末尾加上斜线，在替换的时候，相对路径开始则不会有斜线
            return path.replacingOccurrences(of: separator, with: "", options: [], range: nil)
        }
    }
        
    public var levelsToRoot: Int {
        return self.documentRelativePath.components(separatedBy: "/").filter { $0.count > 0 }.count
    }
    
    public var coverURL: URL {
        return self.appendingPathComponent(Document.coverKey)
    }
}

extension String {
    func removingPrefixIfNeeded() -> String {
        if self.hasPrefix("/private") {
            return String(self[index(self.startIndex, offsetBy: 8)...])
        } else {
            return self
        }
    }

}

extension URL {
    public func duplicate(queue q: DispatchQueue, copyExt: String, completion: @escaping (URL?, Error?) -> Void) {
        let fileCoordinator = fetchFileCoordinator(self)
        let read = NSFileAccessIntent.readingIntent(with: self, options: NSFileCoordinator.ReadingOptions.Element())
        
        var copyURL = self.concatingToFileName(" \(copyExt)")
        // 如果对应的文件名已经存在，则在文件名后添加数字，并以此增大
        var incrementaor: Int = 1
        let copyOfNewURL = copyURL
        while FileManager.default.fileExists(atPath: copyURL.path) {
            let name = copyOfNewURL.deletingPathExtension().lastPathComponent + "\(incrementaor)"
            copyURL = copyOfNewURL.deletingPathExtension().deletingLastPathComponent().appendingPathComponent(name).appendingPathExtension(Document.fileExtension)
            incrementaor += 1
        }
        
        let write = NSFileAccessIntent.writingIntent(with: copyURL,
                                                     options: NSFileCoordinator.WritingOptions.forReplacing)
        
        let queue = OperationQueue()
        queue.underlyingQueue = q
        fileCoordinator.coordinate(with: [write, read], queue: queue) { error in
            if error != nil {
                completion(nil, error)
                removeFileCoordinatorFromCache(self)
            } else {
                let fm = FileManager.default
                do {
                    try fm.copyItem(at: read.url, to: write.url)
                    completion(copyURL, nil)
                    removeFileCoordinatorFromCache(self)
                } catch {
                    completion(nil, error)
                    removeFileCoordinatorFromCache(self)
                }
            }
        }
    }
    
    public func delete(queue q: DispatchQueue, completion: @escaping (Error?) -> Void) {
        let fileCoordinator = fetchFileCoordinator(self)
        let fileAccessIntent = NSFileAccessIntent.writingIntent(with: self, options: NSFileCoordinator.WritingOptions.forDeleting)
        let queue = OperationQueue()
        queue.underlyingQueue = q
        fileCoordinator.coordinate(with: [fileAccessIntent], queue: queue) { error in
            if let error = error {
                completion(error)
            } else {
                do {
                    try FileManager.default.removeItem(at: fileAccessIntent.url)
                    completion(nil)
                    removeFileCoordinatorFromCache(self)
                } catch {
                    completion(error)
                    removeFileCoordinatorFromCache(self)
                }
            }
        }
    }
    
    public func rename(queue q: DispatchQueue, url: URL, completion: ((Error?) -> Void)?) {
        let oldURL = self
        let newURL = url
        
        let fileCoordinator = fetchFileCoordinator(self)
        let moving = NSFileAccessIntent.writingIntent(with: oldURL, options: NSFileCoordinator.WritingOptions.forMoving)
        let replacing = NSFileAccessIntent.writingIntent(with: newURL, options: NSFileCoordinator.WritingOptions.forReplacing)
        
        let queue = OperationQueue()
        queue.underlyingQueue = q
        fileCoordinator.coordinate(with: [moving, replacing], queue: queue) { [unowned fileCoordinator] error in
            do {
                let fileManager = FileManager.default
                fileCoordinator.item(at: moving.url, willMoveTo: replacing.url)
                try fileManager.moveItem(at: moving.url, to: replacing.url)
                fileCoordinator.item(at: moving.url, didMoveTo: replacing.url)
                completion?(error)
                removeFileCoordinatorFromCache(self)
            } catch {
                completion?(error)
                removeFileCoordinatorFromCache(self)
            }
        }
    }
    
    public func createDirectoryIfNeeded() -> Error? {
        var isDir = ObjCBool(true)
        guard !FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) else {
            return nil
        }
        
        do {
            try Foundation.FileManager.default.createDirectory(atPath: self.path, withIntermediateDirectories: true, attributes: nil)
            return nil
        } catch {
            return error
        }
    }
    
    public func createDirectoryIfNeeded(completion: ((Error?) -> Void)?) {
        var isDir = ObjCBool(true)
        guard !FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) else {
            completion?(nil)
            return
        }
        
        log.info("no directory exists at: \(self.path), creating one...")
        let fileCoordinator = fetchFileCoordinator(self)
        let intent = NSFileAccessIntent.writingIntent(with: URL(fileURLWithPath: path), options: NSFileCoordinator.WritingOptions.forReplacing)
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        fileCoordinator.coordinate(with: [intent], queue: queue) { error in
            do {
                try Foundation.FileManager.default.createDirectory(atPath: intent.url.path, withIntermediateDirectories: true, attributes: nil)
                completion?(nil)
                removeFileCoordinatorFromCache(self)
            } catch {
                completion?(error)
                removeFileCoordinatorFromCache(self)
            }
        }
    }
}

extension URL {
    /// if the url existed, add number to the end
    public var uniqueURL: URL {
        var newURL = self
        var incrementaor: Int = 1
        let copyOfNewURL = newURL
        // 如果对应的文件名已经存在，则在文件名后添加数字，并以此增大
        while FileManager.default.fileExists(atPath: newURL.path) {
            let name = copyOfNewURL.deletingPathExtension().lastPathComponent + "\(incrementaor)"
            newURL = copyOfNewURL.deletingPathExtension().deletingLastPathComponent().appendingPathComponent(name).appendingPathExtension(Document.fileExtension)
            incrementaor += 1
        }
        
        return newURL
    }
}


extension String {
//    public func substring(_ range: NSRange) -> String {
//        return self.nsstring.substring(with: range)
//    }
//
    public var nsstring: NSString {
        return self as NSString
    }
    
    public func removing(_ range: NSRange) -> String {
        return self.replacingOccurrences(of: self.nsstring.substring(with: range), with: "")
    }
}
