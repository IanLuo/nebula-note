//
//  DocumentBrowserViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Storage

public protocol DocumentBrowserViewModelDelegate: class {
    func didSelectDocument(url: URL)
    func didSelectDocumentHeading(url: URL, headingLocation: Int)
}

public class DocumentBrowserViewModel {
    fileprivate struct Constants {
        static let filesFolderName = "files"
        static let filesFolder = File.Folder.document(filesFolderName)
    }
    
    public typealias Dependency = DocumentCoordinator
    
    public weak var delegate: DocumentBrowserViewModelDelegate?
    
    public weak var dependency: Dependency?
    
    public init() {
        Constants.filesFolder.createFolderIfNeeded()
    }
    
    func findDocuments(under: URL?) throws -> [URL] {
        if let under = under {
            return try findDocument(in: under.convertoFolderURL)
        } else {
            return try findDocument(in: URL.filesFolder)
        }
    }
    
    private func findDocument(in folder: URL) throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: folder,
                                                includingPropertiesForKeys: nil,
                                                options: .skipsHiddenFiles)
            .filter { $0.pathExtension == Document.fileExtension }
            .map { folder.appendingPathComponent($0.path) }
    }
    
    func createDocument(title: String,
                        below: URL?,
                        completion: ((URL?) -> Void)? = nil) {
        var newURL: URL = URL.filesFolder.appendingPathComponent(title).appendingPathExtension(Document.fileExtension)
        if let below = below {
            newURL = below.convertoFolderURL.appendingPathComponent(title).appendingPathExtension(Document.fileExtension)
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
    
    func deleteDocument(url: URL,
                        completion: ((Error?) -> Void)? = nil) {
        do {
            // TODO: 删除子文件
            try FileManager.default.removeItem(at: url) // FIXME: use Filecorrdinator
            completion?(nil)
        } catch {
            log.error("failed to delete document: \(error)")
            completion?(error)
        }
    }
    
    func rename(url: URL,
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

extension URL {
    /// 一个文件，可以包含子文件，方法是，创建一个以该文件同名的文件夹(以'__'结尾)，放在同一目录
    public var convertoFolderURL: URL {
        let path = self.deletingPathExtension().path.replacingOccurrences(of: URL.filesFolderPath, with: "")
            .components(separatedBy: "/")
            .map { $0 + "__" }
            .joined()
        let folder = File.Folder.document(DocumentBrowserViewModel.Constants.filesFolderName + "/" + path)
        folder.createFolderIfNeeded()
        return folder.url
    }
    
    public static var filesFolder: URL {
        return DocumentBrowserViewModel.Constants.filesFolder.url
    }
    
    public static var filesFolderPath: String {
        return DocumentBrowserViewModel.Constants.filesFolder.path
    }
}
