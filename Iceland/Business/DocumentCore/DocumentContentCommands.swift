//
//  DocumentCommands.swift
//  Business
//
//  Created by ian luo on 2019/3/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct DocumentContentCommandResult {
    public let isModifiedContent: Bool
    public let range: NSRange?
    public let content: String?
    public let delta: Int
    
    fileprivate static var noChange: DocumentContentCommandResult {
        return DocumentContentCommandResult(isModifiedContent: false, range: nil, content: nil, delta: 0)
    }
}

public protocol DocumentContentCommand {
    func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult
}

// MARK: - ReplaceHeadingCommand
public class ReplaceHeadingCommand: DocumentContentCommand {
    let fromLocation: Int
    let toLocation: Int
    public init(fromLocation: Int, toLocation: Int) {
        self.fromLocation = fromLocation
        self.toLocation = toLocation
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        guard let fromHeading = textStorage.heading(contains: self.fromLocation) else { return DocumentContentCommandResult.noChange }
        guard let toHeading = textStorage.heading(contains: self.fromLocation) else { return DocumentContentCommandResult.noChange }
        
        let stringToReplace = textStorage.string.substring(toHeading.paragraphRange).appending(textStorage.string.substring(fromHeading.paragraphRange))
        
        return ReplaceTextCommand(range: fromHeading.range.union(toHeading.range), textToReplace: stringToReplace).toggle(textStorage:textStorage)
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
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        guard let heading = textStorage.heading(contains: self.location) else { return DocumentContentCommandResult.noChange }
        
        let location = heading.paragraphRange.upperBound - 1
        
        return InsertTextCommand(location: location, textToInsert: self.textToInsert).toggle(textStorage: textStorage)
    }
}

// MARK: - InsertTextCommand
public class InsertTextCommand: DocumentContentCommand {
    let replaceTextCommand: ReplaceTextCommand
    public init(location: Int, textToInsert: String) {
        self.replaceTextCommand = ReplaceTextCommand(range: NSRange(location: location, length: 0), textToReplace: textToInsert)
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        return self.replaceTextCommand.toggle(textStorage: textStorage)
    }
}

public class ReplaceTextCommand: DocumentContentCommand {
    let range: NSRange
    let textToReplace: String
    
    public init(range: NSRange, textToReplace: String) {
        self.range = range
        self.textToReplace = textToReplace
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        textStorage.replaceCharacters(in: self.range, with: self.textToReplace)
        let undoRange = NSRange(location: self.range.location, length: self.textToReplace.count)
        let undoString = textStorage.string.substring(self.range)
        return DocumentContentCommandResult(isModifiedContent: true, range: undoRange, content: undoString, delta: undoRange.length - self.range.length)
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
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        if let heading = textStorage.heading(contains: location) {
            
            log.info("fold range: \(heading.contentRange)")
            
            guard heading.contentRange.length > 0 else { return DocumentContentCommandResult.noChange }
            
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
        
        return DocumentContentCommandResult.noChange
    }
}

// MARK: FoldAllCommand
public class FoldAllCommand: FoldingAndUnfoldingCommand {
    public init() {
        super.init(location: 0)
    }
    
    public override func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        for heading in textStorage.topLevelHeadings {
            super._fold(heading: heading, textStorage: textStorage)
        }
        
        return DocumentContentCommandResult.noChange
    }
}

// MARK: UnFoldAllCommand
public class UnFoldAllCommand: FoldingAndUnfoldingCommand {
    public init() {
        super.init(location: 0)
    }
    
    public override func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        for heading in textStorage.topLevelHeadings {
            super._unFoldHeadingAndChildren(heading: heading, textStorage: textStorage)
        }
        
        return DocumentContentCommandResult.noChange
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
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        let content = OutlineParser.Values.Attachment.serialize(kind: kind, value: self.attachmentId)
        
        return InsertTextCommand(location: self.location, textToInsert: content).toggle(textStorage: textStorage)
    }
}

// MARK: - CheckboxCommand
public class CheckboxStatusCommand: DocumentContentCommand {
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        let status = textStorage.string.substring(range)
        
        var nextStatus: String = status
        switch status {
        case OutlineParser.Values.Checkbox.checked: fallthrough
        case OutlineParser.Values.Checkbox.halfChecked:
            nextStatus = OutlineParser.Values.Checkbox.unchecked
        default:
            nextStatus = OutlineParser.Values.Checkbox.checked
        }
        
        return ReplaceTextCommand(range: range, textToReplace: nextStatus).toggle(textStorage: textStorage)
    }
    
    public let range: NSRange
    
    public init(range: NSRange) { self.range = range}
}

// MARK: - UpdateDateAndTimeCommand
public class UpdateDateAndTimeCommand: DocumentContentCommand {
    let range: NSRange
    let newDateAndTime: DateAndTimeType
    
