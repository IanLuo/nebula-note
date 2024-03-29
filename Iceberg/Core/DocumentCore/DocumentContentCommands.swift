//
//  DocumentCommands.swift
//  Business
//
//  Created by ian luo on 2019/3/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface

public struct DocumentContentCommandResult {
    public let isModifiedContent: Bool
    public var range: NSRange?
    public let content: String?
    public let delta: Int
    
    public static var noChange: DocumentContentCommandResult {
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
    public var resultMap: ((DocumentContentCommandResult) -> DocumentContentCommandResult)?
    public var completionAction: (() -> Void)?
    public var manullayReplace: ((NSRange, String) -> Void)?
    
    public init(range: NSRange, textToReplace: String, textStorage: OutlineTextStorage, manullayReplace: ((NSRange, String) -> Void)? = nil) {
        self.textStorage = textStorage
        self.range = range
        self.textToReplace = textToReplace
        self.manullayReplace = manullayReplace
    }
    
    public func perform() -> DocumentContentCommandResult {
        let undoRange = NSRange(location: self.range.location, length: self.textToReplace.count)
        let undoString = self.textStorage.string.nsstring.substring(with: self.range)
        
        if let manullayReplace = self.manullayReplace {
            manullayReplace(self.range, self.textToReplace)
        } else {
            self.textStorage.replaceCharacters(in: self.range, with: self.textToReplace)
        }
        
        let result = DocumentContentCommandResult(isModifiedContent: true, range: undoRange, content: undoString, delta: self.textToReplace.count - self.range.length)
        
        completionAction?()
        
        if let resultMap = self.resultMap {
            return resultMap(result)
        } else {
            return result
        }
    }
}

public class SetHeadingPropertyComposer: DocumentContentCommandComposer {
    public init(location: Int, property: [String: String]) {
        self.location = location
        self.property = property
    }
    
    public let location: Int
    public let property: [String: String]
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
        let propertyLocation = heading.range.moveRightBound(by: 1).upperBound
        
        
        if var content = textStorage.propertyContentForHeading(at: self.location) {
            for (key, value) in self.property {
                content[key] = value
            }
            
            return UpdateDrawerComposer(location: propertyLocation, name: OutlineParser.Values.Block.Drawer.nameProperty, content: content.map { ":\($0.key): \($0.value)" }.joined(separator: "\n")).compose(textStorage: textStorage)
        } else {
            var content = defaultHeadingProperty
            for (key, value) in self.property {
                content[key] = value
            }
            return AddDrawerComposer(location: propertyLocation, name: OutlineParser.Values.Block.Drawer.nameProperty, content: content.map { ":\($0.key): \($0.value)" }.joined(separator: "\n")).compose(textStorage: textStorage)
        }
    }
    
    private var defaultHeadingProperty: [String: String] {
        return [:]
    }
}

public class AddDrawerComposer: DocumentContentCommandComposer {
    public init(location: Int, name: String, content: String = "") {
        self.location = location
        self.name = name
        self.content = content
    }
    
    public let location: Int
    public let name: String
    public let content: String
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let content = ":\(self.name):\n\(self.content)\n:END:\n"
        return ReplaceTextCommand(range: NSRange(location: self.location, length: 0), textToReplace: content, textStorage: textStorage)
    }
}

public class UpdateDrawerComposer: DocumentContentCommandComposer {
    public init(location: Int, name: String, content: String = "") {
        self.location = location
        self.name = name
        self.content = content
    }
    
    public let location: Int
    public let name: String
    public let content: String
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        for case let token in textStorage.token(at: self.location) where token is BlockToken {
            if (token as? BlockToken)?.blockType == .drawer {
                let content = ":\(self.name):\n\(self.content)\n:END:"
                return ReplaceTextCommand(range: token.range, textToReplace: content, textStorage: textStorage)
            }
        }
        
        return AddDrawerComposer(location: self.location, name: self.name, content: self.content).compose(textStorage: textStorage)
    }
}

public class DeleteSectionCommpandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) { self.location = location }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        if let heading = textStorage.heading(contains: self.location) {
            return ReplaceContentCommandComposer(range: heading.paragraphWithSubRange, textToReplace: "").compose(textStorage: textStorage)
        } else {
            return NoChangeCommandComposer().compose(textStorage: textStorage)
        }
    }
}

public class AddDocumentLinkCommpandComposer: DocumentContentCommandComposer {
    let range: NSRange
    let documentInfo: DocumentInfo
    let outlineLocation: OutlineLocation
    let url: URL
    
    public init(range: NSRange, url: URL, documentInfo: DocumentInfo, outlineLocation: OutlineLocation) {
        self.range = range
        self.url = url
        self.documentInfo = documentInfo
        self.outlineLocation = outlineLocation
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return ReplaceContentCommandComposer(range: self.range, textToReplace: OutlineParser.Values.Link.serializeFileLink(url: self.url, documentInfo: self.documentInfo, outlineLocation: self.outlineLocation)).compose(textStorage: textStorage)
    }
}

