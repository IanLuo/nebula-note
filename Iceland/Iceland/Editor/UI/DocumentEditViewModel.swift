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
    func didChangeHeading()
}

public class DocumentEditViewModel {
    public let editorController: EditorController
    public weak var delegate: DocumentEditViewModelDelegate?
    private var document: Document
    public var onLoadingLocation: Int = 0
    public typealias Dependency = DocumentCoordinator
    public weak var dependency: Dependency?
    
    public init(editorController: EditorController,
                document: Document) {
        self.document = document
        self.editorController = editorController
        self.editorController.delegate = self
        self.addStatesObservers()
    }
    
    deinit {
        self.removeObservers()
        self.close()
    }
    
    /// 删除 due date
    public func remove(due: Date, at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let dueRange = heading.due {
            let extendedRange = NSRange(location: dueRange.location - 1, length: dueRange.length + 1) // 还有一个换行符
            self.editorController.textStorage.replaceCharacters(in: extendedRange, with: "")
        }
        
        self.save() // FIXME: 更好的保存方式
    }
    
    public func remove(schedule: Date, at headingLocation: Int) {
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
    
    public func remove(planning: String, at headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        if let planningRange = heading.planning {
            if planning == (document.string as NSString).substring(with: planningRange) {
                self.editorController.textStorage.replaceCharacters(in: planningRange, with: "")
            }
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
}

// MARK: - EditorControllerDelegate
extension DocumentEditViewModel: EditorControllerDelegate {
    public func currentHeadingDidChnage(heading: OutlineTextStorage.Heading?) {
        self.delegate?.didChangeHeading()
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
