//
//  EditorServer.swift
//  Iceland
//
//  Created by ian luo on 2018/12/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIDocument

public class OutlineEditorServer: EditorServiceDelegate {
    private init() {}
    private static let _instance = OutlineEditorServer()
    
    private var instances: [URL: EditorService] = [:]
    
    private let editingQueue: DispatchQueue = DispatchQueue(label: "editor.doing.editing")
    
    public static func request(url: URL) -> EditorService {
        if let editorInstance = OutlineEditorServer._instance.instances[url] {
            return editorInstance
        } else {
            let newService = EditorService.connect(url: url, queue: OutlineEditorServer._instance.editingQueue)
            OutlineEditorServer._instance.instances[url] = newService
            return self.request(url: url)
        }
    }
    
    /// 当重命名后，将缓存中的旧文件名指向新的
    func didChangeFileName(to url: URL, old: URL) {
        instances[old] = instances[url]
    }
}

fileprivate protocol EditorServiceDelegate: class {
    func didChangeFileName(to url: URL, old: URL)
}

public class EditorService {
    private let editorController = EditorController(parser: OutlineParser())
    private var document: Document!
    fileprivate weak var delegate: EditorServiceDelegate?
    
    fileprivate init() {}
    
    private var queue: DispatchQueue!
    
    public var container: NSTextContainer {
        return editorController.textContainer
    }
    
    public var outlineDelegate: OutlineTextViewDelegate {
        return editorController
    }
    
    public func start(complete: @escaping (Bool, EditorService) -> Void) {
        queue.async { [unowned self] in
            if self.document.documentState == UIDocument.State.normal {
                complete(true, self)
            } else {
                self.document.open {
                    if $0 {
                        self.editorController.string = self.document.string
                        DispatchQueue.main.async {
                            complete(true, self)
                        }
                    } else {
                        DispatchQueue.main.async {
                            complete(false, self)
                        }
                    }
                    
                }
            }
        }
    }
    
    public var string: String {
        get { return editorController.string }
        set { self.replace(text: newValue, range: NSRange(location: 0, length: editorController.string.count)) }
        
    }
    
    public func replace(text: String, range: NSRange) {
        self.editorController.replace(text: text, in: range)
        self.save()
    }
    
    fileprivate static func connect(url: URL, queue: DispatchQueue) -> EditorService {
        let instance = EditorService()
        instance.document = Document(fileURL: url)
        instance.queue = queue
        return instance
    }
    
    public var fileURL: URL {
        return document.fileURL
    }
    
    /// 删除 due date
    public func removeDue(at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let dueRange = heading.due {
            let extendedRange = NSRange(location: dueRange.location - 1, length: dueRange.length + 1) // 还有一个换行符
            self.editorController.textStorage.replaceCharacters(in: extendedRange, with: "")
        }
        
        self.save() // FIXME: 更好的保存方式
    }
    
    public func removeSchedule(at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let scheduleRange = heading.schedule {
            let extendedRange = NSRange(location: scheduleRange.location - 1, length: scheduleRange.length + 1) // 还有一个换行符
            self.editorController.textStorage.replaceCharacters(in: extendedRange, with: "")
        }
        
        self.save() // FIXME: 更好的保存方式
    }
    
    public func remove(tag: String, at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let tagsRange = heading.tags {
            var newTags = document.string.subString(tagsRange)
            for t in document.string.subString(tagsRange).components(separatedBy: ":").filter({ $0.count > 0 }) {
                if t == tag {
                    newTags = newTags.replacingOccurrences(of: t, with: "")
                    if newTags == "::" {
                        newTags = ""
                    } else {
                        newTags = newTags.replacingOccurrences(of: "::", with: ":")
                    }
                    self.editorController.replace(text: newTags, in: tagsRange)
                    break
                }
            }
        }
        
        self.save() // FIXME: 更好的保存方式
    }
    
    public func removePlanning(at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let planningRange = heading.planning {
            self.editorController.textStorage.replaceCharacters(in: planningRange, with: "")
        }
        
        self.save() // FIXME: 更好的保存方式
    }
    
    public func update(planning: String, at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        var editRange: NSRange!
        var replacement: String!
        // 有旧的 planning，就直接替换这个字符串
        if let oldPlanningRange = heading.planning {
            editRange = oldPlanningRange
            replacement = planning
        } else {
            // 没有 planning， 则直接放在 level 之后添加
            editRange = NSRange(location: heading.level + 1, length: 0)
            replacement = planning + " "
        }
        
        editorController.textStorage.replaceCharacters(in: editRange, with: replacement)
        
        self.save() // FIXME: 更好的保存方式
    }
    