// MARK: - AddNewLineBelowCommandComposer
public class AddNewLineBelowCommandComposer: DocumentContentCommandComposer {
    let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let lineEnd = (textStorage.string as NSString).lineRange(for: NSRange(location: self.location, length: 0)).upperBound
        
        return ReplaceContentCommandComposer(range: NSRange(location: lineEnd, length: 0),
                                             textToReplace: OutlineParser.Values.Character.linebreak)
            .compose(textStorage: textStorage)
    }
}

public class AddNewHeadingAfterCurrentHeadingWithSameLevelCommandComposer: DocumentContentCommandComposer {
    let location: Int
    
    public init(location: Int) { self.location = location }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let level = textStorage.heading(contains: self.location)?.level ?? 1
        
        return AddNewHeadingAfterCurrentHeadingCommandComposer(location: self.location, level: level).compose(textStorage: textStorage)
    }
}

public class AddNewSubHeadingAfterCurrentHeading: DocumentContentCommandComposer {
    let location: Int
    
    public init(location: Int) { self.location = location }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let level = (textStorage.heading(contains: self.location)?.level ?? 0) + 1
        
        return AddNewHeadingAfterCurrentHeadingCommandComposer(location: self.location, level: level).compose(textStorage: textStorage)
    }
}

public class AddNewHeadingAtBottomCommandComposer: DocumentContentCommandComposer {
    public init() {}
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let level = 1
        let insertLocation = textStorage.string.count
        
        var textToReplace = "*" * level + " " + OutlineParser.Values.Character.linebreak
        
        if textStorage.string.last != "\n" {
           textToReplace = "\n" + textToReplace
        }
        
        return ReplaceContentCommandComposer(range: NSRange(location: insertLocation, length: 0),
                                             textToReplace: textToReplace)
            .compose(textStorage: textStorage)
    }
}

public class addNewSameLevelHeadingAboveCurrentHeadingCommandComposer: DocumentContentCommandComposer {
    let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let level = textStorage.heading(contains: self.location)?.level ?? 1
        let insertLocation = max(0, (textStorage.heading(contains: self.location)?.range.location ?? self.location))
        
        let textToReplace = "*" * level + " " + OutlineParser.Values.Character.linebreak
        
        return ReplaceContentCommandComposer(range: NSRange(location: insertLocation, length: 0),
                                             textToReplace: textToReplace)
            .compose(textStorage: textStorage)
    }
}

public class AddNewHeadingAfterCurrentHeadingCommandComposer: DocumentContentCommandComposer {
    let location: Int
    let level: Int
    
    public init(location: Int, level: Int) {
        self.location = location
        self.level = level
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let sectionEnd = textStorage.heading(contains: self.location)?.paragraphWithSubRange.lastCharacterLocation ?? self.location
        let insertLocation = sectionEnd + 1
        
        var textToReplace = "*" * self.level + " " + OutlineParser.Values.Character.linebreak
        
        if textStorage.substring(NSRange(location: sectionEnd, length: 1)) != OutlineParser.Values.Character.linebreak || textStorage.isFolded(location: sectionEnd) {
            textToReplace = OutlineParser.Values.Character.linebreak + textToReplace
        }
        
        return ReplaceContentCommandComposer(range: NSRange(location: insertLocation, length: 0),
                                             textToReplace: textToReplace)
            .compose(textStorage: textStorage)
    }
}

