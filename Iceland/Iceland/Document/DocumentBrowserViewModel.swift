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
    func didSelectDocument(document: Document)
    func didSelectDocument(document: Document, location: Int)
}

public class DocumentBrowserViewModel {
    fileprivate struct Constants {
        static let filesFolderName = "files"
        static let filesFolder = File.Folder.document(filesFolderName)
    }
    
    public weak var delegate: DocumentBrowserViewModelDelegate?
    
    public init() {
        Constants.filesFolder.createFolderIfNeeded()
    }
    
    func findDocuments(below: URL?) throws -> [URL] {
        if let below = below {
            return try findDocument(in: below.convertoFolderURL)
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
        document.string = ""
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
            try FileManager.default.removeItem(at: url)
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
    public var convertoFolderURL: URL {
        let path = self.deletingPathExtension().path.replacingOccurrences(of: URL.filesFolderPath, with: "")
            .components(separatedBy: "/")
            .map { "_" + $0 }
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
