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
}

extension URL {
    public static func directory(location: URLLocation) -> URL {
        return location.url
    }
    
    public static func directory(location: URLLocation, relativePath: String) -> URL {
        return location.url.appendingPathComponent(relativePath)
    }
    
    public static func file(directory: URL, name: String, extension ext: String) -> URL {
        return directory.appendingPathComponent(name).appendingPathExtension(ext)
    }
    
    public func concatingToFileName(_ string: String) -> URL {
        let ext = self.pathExtension
        return URL(fileURLWithPath: self.deletingPathExtension().deletingLastSplashIfThereIs.appending(string)).appendingPathExtension(ext)
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
        let path = self.deletingPathExtension().path.replacingOccurrences(of: URL.filesFolderPath, with: "")
            + DocumentConstants.documentDirSuffix
        return URL.directory(location: URLLocation.document, relativePath: path)
    }
    
    public var pathReleatedToRoot: String {
        return self.deletingPathExtension().path.replacingOccurrences(of: URL.filesFolderPath, with: "")
    }
    
    public var parentDir: URL {
        return self.parentDocumentURL?.deletingLastPathComponent() ?? URL.documentBaseURL
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
        return DocumentManager.Constants.filesFolder.path
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
        let seperator = DocumentManager.Constants.filesFolder.path
        return path.components(separatedBy: seperator).last!
    }
    
    public var coverURL: URL {
        return self.appendingPathComponent(Document.coverKey)
    }
}


extension URL {
    public func duplicate(completion: @escaping (URL?, Error?) -> Void) {
        let fileCoordinator = NSFileCoordinator()
        let read = NSFileAccessIntent.readingIntent(with: self, options: NSFileCoordinator.ReadingOptions.Element())
        
        let copyURL = self.concatingToFileName(" copy")
        let write = NSFileAccessIntent.writingIntent(with: copyURL,
                                                     options: NSFileCoordinator.WritingOptions.forReplacing)
        fileCoordinator.coordinate(with: [write, read], queue: OperationQueue()) { error in
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            } else {
                let fm = FileManager.default
                do {
                    try fm.copyItem(at: self, to: copyURL)
                    DispatchQueue.main.async {
                        completion(copyURL, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
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
                DispatchQueue.main.async {
                    completion(error)
                }
            } else {
                do {
                    try FileManager.default.removeItem(at: fileAccessIntent.url)
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }
    
    public func rename(url: URL, completion: ((Error?) -> Void)?) {
        let oldURL = self
        let newURL = url
        var error: NSError?
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            fileCoordinator.coordinate(writingItemAt: oldURL,
                                       options: NSFileCoordinator.WritingOptions.forMoving,
                                       writingItemAt: newURL,
                                       options: NSFileCoordinator.WritingOptions.forReplacing,
                                       error: &error,
                                       byAccessor: { (newURL1, newURL2) in
                                        do {
                                            let fileManager = FileManager.default
                                            fileCoordinator.item(at: oldURL, willMoveTo: newURL)
                                            try fileManager.moveItem(at: newURL1, to: newURL2)
                                            fileCoordinator.item(at: oldURL, didMoveTo: newURL)
                                            DispatchQueue.main.async {
                                                completion?(error)
                                            }
                                        } catch {
                                            DispatchQueue.main.async {
                                                completion?(error)
                                            }
                                        }
                                        
            })
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