// MARK: - RemoveParagraphCommandComposer
public class RemoveParagraphCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
        return ReplaceTextCommand(range: heading.paragraphWithSubRange, textToReplace: "", textStorage: textStorage)
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
        guard textStorage.isFolded(location: heading.range.location) == true && heading.contentWithSubHeadingsRange.length > 0 else { return }
        
        textStorage.setAttributeForHeading(heading, isFolded: false)
        
        for subHeading in textStorage.firstLevelSubheadings(of: heading) {
            // rerender all sub heading headers
            subHeading.needsRender = true
            
            // and also make the line break work
            let lastCharactorRange = subHeading.paragraphWithSubRange.tail(1)
            if textStorage.substring(lastCharactorRange) == "\n" {
                textStorage.setAttributes(nil, range: lastCharactorRange)
            }
        }
        
        textStorage.flushTokens()
        textStorage.setParagraphIndent(heading: heading, for: heading.paragraphWithSubRange)
    }
    
    fileprivate func _markFold(heading: HeadingToken, textStorage: OutlineTextStorage) {
        guard textStorage.isFolded(location: heading.range.location) == false && heading.contentWithSubHeadingsRange.length > 0 else { return }
        textStorage.setAttributeForHeading(heading, isFolded: true)
    }
    
    fileprivate func _unFoldHeadingAndChildren(heading: HeadingToken, textStorage: OutlineTextStorage) {
        self._markUnfold(heading: heading, textStorage: textStorage)
        for child in textStorage.subheadings(of: heading) {
            textStorage.setParagraphIndent(heading: child)
        }
    }
    
    fileprivate func _isFolded(heading: HeadingToken, textStorage: OutlineTextStorage) -> Bool {
        return textStorage.isHeadingFolded(heading: heading)
    }
    
    public func perform() -> DocumentContentCommandResult {
        if let heading = textStorage.heading(contains: location) {
            
//            guard heading.contentRange != nil else { return DocumentContentCommandResult.noChange }
            
            var toggleFoldAndUnfoldAction: ((OutlineTextStorage, HeadingToken, FoldingAndUnfoldingCommand) -> Void)!
            toggleFoldAndUnfoldAction = { textStorage, heading, command in
                if command._isFolded(heading: heading, textStorage: textStorage) {
                    command._markUnfold(heading: heading, textStorage: textStorage)
                } else {
                    command._markFold(heading: heading, textStorage: textStorage)
                }
            }
            
            textStorage.beginEditing()
            toggleFoldAndUnfoldAction(textStorage, heading, self)
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
            super._markFold(heading: heading, textStorage: textStorage)
        }
        
        return DocumentContentCommandResult.noChange
    }
}

// MARK: - UnfoldToLocationCommand
// 还有 bug FIXME: 折叠部分包含了大片空白
public class UnfoldToLocationCommand: FoldingAndUnfoldingCommand {
    public override func perform() -> DocumentContentCommandResult {
        textStorage.beginEditing()
        
        for heading in self.textStorage.headingTokens {
            if heading.contentWithFirstLevelSubHeadingsRange.contains(self.location) || heading.range.location == self.location {
                super._markUnfold(heading: heading, textStorage: self.textStorage)
            }
        }
        
        textStorage.endEditing()
        
        return DocumentContentCommandResult.noChange
    }
}

// MARK: - FoldToLocationCommand
// 还有 bug FIXME: 折叠部分包含了大片空白
public class FoldToLocationCommand: FoldingAndUnfoldingCommand {
    public override func perform() -> DocumentContentCommandResult {
        self.textStorage.beginEditing()
        
        if let heading = self.textStorage.heading(contains: self.location) {
            super._markFold(heading: heading, textStorage: self.textStorage)
        }
        
        self.textStorage.endEditing()
        
        return DocumentContentCommandResult.noChange
    }
}

// MARK: - HeadingConvertCommandComposer
public class ConvertLineToHeadingCommandComposer: DocumentContentCommandComposer {
    let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let lineStart = textStorage.lineStart(at: self.location)
        
        if let heading = textStorage.heading(contains: self.location) {
            // 如果当前行已经是 heading，则忽略
            guard heading.range.location != lineStart else { return NoChangeCommand() }
            
            if lineStart > 0 {
                if let lastHeading = textStorage.heading(contains: lineStart - 1) {
                    let lastHeadingLevelString = textStorage.string.nsstring.substring(with: lastHeading.levelRange)
                    return ReplaceTextCommand(range: NSRange(location: lineStart, length: 0), textToReplace: "\(lastHeadingLevelString) ", textStorage: textStorage)
                } else {
                    return ReplaceTextCommand(range: NSRange(location: lineStart, length: 0), textToReplace: "* ", textStorage: textStorage)
                }
            } else {
                return ReplaceTextCommand(range: NSRange(location: lineStart, length: 0), textToReplace: "* ", textStorage: textStorage)
            }
            
        } else {
            return ReplaceTextCommand(range: NSRange(location: lineStart, length: 0), textToReplace: "* ", textStorage: textStorage)
        }
    }
}

// MARK: - ConvertHeadingLineToParagragh
public class ConvertHeadingLineToParagragh: DocumentContentCommandComposer {
    let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        
        guard let heading = textStorage.heading(contains: self.location) else {
            return NoChangeCommand()
        }
        
        return ReplaceTextCommand(range: heading.prefix.moveRightBound(by: 1), textToReplace: "", textStorage: textStorage)
    }
}

// MARK: - HeadingLevelChangeCommandComposer
public class HeadingLevelChangeCommandComposer: DocumentContentCommandComposer {
    let newLevel: Int
    let location: Int
    public init(location: Int, newLevel: Int) {
        self.location = location
        self.newLevel = newLevel
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: location) else { return NoChangeCommand() }
        
        let levelString = (0..<self.newLevel).reduce("", { last, _ in last.appending("*") })
        
        return ReplaceTextCommand(range: heading.levelRange, textToReplace: levelString, textStorage: textStorage)
    }
}

