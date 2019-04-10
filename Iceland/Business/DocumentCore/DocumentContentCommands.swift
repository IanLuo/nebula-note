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
    func perform() -> DocumentContentCommandResult
}

public protocol DocumentContentCommandComposer {
    func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand
}

public struct NoChangeCommand: DocumentContentCommand {
    public init() {}
    public func perform() -> DocumentContentCommandResult {
        return DocumentContentCommandResult.noChange
    }
}

public class ReplaceTextCommand: DocumentContentCommand {
    let range: NSRange
    let textToReplace: String
    let textStorage: OutlineTextStorage
    
    public init(range: NSRange, textToReplace: String, textStorage: OutlineTextStorage) {
        self.textStorage = textStorage
        self.range = range
        self.textToReplace = textToReplace
    }
    
    public func perform() -> DocumentContentCommandResult {
        let undoRange = NSRange(location: self.range.location, length: self.textToReplace.count)
        let undoString = self.textStorage.string.substring(self.range)
        self.textStorage.replaceCharacters(in: self.range, with: self.textToReplace)
        return DocumentContentCommandResult(isModifiedContent: true, range: undoRange, content: undoString, delta: self.textToReplace.count - self.range.length)
    }
}

// MARK: - NoChangeCommandComposer
public class NoChangeCommandComposer: DocumentContentCommandComposer {
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return NoChangeCommand()
    }
}

// MARK: - FoldingAndUnfoldingCommand
public class FoldingAndUnfoldingCommand: DocumentContentCommand {
    public let location: Int
    public let textStorage: OutlineTextStorage
    
    public init(location: Int, textStorage: OutlineTextStorage) {
        self.textStorage = textStorage
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
    
    public func perform() -> DocumentContentCommandResult {
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
    public init(textStorage: OutlineTextStorage) {
        super.init(location: 0, textStorage: textStorage)
    }
    
    public override func perform() -> DocumentContentCommandResult {
        for heading in textStorage.topLevelHeadings {
            super._fold(heading: heading, textStorage: textStorage)
        }
        
        return DocumentContentCommandResult.noChange
    }
}

// MARK: UnFoldAllCommand
public class UnFoldAllCommand: FoldingAndUnfoldingCommand {
    public init(textStorage: OutlineTextStorage) {
        super.init(location: 0, textStorage: textStorage)
    }
    
    public override func perform() -> DocumentContentCommandResult {
        for heading in textStorage.topLevelHeadings {
            super._unFoldHeadingAndChildren(heading: heading, textStorage: textStorage)
        }
        
        return DocumentContentCommandResult.noChange
    }
}

// MARK: ReplaceContentComposer
public class ReplaceContentCommandComposer: DocumentContentCommandComposer {
    let range: NSRange
    let textToReplace: String
    public init(range: NSRange, textToReplace: String) {
        self.range = range
        self.textToReplace = textToReplace
    }
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return ReplaceTextCommand(range: self.range, textToReplace: self.textToReplace, textStorage: textStorage)
    }
}

// MARK: FoldCommandComposer
public class FoldCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) { self.location = location }
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return FoldingAndUnfoldingCommand(location: self.location, textStorage: textStorage)
    }
}

// MARK: - MoveLineUpCommandComposer
public class MoveLineUpCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        for case let token in textStorage.token(at: self.location) ?? [] where token is HeadingToken {
            var lastHeading: HeadingToken?
            for heading in textStorage.headingTokens {
                if let lastHeading = lastHeading, heading.identifier == token.identifier {
                    return ReplaceHeadingCommandComposer(fromLocation: heading.range.location, toLocation: lastHeading.range.location).compose(textStorage: textStorage)
                }
                
                lastHeading = heading
            }
        }
        
        let lineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).location
        if lineStart > 0 {
            let lastLineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: lineStart - 1, length: 0)).location
            return ReplaceLineCommandComposer(fromLocation: lineStart, toLocation: lastLineStart).compose(textStorage: textStorage)
        }
        
        return NoChangeCommand()
    }
}

// MARK: - MoveLineUpCommandComposer
public class MoveLineDownCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        for case let token in textStorage.token(at: self.location) ?? [] where token is HeadingToken {
            var currentHeading: HeadingToken?
            for heading in textStorage.headingTokens {
                if heading.identifier == token.identifier {
                    currentHeading = heading
                    continue
                }
                
                if let currentHeading = currentHeading {
                    return ReplaceHeadingCommandComposer(fromLocation: currentHeading.range.location, toLocation: heading.range.location).compose(textStorage: textStorage)
                }
            }
        }
        
        let lineEnd = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).upperBound
        if lineEnd < textStorage.string.count {
            let nextLineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: lineEnd + 1, length: 0)).location
            return ReplaceLineCommandComposer(fromLocation: lineEnd, toLocation: nextLineStart).compose(textStorage: textStorage)
        }
        
        return NoChangeCommand()
    }
}

