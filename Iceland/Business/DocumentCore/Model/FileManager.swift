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

extension URL {
    public static var documentBaseURL: URL {
        return URL.directory(location: URLLocation.document, relativePath: "files")
    }
    
    public static var attachmentURL: URL {
        return URL.directory(location: URLLocation.document, relativePath: "attachment")
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
    
    @discardableResult
    public func createDirectorysIfNeeded() -> URL {
        var isDIR = ObjCBool(true)
        let path = self.path
        if !Foundation.FileManager.default.fileExists(atPath: path, isDirectory: &isDIR) {
            do { try Foundation.FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil) }
            catch { print("Error when touching dir for path: \(path): error") }
        }
        
        return self
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
        let string = string.replacingOccurrences(of: " ", with: "%20")
        return URL(string: self.deletingPathExtension().deletingLastSplashIfThereIs.appending(string))!.appendingPathExtension(ext)
    }
    
    public var deletingLastSplashIfThereIs: String {
        let absString = self.absoluteString
        if absString.hasSuffix("/") {
            return absString.substring(NSRange(location: 0, length: absString.count - 1))
        } else {
            return absString
        }
    }
}

private struct DocumentConstants {
    fileprivate static let documentDirSuffix: String = ""
}

extension URL {
    /// 一个文件，可以包含子文件，方法是，创建一个以该文件同名的文件夹(不包含 icelane 后缀)，放在同一目录
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
    
    public static var filesFolderPath: String {
        return URL.documentBaseURL.path
    }
    
    public var hasSubDocuments: Bool {
        let subDocumentFolder = self.convertoFolderURL.path
        var isDir = ObjCBool(true)
        let fm = FileManager.default
        return fm.fileExists(atPath: subDocumentFolder, isDirectory: &isDir) &&
            ((try? fm.contentsOfDirectory(atPath: subDocumentFolder)) ?? []).count > 0
    }
    
    public var fileName: String {
        return self.wrapperURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "/", with: "")
    }
    
    public var wrapperURL: URL {
        /// 如果文件是 org, cover, logs 文件，则使用所在的 .iceland 目录
        var url = self
        if url.path.hasSuffix(Document.contentFileExtension)
            || url.path.hasSuffix(Document.coverFileExtension)
            || url.path.hasSuffix(Document.logsFileExtension) {
            url = url.deletingLastPathComponent()
        }
        
        return url
    }
    
    public var documentRelativePath: String {
        let path = self.path
        let separator = URL.documentBaseURL.path + "/" // 在末尾加上斜线，在替换的时候，相对路径开始则不会有斜线
        return path.components(separatedBy: separator).last!
    }
    
    public var coverURL: URL {
        return self.appendingPathComponent(Document.coverKey)
    }
}


extension URL {
    public func duplicate(completion: @escaping (URL?, Error?) -> Void) {
        let fileCoordinator = NSFileCoordinator()
        let read = NSFileAccessIntent.readingIntent(with: self, options: NSFileCoordinator.ReadingOptions.Element())
        
        var copyURL = self.concatingToFileName(" copy")
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
        queue.qualityOfService = .background
        fileCoordinator.coordinate(with: [write, read], queue: queue) { error in
            if error != nil {
                completion(nil, error)
            } else {
                let fm = FileManager.default
                do {
                    try fm.copyItem(at: self, to: copyURL)
                    completion(copyURL, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }
    }
    
    public func delete(completion: @escaping (Error?) -> Void) {
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        let fileAccessIntent = NSFileAccessIntent.writingIntent(with: self, options: NSFileCoordinator.WritingOptions.forDeleting)
        let queue = OperationQueue()
        queue.qualityOfService = .background
        fileCoordinator.coordinate(with: [fileAccessIntent], queue: queue) { error in
            if let error = error {
                completion(error)
            } else {
                do {
                    try FileManager.default.removeItem(at: fileAccessIntent.url)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    public func rename(url: URL, completion: ((Error?) -> Void)?) {
        let oldURL = self
        let newURL = url
        
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        let moving = NSFileAccessIntent.writingIntent(with: oldURL, options: NSFileCoordinator.WritingOptions.forMoving)
        let replacing = NSFileAccessIntent.writingIntent(with: newURL, options: NSFileCoordinator.WritingOptions.forReplacing)
        
        let queue = OperationQueue()
        queue.qualityOfService = .background
        fileCoordinator.coordinate(with: [moving, replacing], queue: queue) { error in
            do {
                let fileManager = FileManager.default
                fileCoordinator.item(at: oldURL, willMoveTo: newURL)
                try fileManager.moveItem(at: oldURL, to: newURL)
                fileCoordinator.item(at: oldURL, didMoveTo: newURL)
                completion?(error)
            } catch {
                completion?(error)
            }
        }
    }
}


extension String {
    public func substring(_ range: NSRange) -> String {
        return (self as NSString).substring(with: range)
    }
    
    public func removing(_ range: NSRange) -> String {
        return self.replacingOccurrences(of: self.substring(range), with: "")
    }
}