// MARK: - ReplaceContentComposer
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

// MARK: - FoldAndUnfoldCommandComposer
public class FoldAndUnfoldCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) { self.location = location }
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return FoldingAndUnfoldingCommand(location: self.location, textStorage: textStorage)
    }
}

// MARK: - FoldAllCommandComposer
public class FoldAllCommandComposer: DocumentContentCommandComposer {
    public init(){}
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return FoldAllCommand(textStorage: textStorage)
    }
}

// MARK: - UnfoldToLocationCommandComposer
public class UnfoldToLocationCommandCompose: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) { self.location = location }
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return UnfoldToLocationCommand(location: self.location, textStorage: textStorage)
    }
}

// MARK: - UnfoldToLocationCommandComposer
public class FoldToLocationCommandCompose: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) { self.location = location }
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        return FoldToLocationCommand(location: self.location, textStorage: textStorage)
    }
}

// MARK: - UpdateLinkCommandCompser
public class UpdateLinkCommandCompser: DocumentContentCommandComposer {
    let location: Int
    let link: String
    
    public init(location: Int, link: String) {
        self.location = location
        self.link = link
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        for case let token in textStorage.token(at: self.location) where token is LinkToken {
            return ReplaceContentCommandComposer(range: token.range, textToReplace: self.link).compose(textStorage: textStorage)
        }
        
        return NoChangeCommand()
    }
}

// MARK: - MoveLineUpCommandComposer
public class MoveLineUpCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        for case let token in textStorage.token(at: self.location) where token is HeadingToken {
            return MoveHeadingUpCommandComposer(location: self.location).compose(textStorage: textStorage)
        }
        
        let lineRange = textStorage.lineRange(at: self.location)
        if lineRange.location > 0 {
            let lastLine = textStorage.lineRange(at: lineRange.location - 1)
            
            // 上一行不能是 heading
            guard case let token = textStorage.token(at: lastLine.location).last, !(token is HeadingToken) else { return NoChangeCommand() }
            
            // 如果当前行是文档的最后一行，当前行结尾没有换行符，因此需要在替换的时候，在当前行末尾加上换行符，并且在上一行去掉换行符
            if lineRange.upperBound == textStorage.string.nsstring.length /* last line of document */ {
                let currentLineText = textStorage.substring(lineRange) + OutlineParser.Values.Character.linebreak
                let lastLineText = textStorage.substring(lastLine.moveRightBound(by: -1))
                let textToReplace = currentLineText.appending(lastLineText)
                let command = ReplaceContentCommandComposer(range: lastLine.union(lineRange),
                                                     textToReplace: textToReplace)
                    .compose(textStorage: textStorage)
                
                (command as? ReplaceTextCommand)?.resultMap = { _ in
                    return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: -lastLineText.count)
                }
                
                return command
            } else {
                let textToReplace = textStorage.substring(lineRange).appending(textStorage.substring(lastLine))
                let command = ReplaceContentCommandComposer(range: lastLine.union(lineRange),
                                                     textToReplace: textToReplace)
                    .compose(textStorage: textStorage)
                
                (command as? ReplaceTextCommand)?.resultMap = { _ in
                    return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: -lastLine.length)
                }
                
                return command
            }
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
        for case let token in textStorage.token(at: self.location) where token is HeadingToken {
            return MoveHeadingDownCommandComposer(location: self.location).compose(textStorage: textStorage)
        }
        
        let lineRange = textStorage.lineRange(at: self.location)
        if lineRange.upperBound < textStorage.string.nsstring.length {
            let nextLine = textStorage.lineRange(at: lineRange.upperBound + 1)
            
            // 下一行不能是 heading
            guard case let token = textStorage.token(at: nextLine.location).last, !(token is HeadingToken) else { return NoChangeCommand() }
            
            // 如果下一行是文档的最后一行，下一行结尾没有换行符，因此需要在替换的时候，在当前行末尾去掉换行符，并且在下一行加上换行符
            if nextLine.upperBound == textStorage.string.nsstring.length /* last line of document */ {
                let currentLineText = textStorage.substring(lineRange.moveRightBound(by: -1))
                let nextLineText = textStorage.substring(nextLine) + OutlineParser.Values.Character.linebreak
                let textToReplace = nextLineText.appending(currentLineText)
                let command = ReplaceContentCommandComposer(range: lineRange.union(nextLine), textToReplace: textToReplace)
                    .compose(textStorage: textStorage)
                (command as? ReplaceTextCommand)?.resultMap = { _ in
                    return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: nextLineText.count)
                }
                return command
            } else {
                let textToReplace = textStorage.substring(nextLine).appending(textStorage.substring(lineRange))
                let command = ReplaceContentCommandComposer(range: lineRange.union(nextLine), textToReplace: textToReplace).compose(textStorage: textStorage)
                (command as? ReplaceTextCommand)?.resultMap = { _ in
                    return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: nextLine.length)
                }
                return command
            }
        }
        
        return NoChangeCommand()
    }
}

