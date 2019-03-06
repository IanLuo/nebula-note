//
//  DocumentCommands.swift
//  Business
//
//  Created by ian luo on 2019/3/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public protocol DocumentContentCommand {
    func toggle(textStorage: OutlineTextStorage) -> Bool
}

// MARK: - ReplaceHeadingCommand
public class ReplaceHeadingCommand: DocumentContentCommand {
    let fromLocation: Int
    let toLocation: Int
    public init(fromLocation: Int, toLocation: Int) {
        self.fromLocation = fromLocation
        self.toLocation = toLocation
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        guard let fromHeading = textStorage.heading(contains: self.fromLocation) else { return false }
        guard let toHeading = textStorage.heading(contains: self.fromLocation) else { return false }
        
        let temp = textStorage.string.substring(fromHeading.paragraphRange)
        textStorage.replaceCharacters(in: fromHeading.paragraphRange, with: textStorage.string.substring(toHeading.paragraphRange))
        textStorage.replaceCharacters(in: toHeading.paragraphRange, with: temp)
        
        return true
    }
}

// MARK: - InsertTextToHeadingCommand
public class InsertTextToHeadingCommand: DocumentContentCommand {
    let location: Int
    let textToInsert: String
    public init(location: Int, textToInsert: String) {
        self.location = location
        self.textToInsert = textToInsert
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        guard let heading = textStorage.heading(contains: self.location) else { return false }
        
        let location = heading.contentRange.upperBound - 1
        
        return InsertTextCommand(location: location, textToInsert: self.textToInsert).toggle(textStorage: textStorage)
    }
}

// MARK: - InsertTextCommand
public class InsertTextCommand: DocumentContentCommand {
    let location: Int
    let textToInsert: String
    public init(location: Int, textToInsert: String) {
        self.location = location
        self.textToInsert = textToInsert
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        textStorage.replaceCharacters(in: NSRange(location: self.location, length: 0), with: self.textToInsert)
        return true
    }
}

// MARK: - FoldingCommand
public class FoldingCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        if let heading = textStorage.heading(contains: location) {
            log.info("fold range: \(heading.contentRange)")
            
            guard heading.contentRange.length > 0 else { return false }
            
            if textStorage.attribute(OutlineAttribute.hidden, at: heading.contentRange.location, effectiveRange: nil) == nil {
                // 标记内容为隐藏
                textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueFolded,
                                                OutlineAttribute.showAttachment: OutlineAttribute.Heading.folded],
                                               range: heading.contentRange)
                
                textStorage.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingFolded, range: heading.levelRange)
            } else {
                // 移除内容隐藏标记
                textStorage.removeAttribute(OutlineAttribute.hidden,
                                                 range: heading.contentRange)
                textStorage.removeAttribute(OutlineAttribute.showAttachment,
                                                 range: heading.contentRange)
                textStorage.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingUnfolded, range: heading.levelRange)
            }
        }
        
        return false
    }
}

// MARK: - AddAttachmentCommand
public class AddAttachmentCommand: DocumentContentCommand {
    let attachmentId: String
    let location: Int
    let type: String
    
    public init(attachmentId: String, location: Int, type: String) {
        self.attachmentId = attachmentId
        self.location = location
        self.type = type
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        let content = OutlineParser.Values.Attachment.serialize(type: type, value: self.attachmentId)
        
        return InsertTextCommand(location: self.location, textToInsert: content).toggle(textStorage: textStorage)
    }
}

// MARK: - CheckboxCommand
public class CheckboxCommand: DocumentContentCommand {
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        let status = textStorage.string.substring(range)
        
        var nextStatus: String = status
        switch status {
        case OutlineParser.Values.Checkbox.checked: fallthrough
        case OutlineParser.Values.Checkbox.halfChecked:
            nextStatus = OutlineParser.Values.Checkbox.unchecked
        default:
            nextStatus = OutlineParser.Values.Checkbox.checked
        }
        
        textStorage.replaceCharacters(in: range, with: nextStatus)
        
        return true
    }
    
    public let range: NSRange
    
    public init(range: NSRange) { self.range = range}
}

// MARK: - DueCommand
public class DueCommand: DocumentContentCommand {
    public enum Kind {
        case addOrUpdate(DateAndTimeType)
        case remove
    }
    
    public let kind: Kind
    public let location: Int
    
