//
//  Document.swift
//  Iceland
//
//  Created by ian luo on 2018/12/3.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Storage

public class Document: UIDocument {
    public static let fileExtension = "org"
    var string: String = ""
    var title: String = ""
    
    public override init(fileURL url: URL) {
        let ext = url.absoluteString.hasSuffix(Document.fileExtension) ? "" : Document.fileExtension
        super.init(fileURL: url.appendingPathExtension(ext))
    }
    
    public override var fileType: String? { return "txt" }
    
    public override func contents(forType typeName: String) throws -> Any {
        return string.data(using: .utf8) as Any
    }
    
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let data = contents as? Data {
            self.string = String(data: data, encoding: .utf8)!
        }
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
        
        public var paragraphRange: NSRange {
            return NSRange(location: range.location, length: contentLength)
        }
        
        public convenience init(data: [String: NSRange]) {
            self.init(range: data[OutlineParser.Key.Node.heading]!, name: OutlineParser.Key.Node.heading, data: data)
            log.verbose("new heading: \(range)")
        }
    }
    
}

extension URL {
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