// MARK: - MoveHeadingUpCommandComposer
public class MoveHeadingUpCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
        var findSameLevelHeadingUpwards: ((Int, OutlineTextStorage) -> HeadingToken?)!
        findSameLevelHeadingUpwards = { location, textStorage in
            guard location > 0 else { return nil }
            
            if let lastHeading = textStorage.heading(contains: location) {
                if lastHeading.level == heading.level { // 上一级标题同级，则返回
                    return lastHeading
                } else if lastHeading.level < heading.level {
                    return nil // 上一级标题是更大的标题，则忽略
                } else { // 上一级是更小的标题，则继续查找
                    return findSameLevelHeadingUpwards(lastHeading.range.location - 1, textStorage)
                }
            } else {
                return nil
            }
        }
        
        // 查找上一个同级的标题，如果没有找到同级的，则忽略
        guard let lastHeading = findSameLevelHeadingUpwards(heading.range.location - 1, textStorage) else { return NoChangeCommand() }
        
        // 如果当前 heading 是文档最后一个，则在移动之后要在尾部加上换行符，同理，在被移到末尾的 heading 尾部去掉换行符
        if heading.paragraphWithSubRange.upperBound == textStorage.string.nsstring.length {
            let currentHeadingText = textStorage.substring(heading.paragraphWithSubRange) + OutlineParser.Values.Character.linebreak
            let lastParagraphText = textStorage.substring(lastHeading.paragraphWithSubRange.moveRightBound(by: -1))
            let textToReplace = currentHeadingText.appending(lastParagraphText)
            let command = ReplaceContentCommandComposer(range: lastHeading.paragraphWithSubRange.union(heading.paragraphWithSubRange),
                                                 textToReplace: textToReplace)
                .compose(textStorage: textStorage)
            
            let delta = -lastHeading.paragraphWithSubRange.length
            (command as? ReplaceTextCommand)?.resultMap = { _ in
                return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: delta)
            }
            
            return command
        } else {
            let textToReplace = textStorage.substring(heading.paragraphWithSubRange).appending(textStorage.substring(lastHeading.paragraphWithSubRange))
            let command = ReplaceContentCommandComposer(range: lastHeading.paragraphWithSubRange.union(heading.paragraphWithSubRange),
                                                 textToReplace: textToReplace)
                .compose(textStorage: textStorage)
            
            let delta = -lastHeading.paragraphWithSubRange.length
            (command as? ReplaceTextCommand)?.resultMap = { _ in
                return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: delta)
            }
            return command
        }
    }
}

public class MoveHeadingDownCommandComposer: DocumentContentCommandComposer {
    let location: Int
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
        guard let nextHeading = textStorage.heading(contains: heading.paragraphWithSubRange.upperBound + 1) else { return NoChangeCommand() }
        
        guard nextHeading.level == heading.level else { return NoChangeCommand() } // 如果下一级是更大的标题，则忽略，这里不会有更小的标题，因为更小的标题是当前的子标题
        
        // 如果下一 heading 是文档的最后一个 heading，下一 heading 结尾没有换行符，因此需要在替换的时候，在当前 heading 末尾去掉换行符，并且在下一 heading 加上换行符
        if nextHeading.paragraphWithSubRange.upperBound == textStorage.string.nsstring.length {
            let currentHeadingText = textStorage.substring(heading.paragraphWithSubRange.moveRightBound(by: -1))
            let nextParagraphText = textStorage.substring(nextHeading.paragraphWithSubRange) + OutlineParser.Values.Character.linebreak
            let textToReplace = nextParagraphText.appending(currentHeadingText)
            let command = ReplaceContentCommandComposer(range: heading.paragraphWithSubRange.union(nextHeading.paragraphWithSubRange), textToReplace: textToReplace).compose(textStorage: textStorage)
            
            let delta = nextParagraphText.nsstring.length
            (command as? ReplaceTextCommand)?.resultMap = { _ in
                return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: delta)
            }
            return command
        } else {
            let textToReplace = textStorage.substring(nextHeading.paragraphWithSubRange).appending(textStorage.substring(heading.paragraphWithSubRange))
            let command = ReplaceContentCommandComposer(range: heading.paragraphWithSubRange.union(nextHeading.paragraphWithSubRange), textToReplace: textToReplace).compose(textStorage: textStorage)
            
            let delta = nextHeading.paragraphWithSubRange.length
            (command as? ReplaceTextCommand)?.resultMap = { _ in
                return DocumentContentCommandResult(isModifiedContent: true, range: nil, content: nil, delta: delta)
            }
            return command
        }
    }
}