// MARK: - ReplaceHeadingCommand
public class ReplaceHeadingCommandComposer: DocumentContentCommandComposer {
    let fromLocation: Int
    let toLocation: Int
    public init(fromLocation: Int, toLocation: Int) {
        self.fromLocation = fromLocation
        self.toLocation = toLocation
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let fromHeading = textStorage.heading(contains: self.fromLocation) else { return NoChangeCommand() }
        guard let toHeading = textStorage.heading(contains: self.fromLocation) else { return NoChangeCommand() }
        
        let stringToReplace = textStorage.string.substring(toHeading.paragraphRange).appending(textStorage.string.substring(fromHeading.paragraphRange))
        
        return ReplaceTextCommand(range: fromHeading.range.union(toHeading.range), textToReplace: stringToReplace, textStorage: textStorage)
    }
}

public class ReplaceLineCommandComposer: DocumentContentCommandComposer {
    let fromLocation: Int
    let toLocation: Int
    
    public init(fromLocation: Int, toLocation: Int) {
        self.fromLocation = fromLocation
        self.toLocation = toLocation
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let lineFrom = (textStorage.string as NSString).lineRange(for: NSRange(location: self.fromLocation, length: 0))
        let lineTo = (textStorage.string as NSString).lineRange(for: NSRange(location: self.toLocation, length: 0))
        
        let stringToReplace = textStorage.string.substring(lineTo).appending(textStorage.string.substring(lineFrom))
        
        return ReplaceTextCommand(range: lineFrom.union(lineTo), textToReplace: stringToReplace, textStorage: textStorage)
    }
}

// MARK: - InsertTextToHeadingCommand
public class InsertTextToHeadingCommandComposer: DocumentContentCommandComposer {
    let location: Int
    let textToInsert: String
    public init(location: Int, textToInsert: String) {
        self.location = location
        self.textToInsert = textToInsert
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
        let location = heading.paragraphRange.upperBound - 1
        
        return InsertTextCommandComposer(location: location, textToInsert: self.textToInsert).compose(textStorage: textStorage)
    }
}

// MARK: - InsertTextCommand
public class InsertTextCommandComposer: DocumentContentCommandComposer {
    let location: Int, textToInsert: String
    
    public init(location: Int, textToInsert: String) {
        self.location = location
        self.textToInsert = textToInsert
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return ReplaceTextCommand(range: NSRange(location: self.location, length: 0), textToReplace: self.textToInsert, textStorage: textStorage)
    }
}


// MARK: - AddAttachmentCommand
public class AddAttachmentCommandComposer: DocumentContentCommandComposer {
    let attachmentId: String
    let location: Int
    let kind: String
    
    public init(attachmentId: String, location: Int, kind: String) {
        self.attachmentId = attachmentId
        self.location = location
        self.kind = kind
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let content = OutlineParser.Values.Attachment.serialize(kind: kind, value: self.attachmentId)
        
        return InsertTextCommandComposer(location: self.location, textToInsert: content).compose(textStorage: textStorage)
    }
}

// MARK: - CheckboxCommand
public class CheckboxStatusCommandComposer: DocumentContentCommandComposer {
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let status = checkboxString
        
        var nextStatus: String = status
        switch status {
        case OutlineParser.Values.Checkbox.checked: fallthrough
        case OutlineParser.Values.Checkbox.halfChecked:
            nextStatus = OutlineParser.Values.Checkbox.unchecked
        default:
            nextStatus = OutlineParser.Values.Checkbox.checked
        }
        
        for case let token in textStorage.token(at: self.location) ?? [] where token.name == OutlineParser.Key.Node.checkbox {
            return ReplaceTextCommand(range: token.range, textToReplace: nextStatus, textStorage: textStorage)
        }
        
        return NoChangeCommand()
    }
    
    public let location: Int
    public let checkboxString: String
    
    public init(location: Int, checkboxString: String) {
        self.location = location
        self.checkboxString = checkboxString
    }
}

// MARK: - UpdateDateAndTimeCommand
public class UpdateDateAndTimeCommandComposer: DocumentContentCommandComposer {
    let range: NSRange
    let newDateAndTime: DateAndTimeType
    
    public init(range: NSRange, dateAndTime: DateAndTimeType) {
        self.range = range
        self.newDateAndTime = dateAndTime
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return ReplaceTextCommand(range: self.range, textToReplace: self.newDateAndTime.markString, textStorage: textStorage)
    }
}

// MARK: - TagCommand
public class TagCommandComposer: DocumentContentCommandComposer {
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
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
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
                        return ReplaceTextCommand(range: tagsRange, textToReplace: newTags, textStorage: textStorage)
                    }
                }
            }
            
            return NoChangeCommand()
        case .add(let tag):
            if let tagsRange = heading.tags {
                return InsertTextCommandComposer(location: tagsRange.upperBound, textToInsert: "\(tag):").compose(textStorage: textStorage)
            } else {
                return InsertTextCommandComposer(location: heading.tagLocation, textToInsert: " :\(tag):").compose(textStorage: textStorage)
            }
        }
        
    }
}

