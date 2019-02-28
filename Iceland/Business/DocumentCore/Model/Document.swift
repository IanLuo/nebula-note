//
//  Document.swift
//  Iceland
//
//  Created by ian luo on 2018/12/3.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

public class DocumentInfo {
    public let name: String
    public var cover: UIImage? {
        return UIImage(contentsOfFile: coverURL.path)
    }
    public let url: URL
    public let coverURL: URL
    
    public init(name: String, cover: UIImage?, url: URL) {
        self.name = name
        self.coverURL = url.coverURL
        self.url = url
    }
    
    public init(wrapperURL: URL) {
        guard wrapperURL.path.hasSuffix(Document.fileExtension) else { fatalError("must be a '.icelande' file") }
        
        self.name = wrapperURL.fileName
        self.coverURL = wrapperURL.coverURL
        self.url = wrapperURL
    }
}

public struct DocumentNotification {
    public static let didUpdateDocumentContent = Notification.Name(rawValue: "didUpdateDocumentContent")
}

public class Document: UIDocument {
    public static let fileExtension = "iceland"
    public static let contentFileExtension = "org"
    public static let coverFileExtension = "jpg"
    public static let logsFileExtension = "log"
    
    var string: String = ""
    var logs: String = ""
    var cover: UIImage?
    var wrapper: FileWrapper?
    
    public static let contentKey: String = "content.org"
    public static let coverKey: String = "cover.jpg"
    public static let logsKey: String = "logs.log"
    
    public func updateCover(_ new: UIImage?) {
        self.cover = new
        if let oldWrapper = self.wrapper?.fileWrappers?[Document.coverKey] {
            self.wrapper?.removeFileWrapper(oldWrapper)
        }
        
        self.updateChangeCount(UIDocument.ChangeKind.done)
    }
    
    public func updateContent(_ new: String) {
        self.string = new
        if let oldWrapper = self.wrapper?.fileWrappers?[Document.contentKey] {
            self.wrapper?.removeFileWrapper(oldWrapper)
        }
        
        self.updateChangeCount(UIDocument.ChangeKind.done)
    }
    
    public func updateLogs(_ new: String) {
        self.string = new
        if let oldWrapper = self.wrapper?.fileWrappers?[Document.logsKey] {
            self.wrapper?.removeFileWrapper(oldWrapper)
        }
        
        self.updateChangeCount(UIDocument.ChangeKind.done)
    }
    
    public override func contents(forType typeName: String) throws -> Any {
        if self.wrapper == nil {
            self.wrapper = FileWrapper(directoryWithFileWrappers: [:])
        }
        
        if self.wrapper?.fileWrappers?[Document.contentKey] == nil {
            if let data = self.string.data(using: .utf8) {
                let textWrapper = FileWrapper(regularFileWithContents: data)
                textWrapper.preferredFilename = Document.contentKey
                self.wrapper?.addFileWrapper(textWrapper)
            }
        }
        
        if self.wrapper?.fileWrappers?[Document.coverKey] == nil {
            if let coverImage = self.cover {
                if let coverData = coverImage.jpegData(compressionQuality: 0.8) {
                    let coverWrapper = FileWrapper(regularFileWithContents: coverData)
                    coverWrapper.preferredFilename = Document.coverKey
                    self.wrapper?.addFileWrapper(coverWrapper)
                }
            }
        }
        
        if self.wrapper?.fileWrappers?[Document.logsKey] == nil {
            if let logsData = self.logs.data(using: .utf8) {
                let logsWrapper = FileWrapper(regularFileWithContents: logsData)
                logsWrapper.preferredFilename = Document.logsKey
                self.wrapper?.addFileWrapper(logsWrapper)
            }
        }
        
        return self.wrapper!
    }
    
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let wrapper = contents as? FileWrapper {
            self.wrapper = wrapper
            
            if let contentData = wrapper.fileWrappers?[Document.contentKey]?.regularFileContents {
                self.string = String(data: contentData, encoding: .utf8) ?? ""
            }
            
            if let imageData = wrapper.fileWrappers?[Document.coverKey]?.regularFileContents {
                self.cover = UIImage(data: imageData)
            }
            
            if let logsData = wrapper.fileWrappers?[Document.logsKey]?.regularFileContents {
                self.logs = String(data: logsData, encoding: .utf8) ?? ""
            }
        }
    }
    
    public override func save(to url: URL, for saveOperation: UIDocument.SaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        if self.hasUnsavedChanges {
            NotificationCenter.default.post(name: DocumentNotification.didUpdateDocumentContent, object: nil, userInfo: ["url": url])
        }
        
        super.save(to: url, for: saveOperation, completionHandler: completionHandler)
    }
}