    public func update(schedule: DateAndTimeType, at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        var editRange: NSRange!
        var replacement: String!
        // 有旧的 schedule，就直接替换这个字符串
        if let oldScheduleRange = heading.schedule {
            editRange = oldScheduleRange
            replacement = schedule.toScheduleString()
        } else {
            // 没有 due date， 则直接放在 heading range 最后，注意要在新的一行
            editRange = NSRange(location: heading.range.upperBound, length: 0)
            replacement = "\n" + schedule.toScheduleString()
        }
        
        editorController.textStorage.replaceCharacters(in: editRange, with: replacement)
        
        self.save()// FIXME: 更好的保存方式
    }
    
    public func update(due: DateAndTimeType, at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        var editRange: NSRange!
        var replacement: String!
        
        // 如果有旧的 due date，直接替换就行了
        // 如果没有，添加到 heading range 的最后，注意要在新的一行
        if let oldDueDateRange = heading.due {
            editRange = oldDueDateRange
            replacement = due.toDueDateString()
        } else {
            editRange = NSRange(location: heading.range.upperBound, length: 0)
            replacement = "\n" + due.toScheduleString()
        }
        
        editorController.textStorage.replaceCharacters(in: editRange, with: replacement)
        
        self.save()// FIXME: 更好的保存方式
    }
    
    /// 添加 tag 到 heading
    public func add(tag: String, at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let tagsRange = heading.tags {
            editorController.insert(string: "\(tag):", at: tagsRange.upperBound)
        } else {
            editorController.insert(string: " :\(tag):", at: heading.tagLocation)
        }
        
        self.save()// FIXME: 更好的保存方式
    }
    
    public func archive(headingLocation: Int) {
        self.add(tag: OutlineParser.Values.Heading.Tag.archive, at: headingLocation)
    }
    
    public func unArchive(headingLocation: Int) {
        self.remove(tag: OutlineParser.Values.Heading.Tag.archive, at: headingLocation)
    }
    
    public func open(completion:((String?) -> Void)? = nil) {
        document.open { [weak self] (isOpenSuccessfully: Bool) in
            guard let strongSelf = self else { return }
            
            if isOpenSuccessfully {
                strongSelf.editorController.string = strongSelf.document.string // 触发解析
                completion?(strongSelf.document.string)
            } else {
                completion?(nil)
            }
        }
    }
    
    public func insert(content: String, headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        editorController.insertToParagraph(at: heading, content: content)
        
        self.save()// FIXME: 更好的保存方式
    }
    
    public func close(completion:((Bool) -> Void)? = nil) {
        document.close {
            completion?($0)
        }
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        let oldURL = self.fileURL
        let newURL = self.document.fileURL.deletingLastPathComponent().appendingPathComponent(newTitle).appendingPathExtension(Document.fileExtension)
        document.fileURL.rename(url: newURL, completion: completion)
        
        self.delegate?.didChangeFileName(to: newURL, old:oldURL)
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        queue.async {
            self.document.string = self.editorController.string
            self.document.save(to: self.document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { success in
                
                DispatchQueue.main.async {
                    completion?(success)
                }
            }
        }
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        self.document.fileURL.delete {
            completion?($0)
        }
    }
    
    public func find(target: String, found: @escaping ([NSRange]) -> Void) throws {
        let matcher = try NSRegularExpression(pattern: "\(target)", options: .caseInsensitive)
        let string = self.document.string
        var matchedRanges: [NSRange] = []
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            matcher.enumerateMatches(in: string,
                                     options: [],
                                     range: NSRange(location: 0, length: string.count)) { (result, flag, stop) in
                                        guard let range = result?.range else { return }
                                        matchedRanges.append(range)
            }
            
            DispatchQueue.main.async {
                found(matchedRanges)
            }
        }
    }
    
    // 返回 location 所在的 heading
    internal func heading(at location: Int) -> OutlineTextStorage.Heading? {
        for heading in self.editorController.getParagraphs() {
            if heading.paragraphRange.contains(location) {
                return heading
            }
        }
        return nil
    }
    
    internal func headingList() -> [OutlineTextStorage.Heading] {
        return self.editorController.getParagraphs()
    }
    
    /// 交换两个 paragraph 的内容
    public func replace(heading: OutlineTextStorage.Heading, with: OutlineTextStorage.Heading) {
        let temp = self.editorController.string.subString(heading.paragraphRange)
        self.editorController.replace(text: self.editorController.string.subString(with.paragraphRange), in: heading.paragraphRange)
        self.editorController.replace(text: temp, in: with.paragraphRange)
    }
}
