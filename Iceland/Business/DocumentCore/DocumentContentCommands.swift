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
        
        let location = heading.paragraphRange.upperBound - 1
        
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

// MARK: - FoldingAndUnfoldingCommand
public class FoldingAndUnfoldingCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    fileprivate func _markUnfold(heading: HeadingToken, textStorage: OutlineTextStorage) {
        var range = heading.contentRange.moveLeftBound(by: -1).moveRightBound(by: -1)
        range = range.length > 0 ? range : NSRange(location: range.location, length: 0)
        
        textStorage.addAttributes([OutlineAttribute.tempHidden: 0,
                                   OutlineAttribute.tempShowAttachment: ""],
                                  range: range)
        
        textStorage.addAttributes([OutlineAttribute.showAttachment: OutlineAttribute.Heading.foldingUnfolded,
                                   OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment],
                                  range: heading.levelRange)
    }
    
    fileprivate func _markFold(heading: HeadingToken, textStorage: OutlineTextStorage) {
        var range = heading.contentRange.moveLeftBound(by: -1).moveRightBound(by: -1)
        range = range.length > 0 ? range : NSRange(location: range.location, length: 0)
        
        textStorage.addAttributes([OutlineAttribute.tempHidden: OutlineAttribute.hiddenValueFolded,
                                   OutlineAttribute.tempShowAttachment: OutlineAttribute.Heading.folded],
                                  range: range)
        
        textStorage.addAttributes([OutlineAttribute.showAttachment: OutlineAttribute.Heading.foldingFolded,
                                   OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment],
                                  range: heading.levelRange)
    }
    
    fileprivate func _unFoldHeadingAndChildren(heading: HeadingToken, textStorage: OutlineTextStorage) {
        self._markUnfold(heading: heading, textStorage: textStorage)
        for child in textStorage.subheadings(of: heading) {
            self._markUnfold(heading: child, textStorage: textStorage)
        }
    }
    
    fileprivate func _unFoldHeadingButFoldChildren(heading: HeadingToken, textStorage: OutlineTextStorage) {
        self._markUnfold(heading: heading, textStorage: textStorage)
        for child in textStorage.subheadings(of: heading) {
            if !self._isFolded(heading: child, textStorage: textStorage) {
                self._fold(heading: child, textStorage: textStorage)
            }
        }
    }
    
    fileprivate func _fold(heading: HeadingToken, textStorage: OutlineTextStorage) {
        self._markFold(heading: heading, textStorage: textStorage)
        for child in textStorage.subheadings(of: heading) {
            if !self._isFolded(heading: child, textStorage: textStorage) {
                self._fold(heading: child, textStorage: textStorage)
            }
        }
    }
    
    fileprivate func _isFolded(heading: HeadingToken, textStorage: OutlineTextStorage) -> Bool {
        return textStorage.attribute(OutlineAttribute.tempHidden, at: heading.contentRange.location, effectiveRange: nil) as? Int != 0
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        if let heading = textStorage.heading(contains: location) {
            
            log.info("fold range: \(heading.contentRange)")
            
            guard heading.contentRange.length > 0 else { return false }
            
            textStorage.beginEditing()
            if _isFolded(heading: heading, textStorage: textStorage) {
                self._markUnfold(heading: heading, textStorage: textStorage)
            } else {
                var isEveryChildrenUnfold: Bool = true
                for child in textStorage.subheadings(of: heading) {
                    if self._isFolded(heading: child, textStorage: textStorage) {
                        isEveryChildrenUnfold = false
                        self._unFoldHeadingButFoldChildren(heading: child, textStorage: textStorage)
                    }
                }
                
                if isEveryChildrenUnfold {
                    self._fold(heading: heading, textStorage: textStorage)
                }
            }
            textStorage.endEditing()
        }
        
        return false
    }
}

// MARK: FoldAllCommand
public class FoldAllCommand: FoldingAndUnfoldingCommand {
    public init() {
        super.init(location: 0)
    }
    
    public override func toggle(textStorage: OutlineTextStorage) -> Bool {
        for heading in textStorage.topLevelHeadings {
            super._fold(heading: heading, textStorage: textStorage)
        }
        
        return false
    }
}

// MARK: UnFoldAllCommand
public class UnFoldAllCommand: FoldingAndUnfoldingCommand {
    public init() {
        super.init(location: 0)
    }
    
    public override func toggle(textStorage: OutlineTextStorage) -> Bool {
        for heading in textStorage.topLevelHeadings {
            super._unFoldHeadingAndChildren(heading: heading, textStorage: textStorage)
        }
        
        return false
    }
}

// MARK: - AddAttachmentCommand
public class AddAttachmentCommand: DocumentContentCommand {
    let attachmentId: String
    let location: Int
    let kind: String
    
