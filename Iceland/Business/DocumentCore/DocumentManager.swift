//
//  DocumentManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

public struct DocumentManager {
    public init() {
        Constants.filesFolder.createFolderIfNeeded()
    }
    
    public func query(in folder: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: folder,
                                                           includingPropertiesForKeys: nil,
                                                           options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            .filter { $0.pathExtension == Document.fileExtension }
            .map { folder.appendingPathComponent($0.path) }
    }
    
    public func add(title: String,
                        below: URL?,
                        completion: ((URL?) -> Void)? = nil) {
        var newURL: URL = URL.filesFolder.appendingPathComponent(title).appendingPathExtension(Document.fileExtension)
        if let below = below {
            let folderURL = below.convertoFolderURL
            var isDIR = ObjCBool(true)
            if !Foundation.FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDIR) {
                do { try Foundation.FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil) }
                catch { print("Error when touching dir for path: \(folderURL.path): error") }
            }
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
        document.save(to: newURL, for: UIDocument.SaveOperation.forCreating) { success in
            if success {
                completion?(newURL)
            } else {
                completion?(nil)
            }
        }
    }
    
    public func delete(url: URL,
                       completion: ((Error?) -> Void)? = nil) {
        do {
            // 1. 如果有子文件, 一并删除
            // 2. 如果删除之后文件夹为空，将空文件夹一并删除
            try FileManager.default.removeItem(at: url) // FIXME: use Filecorrdinator
            completion?(nil)
        } catch {
            log.error("failed to delete document: \(error)")
            completion?(error)
        }
    }
    
    public func rename(url: URL,
                to: String,
                below: URL?,
                completion: ((Error?) -> Void)? = nil) {
        var newURL: URL = url
        if let below = below {
            newURL = below.convertoFolderURL.appendingPathComponent(to).appendingPathExtension(Document.fileExtension)
        } else {
            newURL.deleteLastPathComponent()
            newURL.appendPathComponent(to)
        }
        url.rename(url: newURL, completion: completion)
    }
}

fileprivate struct Constants {
    static let filesFolderName = "files"
    static let filesFolder = File.Folder.document(filesFolderName)
}

private struct DocumentConstants {
    fileprivate static let documentDirSuffix: String = "__"
}

// MARK: - URL extension

extension URL {
    /// 一个文件，可以包含子文件，方法是，创建一个以该文件同名的文件夹(以'__'结尾)，放在同一目录
    /// 将当前文件的 URL 转为当前文件子文件夹的 URL
    public var convertoFolderURL: URL {
        let path = self.deletingPathExtension().path.replacingOccurrences(of: URL.filesFolderPath, with: "")
            + DocumentConstants.documentDirSuffix
        let folder = File.Folder.document(Constants.filesFolderName + "/" + path)
        return folder.url
    }
    
    public var pathReleatedToRoot: String {
        return self.deletingPathExtension().path.replacingOccurrences(of: URL.filesFolderPath, with: "")
    }
    
    public var urlReleatedToRoot: URL {
        return URL(string: self.deletingPathExtension().path.replacingOccurrences(of: URL.filesFolderPath, with: ""))!
    }
    
    public var parentDir: URL {
        return self.parentDocumentURL?.deletingLastPathComponent() ?? File.Folder.document(URL.filesFolderPath).url
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
    
    public static var filesFolder: URL {
        return Constants.filesFolder.url
    }
    
    public static var filesFolderPath: String {
        return Constants.filesFolder.path
    }
    
    public var hasSubDocuments: Bool {
        let subDocumentFolder = self.convertoFolderURL.path
        var isDir = ObjCBool(true)
        let fm = FileManager.default
        return fm.fileExists(atPath: subDocumentFolder, isDirectory: &isDir) &&
        ((try? fm.contentsOfDirectory(atPath: subDocumentFolder)) ?? []).count > 0
        
    }
}