// MARK: - PlanningCommand
public class PlanningCommandComposer: DocumentContentCommandComposer {
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
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
        switch self.kind {
        case .remove:
            if let planningRange = heading.planning {
                return ReplaceTextCommand(range: planningRange, textToReplace: "", textStorage: textStorage)
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
            
            return ReplaceTextCommand(range: editRange, textToReplace: replacement, textStorage: textStorage)
        }
        
        return NoChangeCommand()
    }
}

// MARK: - ArchiveCommand
public class ArchiveCommandComposer: TagCommandComposer {
    public init(location: Int) {
        super.init(location: location, kind: .add(OutlineParser.Values.Heading.Tag.archive))
    }
}

// MARK: - UnarchiveCommand
public class UnarchiveCommandComposer: TagCommandComposer {
    public init(location: Int) {
        super.init(location: location, kind: .remove(OutlineParser.Values.Heading.Tag.archive))
    }
}

// MARK: - TextMarkCommandComposer
public class TextMarkCommandComposer: DocumentContentCommandComposer {
    public let markType: OutlineParser.MarkType
    public let range: NSRange
    
    public init(markType: OutlineParser.MarkType, range: NSRange) {
        self.markType = markType
        self.range = range
    }

    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let temp = textStorage.string.substring(self.range)
        let replacement = self.markType.mark + temp + self.markType.mark

        return ReplaceTextCommand(range: self.range, textToReplace: replacement, textStorage: textStorage)
    }
}

// MARK: - AddSeparatorCommand
public class AddSeparatorCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return InsertTextCommandComposer(location: self.location, textToInsert: OutlineParser.Values.separator).compose(textStorage: textStorage)
    }
}


public class IncreaseIndentCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        var start = 0
        var end = 0
        var content = 0
        (textStorage.string as NSString).getLineStart(&start,
                                                      end: &end,
                                                      contentsEnd: &content,
                                                      for: NSRange(location: self.location, length: 0))

        return InsertTextCommandComposer(location: start, textToInsert: OutlineParser.Values.Character.tab).compose(textStorage: textStorage)
    }
}

public class DecreaseIndentCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
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
                return ReplaceTextCommand(range: range, textToReplace: "", textStorage: textStorage)
            } else {
                return NoChangeCommand()
            }
        } else {
            return NoChangeCommand()
        }
    }
}


// MARK: - QuoteBlockCommand
public class QuoteBlockCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        // TODO:
        return NoChangeCommand()
    }
}

// MARK: -
public class CodeBlockCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        // TODO:
        return NoChangeCommand()
    }
}

// MARK: - UnorderdListSwitchCommand
/// 切换当前行是否 unorderd list
public class UnorderdListSwitchCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let lineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).location
        
        for case let token in (textStorage.token(at: lineStart) ?? []) where token.name == OutlineParser.Key.Node.unordedList {
            if let prefixRange = token.data[OutlineParser.Key.Element.UnorderedList.prefix] {
                return ReplaceTextCommand(range: prefixRange, textToReplace: "", textStorage: textStorage)
            } else {
                return NoChangeCommand()
            }
        }
        
        return InsertTextCommandComposer(location: lineStart, textToInsert: OutlineParser.Values.List.unorderedList).compose(textStorage: textStorage)
    }
}

// MARK: - OrderedListSwitchCommand
/// 切换当前行是否 orderd list
public class OrderedListSwitchCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let lineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).location
        
        for case let token in (textStorage.token(at: lineStart) ?? []) where token.name == OutlineParser.Key.Node.ordedList {
            if let prefixRange = token.data[OutlineParser.Key.Element.OrderedList.prefix] {
                return ReplaceTextCommand(range: prefixRange, textToReplace: "", textStorage: textStorage)
            } else {
                return NoChangeCommand()
            }
        }
        
        if lineStart > 0 {
            // 1. find last line index
            let lastLineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: lineStart - 1, length: 0)).location
            for case let token in (textStorage.token(at: lastLineStart) ?? []) where token.name == OutlineParser.Key.Node.ordedList {
                // 2. insert index
                let lastPrefix = textStorage.string.substring(token.data[OutlineParser.Key.Element.OrderedList.prefix]!)
                return InsertTextCommandComposer(location: lineStart,
                                         textToInsert: OutlineParser.Values.List.orderListIncrease(prefix: lastPrefix))
                    .compose(textStorage: textStorage)
            }
            
            // 2.2 use default index
            return InsertTextCommandComposer(location: lineStart, textToInsert: OutlineParser.Values.List.orderdList(index: "1"))
                .compose(textStorage: textStorage)
        } else {
            return InsertTextCommandComposer(location: lineStart, textToInsert: OutlineParser.Values.List.orderdList(index: "1"))
                .compose(textStorage: textStorage)
        }
    }
}

// MARK: - CheckboxSwitchCommand
/// 切换当前行是否 checkbox
public class CheckboxSwitchCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let lineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).location
        
        for case let token in (textStorage.token(at: lineStart) ?? []) where token.name == OutlineParser.Key.Node.checkbox {
            return ReplaceTextCommand(range: token.range, textToReplace: "", textStorage: textStorage)
        }
        
        return InsertTextCommandComposer(location: lineStart, textToInsert: OutlineParser.Values.Checkbox.unchecked).compose(textStorage: textStorage)
    }
}
