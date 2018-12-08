//
//  PageViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/1.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Storage

public protocol DocumentEditViewModelDelegate: class {
    func didClickLink(url: URL)
}

public class DocumentEditViewModel {
    public let editorController: EditorController
    public weak var delegate: DocumentEditViewModelDelegate?
    private var document: Document
    public var onLoadingLocation: Int = 0
    
    public init(editorController: EditorController,
                document: Document) {
        self.document = document
        self.editorController = editorController
        self.addStatesObservers()
    }
    
    deinit {
        self.removeObservers()
        self.close()
    }
    
    public func remove(due: Date, headingLocation: Int, completion: @escaping (Bool) -> Void) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let dueRange = heading.due {
            let extendedRange = NSRange(location: dueRange.location - 1, length: dueRange.length + 1)
            self.editorController.textStorage.replaceCharacters(in: extendedRange, with: "")
        }
        
        document.string = editorController.string
        self.save(completion: completion) // FIXME: 更好的保存方式
    }
    
    public func remove(schedule: Date, headingLocation: Int, completion: @escaping (Bool) -> Void) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let scheduleRange = heading.schedule {
            let extendedRange = NSRange(location: scheduleRange.location - 1, length: scheduleRange.length + 1)
            self.editorController.textStorage.replaceCharacters(in: extendedRange, with: "")
        }
        
        document.string = editorController.string
        self.save(completion: completion) // FIXME: 更好的保存方式
    }
    
    public func remove(tag: String, headingLocation: Int, completion: @escaping (Bool) -> Void) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let tagsRange = heading.tags {
            self.editorController.textStorage.replaceCharacters(in: tagsRange, with: "")
        }
        
        document.string = editorController.string
        self.save(completion: completion) // FIXME: 更好的保存方式
    }
    
    public func remove(planning: String, headingLocation: Int, completion: @escaping (Bool) -> Void) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let planningRange = heading.planning {
            self.editorController.textStorage.replaceCharacters(in: planningRange, with: "")
        }
        
        document.string = editorController.string
        self.save(completion: completion) // FIXME: 更好的保存方式
    }
    
    public func update(planning: String, includeTime: Bool, at headingLocation: Int, completion: @escaping (Bool) -> Void) {
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
        
        document.string = editorController.string
        self.save(completion: completion) // FIXME: 更好的保存方式
    }

    public func update(schedule: DateAndTimeType, at headingLocation: Int, completion: @escaping (Bool) -> Void) {
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
        
        document.string = editorController.string
        self.save(completion: completion)// FIXME: 更好的保存方式
    }
    
    public func update(due: DateAndTimeType, at headingLocation: Int, completion: @escaping (Bool) -> Void) {
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
        document.string = editorController.string
        self.save(completion: completion)// FIXME: 更好的保存方式
    }
        
    public func open(completion:((String?) -> Void)? = nil) {
        document.open { [weak self] (isOpenSuccessfully: Bool) in
            guard let strongSelf = self else { return }
            
            if isOpenSuccessfully {
                // 触发解析
                strongSelf.editorController.string = strongSelf.document.string
                completion?(strongSelf.document.string)
            } else {
                completion?(nil)
            }
        }
    }
    
    public func insert(content: String, headingLocation: Int, completion: @escaping (Bool) -> Void) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        editorController.insertToParagraph(at: heading, content: content)
        document.string = editorController.string
        self.save(completion: completion)// FIXME: 更好的保存方式
    }
    
    public func close(completion:((Bool) -> Void)? = nil) {
        document.close {
            completion?($0)
        }
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        let newURL = self.document.fileURL.deletingLastPathComponent().appendingPathComponent(newTitle).appendingPathExtension(Document.fileExtension)
        document.fileURL.rename(url: newURL, completion: completion) // FIXME: any problem？
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        document.string = editorController.string
        document.save(to: document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { success in
            completion?(success)
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
    
    internal func heading(at location: Int) -> OutlineTextStorage.Heading? {
        for heading in self.editorController.getParagraphs() {
            if heading.range.location == location {
                return heading
            }
        }
        return nil
    }
}

extension DocumentEditViewModel {
    fileprivate func addStatesObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStatesChanges),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleStatesChanges(notification: Notification) {
        if let state = notification.object as? UIDocument.State {
            if state.contains(.savingError) {
            }
        }
    }
}