// MARK: - InsertTextToHeadingCommand
public class AppendTextToParagraphCommandComposer: DocumentContentCommandComposer {
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
    let range: NSRange
    let kind: String
    
    public init(attachmentId: String, range: NSRange, kind: String) {
        self.attachmentId = attachmentId
        self.range = range
        self.kind = kind
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        
        var content = OutlineParser.Values.Attachment.serialize(kind: kind, value: self.attachmentId)
        
        // 文字和链接附件不添加前后的空行
        if ![Attachment.Kind.link.rawValue, Attachment.Kind.text.rawValue].contains(kind) {
            content = OutlineParser.Values.Character.linebreak + OutlineParser.Values.Attachment.serialize(kind: kind, value: self.attachmentId) + OutlineParser.Values.Character.linebreak // 在添加附件前后添加空行，方便选择
        }
        
        return ReplaceContentCommandComposer(range: self.range, textToReplace: content).compose(textStorage: textStorage)
    }
}

// MARK: - CheckboxStatusCommandComposer
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
        
        for case let token in textStorage.token(at: self.location) where token is CheckboxToken {
            return ReplaceTextCommand(range: (token as! CheckboxToken).status, textToReplace: nextStatus, textStorage: textStorage)
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
    let location: Int
    let newDateAndTime: DateAndTimeType?
    
    public init(location: Int, dateAndTime: DateAndTimeType?) {
        self.location = location
        self.newDateAndTime = dateAndTime
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
            for case let token in textStorage.token(at: self.location) where token.name == OutlineParser.Key.Element.dateAndTIme {
                // 如果参数中有新的日期
                if let newDateAndTime = self.newDateAndTime {
                    // 替换
                    return ReplaceTextCommand(range: token.range, textToReplace: newDateAndTime.markString, textStorage: textStorage)
                } else {
                    // 否则删除
                    return ReplaceTextCommand(range: token.range, textToReplace: "", textStorage: textStorage)
                }
            }
        
        // 没有找到原来的 data and time
        if let newDateAndTime = self.newDateAndTime {
            // 创建新的
            let stringToInsert = newDateAndTime.markString + " " // 在日期后面添加一个空格，避免在文档尾部时，无法移动光标
            return ReplaceTextCommand(range: NSRange(location: self.location, length: 0), textToReplace: stringToInsert, textStorage: textStorage)
        } else {
            // 忽略
            return NoChangeCommand()
        }
    }
}

// MARK: - TagCommandComposer
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
                var newTags = textStorage.string.nsstring.substring(with: tagsRange)
                for t in textStorage.string.nsstring.substring(with: tagsRange).components(separatedBy: ":").filter({ $0.count > 0 }) {
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

// MARK: - PriorityCommandComposer
public class PriorityCommandComposer: DocumentContentCommandComposer {
    let location: Int
    let priority: String?
    
    public init(location: Int, priority: String?) {
        self.location = location
        self.priority = priority
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let heading = textStorage.heading(contains: self.location) else { return NoChangeCommand() }
        
        var priorityLocation: Int = heading.contentLocation
        
        if let planning = heading.planning {
            priorityLocation = planning.upperBound + 1
        }
        
        // 添加或者修改 priority
        if let newPriority = self.priority {
            if let priorityRange = heading.priority { // 修改现有的 priority
                return ReplaceContentCommandComposer(range: priorityRange, textToReplace: newPriority).compose(textStorage: textStorage)
            } else { // 添加 prority
                let priorityString = newPriority + " " // 新增 priortiy 的时候在后面增加一个空格
                return ReplaceContentCommandComposer(range: NSRange(location: priorityLocation, length: 0), textToReplace: priorityString).compose(textStorage: textStorage)
            }
        } else /* 删除 priority */ {
            guard var priorityRange = heading.priority else { return NoChangeCommand() }
            
            if textStorage.substring(priorityRange.moveRightBound(by: 1)).hasSuffix(" ") {
                priorityRange = priorityRange.moveRightBound(by: 1) // 如果右面有空格，删除的时候去掉右边的空格
            }
            
            return ReplaceContentCommandComposer(range: priorityRange, textToReplace: "").compose(textStorage: textStorage)
        }
    }
}

// MARK: - PlanningCommandComposer
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
                return ReplaceTextCommand(range: planningRange.moveRightBound(by: 1), textToReplace: "", textStorage: textStorage) // 删除 planning 的时候，去掉紧跟 planning 后面的空格
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
                editRange = NSRange(location: heading.contentLocation, length: 0)
                replacement = planning + " " // 添加一个空格
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
        let temp = textStorage.string.nsstring.substring(with: self.range)
        
        var replacement = self.markType.mark + temp + self.markType.mark
        
        if self.range.location > 0
            && !OutlineParser.RegexPattern.Element.TextMark.preCharacters.contains(textStorage.substring(self.range.moveLeftBound(by: -1).head(1))) {
            replacement = " " + replacement
        }
        
        if self.range.upperBound < textStorage.string.count
        && !OutlineParser.RegexPattern.Element.TextMark.postCharacters.contains(textStorage.substring(self.range.moveRightBound(by: 1).tail(1))) {
            replacement = replacement + " "
        }

        return ReplaceTextCommand(range: self.range, textToReplace: replacement, textStorage: textStorage)
    }
}

