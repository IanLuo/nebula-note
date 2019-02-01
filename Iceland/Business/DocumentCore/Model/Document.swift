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
        super.save(to: url, for: saveOperation, completionHandler: completionHandler)
    }
    
    /// Node 和 element 都是 Item
    public class Item {
        public var offset: Int = 0 {
            didSet {
                log.verbose("offset did set: \(offset)")
            }
        }
        private var previouse: Item?
        private var next: Item?
        private var _range: NSRange
        public var range: NSRange {
            set { _range = newValue }
            get { return offset == 0 ? _range : _range.offset(self.offset) }
        }
        public var name: String
        public var data: [String: NSRange]
        
        public init(range: NSRange, name: String, data: [String: NSRange]) {
            self._range = range
            self.name = name
            self.data = data
        }
        
        public func offset(_ offset: Int) {
            self.offset += offset
            next?.offset(offset)
        }
    }
    
    public class Heading: Item {
        /// 当前的 heading 的 planning TODO|DONE|CANCELD 等
        public var planning: NSRange? {
            return data[OutlineParser.Key.Element.Heading.planning]?.offset(offset)
        }
        /// 当前 heading 的 tag 数组
        public var tags: NSRange? {
            return data[OutlineParser.Key.Element.Heading.tags]?.offset(offset)
        }
        /// 当前 heading 的 schedule
        public var schedule: NSRange? {
            return data[OutlineParser.Key.Element.Heading.schedule]?.offset(offset)
        }
        /// 当前 heading 的 due
        public var due: NSRange? {
            return data[OutlineParser.Key.Element.Heading.due]?.offset(offset)
        }
        /// 当前的 heading level
        public var level: Int {
            return data[OutlineParser.Key.Element.Heading.level]!.length
        }
        
        /// close 标记
        public var closed: NSRange? {
            return data[OutlineParser.Key.Element.Heading.closed]?.offset(offset)
        }
        
        /// tag 的位置，如果没有 tag，则为应该放 tag 的位置
        public var tagLocation: Int {
            if let tags = self.tags {
                return tags.location
            }
            
            if let schedule = self.schedule, let due = self.due {
                return min(schedule.location, due.location)
            }
            
            if let schedule = self.schedule {
                return schedule.location
            }
            
            if let due = self.due {
                return due.location
            }
            
            return range.upperBound
        }
        
        public var contentLength: Int = 0
        
        public var headingTextRange: NSRange {
            var headingContentRange: NSRange = self.range.offset(-self.range.location).moveLeft(by: self.level + 1)
            
            if let schedule = self.schedule {
                let dateRange = schedule.offset(-self.range.location)
                let newUpperBound = min(dateRange.lowerBound, headingContentRange.upperBound)
                headingContentRange = headingContentRange.withNewUpperBound(newUpperBound)
            }
            
            if let due = self.due {
                let dateRange = due.offset(-self.range.location)
                let newUpperBound = min(dateRange.lowerBound, headingContentRange.upperBound)
                headingContentRange = headingContentRange.withNewUpperBound(newUpperBound)
            }
            
            if let planning = self.planning {
                let planningRange = planning.offset(-self.range.location)
                let newLowerBound = max(headingContentRange.lowerBound, planningRange.upperBound + 1)
                headingContentRange = headingContentRange.withNewLowerBound(newLowerBound)
            }
            
            if let tags = self.tags {
                let tagsRange = tags.offset(-self.range.location)
                let newUpperBound = min(tagsRange.lowerBound - 1, headingContentRange.upperBound)
                headingContentRange = headingContentRange.withNewUpperBound(newUpperBound)
            }
            
            return headingContentRange
        }
        
        public var contentRange: NSRange {
            return NSRange(location: self.range.upperBound, length: self.contentLength)
        }
        
        public var paragraphRange: NSRange {
            return NSRange(location: range.location, length: contentLength + range.length)
        }
        
        public convenience init(data: [String: NSRange]) {
            self.init(range: data[OutlineParser.Key.Node.heading]!, name: OutlineParser.Key.Node.heading, data: data)
            log.verbose("new heading: \(range)")
        }
    }
    
}
