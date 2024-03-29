//
//  Document.swift
//  Iceland
//
//  Created by ian luo on 2018/12/3.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public enum OutlineLocation {
    case heading(DocumentHeading)
    case position(Int)
}

public class DocumentInfo {
    public let name: String
    public var cover: UIImage? {
        return UIImage(contentsOfFile: coverURL.path)
    }
    public let url: URL
    public let coverURL: URL
    public let id: String
    
    public init(name: String, cover: UIImage?, url: URL, coverURL: URL, id: String) {
        self.name = name
        self.coverURL = coverURL
        self.url = url
        self.id = id
    }
    
    public init(wrapperURL: URL) {
        guard wrapperURL.path.hasSuffix(Document.fileExtension) else { fatalError("must be a '.ice' file") }
        
        self.name = wrapperURL.packageName
        self.coverURL = wrapperURL.coverURL
        self.url = wrapperURL
        self.id = ""
    }
}

public class Document: UIDocument {
    public static let documentIdPrefix = "documentID:"
    public static let fileExtension = "ice"
    public static let contentFileExtension = "org"
    public static let coverFileExtension = "jpg"
    public static let logsFileExtension = "log"
    
    public var didUpdateDocumentContentAction: (() -> Void)?
    
    public private(set) var string: String = ""
    public private(set) var logs: String = "{}"
    public private(set) var cover: UIImage?
    private var _wrapper: FileWrapper?
    
    public static let contentKey: String = "content.org"
    public static let coverKey: String = "cover.jpg"
    public static let logsKey: String = "logs.log"
        
    public func updateCover(_ new: UIImage?) {
        self.cover = new
        if let oldWrapper = self._wrapper?.fileWrappers?[Document.coverKey] {
            self._wrapper?.removeFileWrapper(oldWrapper)
        }
        
        self.updateChangeCount(UIDocument.ChangeKind.done)
    }
    
    public func updateContent(_ new: String) {
        self.string = new
        if let oldWrapper = self._wrapper?.fileWrappers?[Document.contentKey] {
            self._wrapper?.removeFileWrapper(oldWrapper)
        }
        
        self.updateChangeCount(UIDocument.ChangeKind.done)
    }
    
    public func updateLogs(_ new: String) {
        self.logs = new
        if let oldWrapper = self._wrapper?.fileWrappers?[Document.logsKey] {
            self._wrapper?.removeFileWrapper(oldWrapper)
        }
        
        self.updateChangeCount(UIDocument.ChangeKind.done)
    }
    
    public override func contents(forType typeName: String) throws -> Any {
        if self._wrapper == nil {
            self._wrapper = FileWrapper(directoryWithFileWrappers: [:])
        }
        
        if self._wrapper?.fileWrappers?[Document.contentKey] == nil {
            if let data = self.string.data(using: .utf8) {
                let textWrapper = FileWrapper(regularFileWithContents: data)
                textWrapper.preferredFilename = Document.contentKey
                self._wrapper?.addFileWrapper(textWrapper)
            }
        }
        
        if self._wrapper?.fileWrappers?[Document.coverKey] == nil {
            if let coverImage = self.cover {
                if let coverData = coverImage.jpegData(compressionQuality: 0.8) {
                    let coverWrapper = FileWrapper(regularFileWithContents: coverData)
                    coverWrapper.preferredFilename = Document.coverKey
                    self._wrapper?.addFileWrapper(coverWrapper)
                }
            }
        }
        
        if self._wrapper?.fileWrappers?[Document.logsKey] == nil {
            if let logsData = self.logs.data(using: .utf8) {
                let logsWrapper = FileWrapper(regularFileWithContents: logsData)
                logsWrapper.preferredFilename = Document.logsKey
                self._wrapper?.addFileWrapper(logsWrapper)
            }
        }
        
        return self._wrapper!
    }
    
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let wrapper = contents as? FileWrapper {
            self._wrapper = wrapper
            
            if let contentData = wrapper.fileWrappers?[Document.contentKey]?.regularFileContents {
                self.string = String(data: contentData, encoding: .utf8) ?? ""
            }
            
            if let imageData = wrapper.fileWrappers?[Document.coverKey]?.regularFileContents {
                self.cover = UIImage(data: imageData)
            }
            
            if let logsData = wrapper.fileWrappers?[Document.logsKey]?.regularFileContents {
                self.logs = String(data: logsData, encoding: .utf8) ?? "{}"
                
                if self.logs == "" {
                    self.logs = "{}"
                }
            }
        }
    }
    
    public override func save(to url: URL, for saveOperation: UIDocument.SaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        if self.hasUnsavedChanges {
            self.didUpdateDocumentContentAction?()
        } else {
            return
        }
        
        log.info("begin to save ... \(url)")
        let time = CFAbsoluteTimeGetCurrent()
        super.save(to: url, for: saveOperation, completionHandler: { success in
            completionHandler?(success)
            if success {
                log.info("save complete \(CFAbsoluteTimeGetCurrent() - time) s ++")
            } else {
                log.info("save faild --")
            }
        })
    }
    
    public override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
}