// MARK: - RemoveTextMarkCommandComposer
public class RemoveTextMarkCommandComposer: DocumentContentCommandComposer {
    public let markType: OutlineParser.MarkType
    public let range: NSRange
    
    public init(markType: OutlineParser.MarkType, range: NSRange) {
        self.markType = markType
        self.range = range
    }

    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        if textStorage.substring(self.range.head(1)) == self.markType.mark
            && textStorage.substring(self.range.tail(1)) == self.markType.mark {
            
            let replacement = textStorage.substring(self.range.moveLeftBound(by: 1).moveRightBound(by: -1))
            
            return ReplaceTextCommand(range: self.range, textToReplace: replacement, textStorage: textStorage)
        } else {
            return NoChangeCommand()
        }
        
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
        for case let heading in textStorage.token(at: self.location) where heading is HeadingToken {
            var newLevel = (heading as! HeadingToken).level + 1
            if newLevel >= SettingsAccessor.shared.maxLevel { newLevel = 1 }
           
            return HeadingLevelChangeCommandComposer(location: self.location, newLevel: newLevel).compose(textStorage: textStorage)
        }
        
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

public class MoveToParagraphAsChildHeadingCommandComposer: DocumentContentCommandComposer {
    public let isToLocationBehindFromLocation: Bool
    public let text: String
    public let toLocation: Int
    
    public init(text: String, to location: Int, isToLocationBehindFromLocation: Bool) {
        self.text = text
        self.toLocation = location
        self.isToLocationBehindFromLocation = isToLocationBehindFromLocation
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let location = self.isToLocationBehindFromLocation ? self.toLocation - self.text.nsstring.length : self.toLocation
        return AppendAsChildHeadingCommandComposer(text: self.text, to: location).compose(textStorage: textStorage)
    }
}

/// 将一段字符串添加到另一个 heading 下面，如果含有 heading 的话，插入的 heading 将会被修改该为目标 heading 的 child
public class AppendAsChildHeadingCommandComposer: DocumentContentCommandComposer {
    public let text: String
    public let toLocation: Int

    public init(text: String, to location: Int) {
        self.text = text
        self.toLocation = location
    }

    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        guard let toHeading = textStorage.heading(contains: self.toLocation) else { return NoChangeCommand() }

        // 解析文件中的全部 heading
        let parseDelegate = SimpleParserDelegate()
        let parser = OutlineParser()
        parser.delegate = parseDelegate
        parser.includeParsee = [.heading]

        parser.parse(str: self.text)

        var textToInsert = self.text
        let firstHeadingLevel = parseDelegate.headings.first?.level ?? 0
        for heading in parseDelegate.headings.reversed() {
            let headingDiff = heading.level - firstHeadingLevel
            textToInsert = textToInsert.nsstring.replacingCharacters(in: heading.levelRange, with: "*" * (headingDiff + toHeading.level + 1))
        }
        
        // if the heading it at the end of document, add line break to it
        if !textToInsert.hasSuffix("\n") {
            textToInsert.append("\n")
        }

        // 2. 插入到新的位置
        let newLocation = NSRange(location: toHeading.paragraphRange.upperBound, length: 0)
        
        if newLocation.upperBound == textStorage.string.nsstring.length { // 如果将要插到文档末尾，添加一个换行符在插入的位置之前
            textToInsert = "\n" + textToInsert
        }

        return ReplaceTextCommand(range: newLocation, textToReplace: textToInsert, textStorage: textStorage)
    }
}

public class DecreaseIndentCommandComposer: DocumentContentCommandComposer {
    public let location: Int
    