    public init(location: Int, kind: Kind) {
        self.location = location
        self.kind = kind
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        guard let heading = textStorage.heading(contains: self.location) else { return false }
        
        if let dueRange = heading.due {
            switch self.kind {
            case .remove:
                let extendedRange = NSRange(location: dueRange.location - 1, length: dueRange.length + 1) // 还有一个换行符
                textStorage.replaceCharacters(in: extendedRange, with: "")
            case .addOrUpdate(let date):
                var editRange: NSRange!
                var replacement: String!
                
                // 如果有旧的 due date，直接替换就行了
                // 如果没有，添加到 heading range 的最后，注意要在新的一行
                if let oldDueDateRange = heading.due {
                    editRange = oldDueDateRange
                    replacement = date.toDueDateString()
                } else {
                    editRange = NSRange(location: heading.range.upperBound, length: 0)
                    replacement = "\n" + date.toScheduleString()
                }
                
                textStorage.replaceCharacters(in: editRange, with: replacement)
            }
        }
        
        return true
    }
}

// MARK: - ScheduleCommand
public class ScheduleCommand: DocumentContentCommand {
    public enum Kind {
        case addOrUpdate(DateAndTimeType)
        case remove
    }
    
    public let kind: Kind
    public let location: Int
    
    public init(location: Int, kind: Kind) {
        self.location = location
        self.kind = kind
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        guard let heading = textStorage.heading(contains: self.location) else { return false }
        
        if let scheduleRange = heading.due {
            switch self.kind {
            case .remove:
                let extendedRange = NSRange(location: scheduleRange.location - 1, length: scheduleRange.length + 1) // 还有一个换行符
                textStorage.replaceCharacters(in: extendedRange, with: "")
            case .addOrUpdate(let date):
                var editRange: NSRange!
                var replacement: String!
                // 有旧的 schedule，就直接替换这个字符串
                if let oldScheduleRange = heading.schedule {
                    editRange = oldScheduleRange
                    replacement = date.toScheduleString()
                } else {
                    // 没有 due date， 则直接放在 heading range 最后，注意要在新的一行
                    editRange = NSRange(location: heading.range.upperBound, length: 0)
                    replacement = "\n" + date.toScheduleString()
                }
                
                textStorage.replaceCharacters(in: editRange, with: replacement)
            }
        }
        
        return true
    }
}

// MARK: - TagCommand
public class TagCommand: DocumentContentCommand {
    public enum Kind {
        case add(String)
        case remove(String)
    }
    
    let location: Int
    let kind: Kind
    
    public init(location: Int, kind: Kind) {
        self.location = location
        self.kind = kind
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        guard let heading = textStorage.heading(contains: self.location) else { return false }
        
        switch self.kind {
        case .remove(let tag):
            if let tagsRange = heading.tags {
                var newTags = textStorage.string.substring(tagsRange)
                for t in textStorage.string.substring(tagsRange).components(separatedBy: ":").filter({ $0.count > 0 }) {
                    if t == tag {
                        newTags = newTags.replacingOccurrences(of: t, with: "")
                        if newTags == "::" {
                            newTags = ""
                        } else {
                            newTags = newTags.replacingOccurrences(of: "::", with: ":")
                        }
                        textStorage.replaceCharacters(in: tagsRange, with: newTags)
                        break
                    }
                }
            }
            
        case .add(let tag):
            if let tagsRange = heading.tags {
                return InsertTextCommand(location: tagsRange.upperBound, textToInsert: "\(tag):").toggle(textStorage: textStorage)
            } else {
                return InsertTextCommand(location: heading.tagLocation, textToInsert: " :\(tag):").toggle(textStorage: textStorage)
            }
        }
        
        return true
    }
}

// MARK: - PlanningCommand

public class PlanningCommand: DocumentContentCommand {
    public enum Kind {
        case addOrUpdate(String)
        case remove
    }
    
    let location: Int
    let kind: Kind
    
    public init(location: Int, kind: Kind) {
        self.location = location
        self.kind = kind
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        guard let heading = textStorage.heading(contains: self.location) else { return false }
        
        switch self.kind {
        case .remove:
            if let planningRange = heading.planning {
                textStorage.replaceCharacters(in: planningRange, with: "")
            }
        case .addOrUpdate(let planning):
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
            
            textStorage.replaceCharacters(in: editRange, with: replacement)
        }
        
        return true
    }
}

// MARK: - ArchiveCommand
public class ArchiveCommand: TagCommand {
    public init(location: Int) {
        super.init(location: location, kind: .add(OutlineParser.Values.Heading.Tag.archive))
    }
}

// MARK: - UnarchiveCommand
public class UnarchiveCommand: TagCommand {
    public init(location: Int) {
        super.init(location: location, kind: .remove(OutlineParser.Values.Heading.Tag.archive))
    }
}