    public init(attachmentId: String, location: Int, kind: String) {
        self.attachmentId = attachmentId
        self.location = location
        self.kind = kind
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        let content = OutlineParser.Values.Attachment.serialize(kind: kind, value: self.attachmentId)
        
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
//public class DueCommand: DocumentContentCommand {
//    public enum Kind {
//        case addOrUpdate(DateAndTimeType)
//        case remove
//    }
//
//    public let kind: Kind
//    public let location: Int
//
//    public init(location: Int, kind: Kind) {
//        self.location = location
//        self.kind = kind
//    }
//
//    public func toggle(textStorage: OutlineTextStorage) -> Bool {
//        guard let heading = textStorage.heading(contains: self.location) else { return false }
//
//        switch self.kind {
//        case .remove:
//            guard let due = heading.due else { return false }
//
//            let extendedRange = NSRange(location: due.location - 1, length: due.length + 1) // 还有一个换行符
//            textStorage.replaceCharacters(in: extendedRange, with: "")
//        case .addOrUpdate(let date):
//            // 如果有 due，添加在 due 之前
//
//            var editRange: NSRange!
//            var replacement: String = date.markString
//
//            if let oldDue = heading.due {
//                editRange = oldDue
//            } else {
//                editRange = heading.range.tail(0)
//                replacement.insert("\n", at: replacement.startIndex)
//            }
//
//            textStorage.replaceCharacters(in: editRange, with: replacement)
//        }
//
//        return true
//    }
//}

// MARK: - ScheduleCommand
//public class ScheduleCommand: DocumentContentCommand {
//    public enum Kind {
//        case addOrUpdate(DateAndTimeType)
//        case remove
//    }
//
//    public let kind: Kind
//    public let location: Int
//
//    public init(location: Int, kind: Kind) {
//        self.location = location
//        self.kind = kind
//    }
//
//    public func toggle(textStorage: OutlineTextStorage) -> Bool {
//        guard let heading = textStorage.heading(contains: self.location) else { return false }
//
//        switch self.kind {
//        case .remove:
//            guard let scheduleRange = heading.schedule else { return false }
//
//            let extendedRange = NSRange(location: scheduleRange.location - 1, length: scheduleRange.length + 1) // 还有一个换行符
//            textStorage.replaceCharacters(in: extendedRange, with: "")
//        case .addOrUpdate(let date):
//            // 如果有 due，添加在 due 之前
//
//            var editRange: NSRange!
//            var replacement: String = date.markString
//
//            if let oldSchedule = heading.schedule {
//                editRange = oldSchedule
//            } else {
//                editRange = heading.range.tail(0)
//                replacement.insert("\n", at: replacement.startIndex)
//            }
//
//            textStorage.replaceCharacters(in: editRange, with: replacement)
//        }
//
//        return true
//    }
//}

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

// MARK: - AddMarkCommand
public class AddMarkCommand: DocumentContentCommand {
    public let markType: OutlineParser.MarkType
    public let range: NSRange
    
    public init(markType: OutlineParser.MarkType, range: NSRange) {
        self.markType = markType
        self.range = range
    }

    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        let temp = textStorage.string.substring(self.range)
        let replacement = self.markType.mark + temp + self.markType.mark
        textStorage.replaceCharacters(in: self.range, with: replacement)
        return true
    }
}

// MARK: - AddSeparatorCommand
public class AddSeparatorCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        textStorage.replaceCharacters(in: NSRange(location: self.location, length: 0), with: OutlineParser.Values.separator)
        return true
    }
}


public class IncreaseIndentCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        var start = 0
        var end = 0
        var content = 0
        (textStorage.string as NSString).getLineStart(&start,
                                                      end: &end,
                                                      contentsEnd: &content,
                                                      for: NSRange(location: self.location, length: 0))

        textStorage.replaceCharacters(in: NSRange(location: start, length: 0),
                                      with: OutlineParser.Values.Character.tab)
        return true
    }
}

public class DecreaseIndentCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        var start = 0
        var end = 0
        var content = 0
        (textStorage.string as NSString).getLineStart(&start,
                                                      end: &end,
                                                      contentsEnd: &content,
                                                      for: NSRange(location: self.location, length: 0))

        let line = textStorage.string.substring(NSRange(location: start, length: end - start))
        
        if line.hasPrefix(OutlineParser.Values.Character.tab) {
            let range = (line as NSString).range(of: OutlineParser.Values.Character.tab).offset(start)
            if range.length > 0 {
                textStorage.replaceCharacters(in: range, with: "")
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}


// MARK: - QuoteBlockCommand
public class QuoteBlockCommand: DocumentContentCommand {
    public let range: NSRange
    
    public init(range: NSRange) {
        self.range = range
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        return false
    }
}

// MARK: -
public class CodeBlockCommand: DocumentContentCommand {
    public let range: NSRange
    
    public init(range: NSRange) {
        self.range = range
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> Bool {
        return false
    }
}