    public init(location: Int) {
        self.location = location
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        for case let heading in textStorage.token(at: self.location) where heading is HeadingToken {
            var newLevel = (heading as! HeadingToken).level - 1
            if newLevel <= 0 { newLevel = SettingsAccessor.shared.maxLevel }
            
            return HeadingLevelChangeCommandComposer(location: self.location, newLevel: newLevel).compose(textStorage: textStorage)
        }
        
        var start = 0
        var end = 0
        var content = 0
        (textStorage.string as NSString).getLineStart(&start,
                                                      end: &end,
                                                      contentsEnd: &content,
                                                      for: NSRange(location: self.location, length: 0))

        let line = textStorage.string.nsstring.substring(with: NSRange(location: start, length: end - start))
        
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


// MARK: - QuoteBlockCommandComposer
public class QuoteBlockCommandComposer: DocumentContentCommandComposer {
    public let range: NSRange
    
    public init(range: NSRange) {
        self.range = range
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let selectedText = textStorage.string.nsstring.substring(with: self.range)
        
        var stringToReplace = OutlineParser.Values.Character.linebreak
        stringToReplace.append(OutlineParser.Values.Block.Quote.begin)
        stringToReplace.append(OutlineParser.Values.Character.linebreak)
        stringToReplace.append(selectedText)
        stringToReplace.append(OutlineParser.Values.Character.linebreak)
        stringToReplace.append(OutlineParser.Values.Block.Quote.end)
        stringToReplace.append(OutlineParser.Values.Character.linebreak)
        
        return ReplaceTextCommand(range: self.range, textToReplace: stringToReplace, textStorage: textStorage)
    }
}

// MARK: -
public class CodeBlockCommandComposer: DocumentContentCommandComposer {
    public let range: NSRange
    
    public init(range: NSRange) {
        self.range = range
    }
    
    public func compose(textStorage: OutlineTextStorage) -> DocumentContentCommand {
        let selectedText = textStorage.string.nsstring.substring(with: self.range)
        
        var stringToReplace = OutlineParser.Values.Character.linebreak
        stringToReplace.append(OutlineParser.Values.Block.Sourcecode.begin)
        stringToReplace.append(OutlineParser.Values.Character.linebreak)
        stringToReplace.append(selectedText)
        stringToReplace.append(OutlineParser.Values.Character.linebreak)
        stringToReplace.append(OutlineParser.Values.Block.Sourcecode.end)
        stringToReplace.append(OutlineParser.Values.Character.linebreak)
        
        return ReplaceTextCommand(range: self.range, textToReplace: stringToReplace, textStorage: textStorage)
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
        
        for case let token in (textStorage.token(at: lineStart)) where token is OrderedListToken {
            return ReplaceTextCommand(range: (token as! OrderedListToken).prefix, textToReplace: OutlineParser.Values.List.unorderedList, textStorage: textStorage)
        }
        
        for case let token in (textStorage.token(at: lineStart)) where token is UnorderdListToken {
            return ReplaceTextCommand(range: (token as! UnorderdListToken).prefix, textToReplace: "", textStorage: textStorage)
        }
        
        for case let token in (textStorage.token(at: lineStart)) where token is CheckboxToken {
            return ReplaceTextCommand(range: (token as! CheckboxToken).range, textToReplace: OutlineParser.Values.List.unorderedList, textStorage: textStorage)
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
        
        for case let token in (textStorage.token(at: lineStart)) where token is OrderedListToken {
            return ReplaceTextCommand(range: (token as! OrderedListToken).prefix, textToReplace: "", textStorage: textStorage)
        }
        
        for case let token in (textStorage.token(at: lineStart)) where token is UnorderdListToken {
            return ReplaceTextCommand(range: (token as! UnorderdListToken).prefix, textToReplace: OutlineParser.Values.List.orderdList(index: "1"), textStorage: textStorage)
        }
        
        for case let token in (textStorage.token(at: lineStart)) where token is CheckboxToken {
            return ReplaceTextCommand(range: (token as! CheckboxToken).range, textToReplace: OutlineParser.Values.List.orderdList(index: "1"), textStorage: textStorage)
        }
        
        if lineStart > 0 {
            // 1. find last line index
            let lastLineStart = (textStorage.string as NSString).lineRange(for: NSRange(location: lineStart - 1, length: 0)).location
            for case let token in (textStorage.token(at: lastLineStart)) where token.name == OutlineParser.Key.Node.ordedList {
                // 2. insert index
                let lastPrefix = textStorage.string.nsstring.substring(with: token.range(for: OutlineParser.Key.Element.OrderedList.prefix)!)
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
        
        for case let token in (textStorage.token(at: lineStart)) where token is OrderedListToken {
            return ReplaceTextCommand(range: (token as! OrderedListToken).prefix, textToReplace: OutlineParser.Values.Checkbox.unchecked, textStorage: textStorage)
        }
        
        for case let token in (textStorage.token(at: lineStart)) where token is UnorderdListToken {
            return ReplaceTextCommand(range: (token as! UnorderdListToken).prefix, textToReplace: OutlineParser.Values.Checkbox.unchecked, textStorage: textStorage)
        }
        
        for case let token in (textStorage.token(at: lineStart)) where token is CheckboxToken {
            return ReplaceTextCommand(range: (token as! CheckboxToken).status, textToReplace: "", textStorage: textStorage)
        }
        
        return InsertTextCommandComposer(location: lineStart, textToInsert: OutlineParser.Values.Checkbox.unchecked).compose(textStorage: textStorage)
    }
}