    public init(range: NSRange, dateAndTime: DateAndTimeType) {
        self.range = range
        self.newDateAndTime = dateAndTime
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        return ReplaceTextCommand(range: self.range, textToReplace: self.newDateAndTime.markString).toggle(textStorage: textStorage)
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
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        guard let heading = textStorage.heading(contains: self.location) else { return DocumentContentCommandResult.noChange }
        
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
                        return ReplaceTextCommand(range: tagsRange, textToReplace: newTags).toggle(textStorage: textStorage)
                    }
                }
            }
            
            return DocumentContentCommandResult.noChange
        case .add(let tag):
            if let tagsRange = heading.tags {
                return InsertTextCommand(location: tagsRange.upperBound, textToInsert: "\(tag):").toggle(textStorage: textStorage)
            } else {
                return InsertTextCommand(location: heading.tagLocation, textToInsert: " :\(tag):").toggle(textStorage: textStorage)
            }
        }
        
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
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        guard let heading = textStorage.heading(contains: self.location) else { return DocumentContentCommandResult.noChange }
        
        switch self.kind {
        case .remove:
            if let planningRange = heading.planning {
                return ReplaceTextCommand(range: planningRange, textToReplace: "").toggle(textStorage: textStorage)
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
            
            return ReplaceTextCommand(range: editRange, textToReplace: replacement).toggle(textStorage: textStorage)
        }
        
        return DocumentContentCommandResult.noChange
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

    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        let temp = textStorage.string.substring(self.range)
        let replacement = self.markType.mark + temp + self.markType.mark

        return ReplaceTextCommand(range: self.range, textToReplace: replacement).toggle(textStorage: textStorage)
    }
}

// MARK: - AddSeparatorCommand
public class AddSeparatorCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        return InsertTextCommand(location: self.location, textToInsert: OutlineParser.Values.separator).toggle(textStorage: textStorage)
    }
}


public class IncreaseIndentCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        var start = 0
        var end = 0
        var content = 0
        (textStorage.string as NSString).getLineStart(&start,
                                                      end: &end,
                                                      contentsEnd: &content,
                                                      for: NSRange(location: self.location, length: 0))

        return InsertTextCommand(location: start, textToInsert: OutlineParser.Values.Character.tab).toggle(textStorage: textStorage)
    }
}

public class DecreaseIndentCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
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
                return ReplaceTextCommand(range: range, textToReplace: "").toggle(textStorage: textStorage)
            } else {
                return DocumentContentCommandResult.noChange
            }
        } else {
            return DocumentContentCommandResult.noChange
        }
    }
}


// MARK: - QuoteBlockCommand
public class QuoteBlockCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        // TODO:
        return DocumentContentCommandResult.noChange
    }
}

// MARK: -
public class CodeBlockCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        // TODO:
        return DocumentContentCommandResult.noChange
    }
}

// MARK: - UnorderdListSwitchCommand
/// 切换当前行是否 unorderd list
public class UnorderdListSwitchCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        let lineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).location
        
        for case let token in (textStorage.token(at: lineStart) ?? []) where token.name == OutlineParser.Key.Node.unordedList {
            if let prefixRange = token.data[OutlineParser.Key.Element.UnorderedList.prefix] {
                return ReplaceTextCommand(range: prefixRange, textToReplace: "").toggle(textStorage: textStorage)
            } else {
                return DocumentContentCommandResult.noChange
            }
        }
        
        return InsertTextCommand(location: lineStart, textToInsert: OutlineParser.Values.List.unorderedList).toggle(textStorage: textStorage)
    }
}

// MARK: - OrderedListSwitchCommand
/// 切换当前行是否 orderd list
public class OrderedListSwitchCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        let lineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).location
        
        for case let token in (textStorage.token(at: lineStart) ?? []) where token.name == OutlineParser.Key.Node.ordedList {
            if let prefixRange = token.data[OutlineParser.Key.Element.OrderedList.prefix] {
                return ReplaceTextCommand(range: prefixRange, textToReplace: "").toggle(textStorage: textStorage)
            } else {
                return DocumentContentCommandResult.noChange
            }
        }
        
        if lineStart > 0 {
            // 1. find last line index
            let lastLineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: lineStart - 1, length: 0)).location
            for case let token in (textStorage.token(at: lastLineStart) ?? []) where token.name == OutlineParser.Key.Node.ordedList {
                // 2. insert index
                let lastPrefix = textStorage.string.substring(token.data[OutlineParser.Key.Element.OrderedList.prefix]!)
                return InsertTextCommand(location: lineStart,
                                         textToInsert: OutlineParser.Values.List.orderListIncrease(prefix: lastPrefix))
                    .toggle(textStorage: textStorage)
            }
            
            // 2.2 use default index
            return InsertTextCommand(location: lineStart, textToInsert: OutlineParser.Values.List.orderdList(index: "1"))
                .toggle(textStorage: textStorage)
        } else {
            return InsertTextCommand(location: lineStart, textToInsert: OutlineParser.Values.List.orderdList(index: "1"))
                .toggle(textStorage: textStorage)
        }
    }
}

// MARK: - CheckboxSwitchCommand
/// 切换当前行是否 checkbox
public class CheckboxSwitchCommand: DocumentContentCommand {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func toggle(textStorage: OutlineTextStorage) -> DocumentContentCommandResult {
        let lineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).location
        
        for case let token in (textStorage.token(at: lineStart) ?? []) where token.name == OutlineParser.Key.Node.checkbox {
            return ReplaceTextCommand(range: token.range, textToReplace: "").toggle(textStorage: textStorage)
        }
        
        return InsertTextCommand(location: lineStart, textToInsert: OutlineParser.Values.Checkbox.unchecked).toggle(textStorage: textStorage)
    }
}
