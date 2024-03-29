//
//  Token.swift
//  Business
//
//  Created by ian luo on 2019/2/28.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface

public enum BlockType {
    case quote
    case sourceCode
    case drawer
}

public class Token {
    public var needsRender: Bool = false
    
    public var offset: Int = 0 {
        didSet {
            log.verbose("offset did set: \(offset)")
        }
    }
    
    public var identifier: String
    private var _range: NSRange
    public var range: NSRange {
        get { return offset == 0 ? _range : _range.offset(self.offset) }
    }
    
    // 有时候有的 token 会包含其他 token，比如 blockBgein token，这时候的 range 是包含了 blockEndToken 的
    // tokenRange 则只包含自身的 range
    // 默认值为自身的 range，在子 token 中自定义
    public var tokenRange: NSRange {
        return self.range
    }
    
    public var isEmbeded: Bool = false
    
    public var name: String
    private var _rawData: [String: NSRange]
    public var data: [String: NSRange] { return _rawData.mapValues { $0.offset(self.offset) } }
    
    public init(range: NSRange, name: String, data: [String: NSRange]) {
        self._range = range
        self.name = name
        self._rawData = data
        self.identifier = UUID().uuidString
    }
    
    public func offset(_ offset: Int) {
        self.offset += offset
    }
    
    public func range(for key: String) -> NSRange? {
        if let range = self._rawData[key] {
            return range.offset(self.offset)
        }
        return nil
    }
    
    
    internal var decorationAttributesAction: ((OutlineTextStorage, Token) -> Void)?
    
    public func clearDecoraton(textStorage: OutlineTextStorage) {
        let range = NSRange(location: min(self.range.location, textStorage.string.nsstring.length - 1),
                                          length: max(0, min(self.range.length, textStorage.string.nsstring.length - self.range.location)))
        textStorage.setAttributes(nil, range: range)
    }
    
    public func renderDecoration(textStorage: OutlineTextStorage) {
        textStorage.setAttributes(nil, range: self.range)
        // 设置文字默认样式
        textStorage.addAttributes(OutlineTheme.paragraphStyle.attributes,
                           range: self.range)
        self.decorationAttributesAction?(textStorage, self)
    }
}

// MARK: - TextMark
public class TextMarkToken: Token {}

// MARK: - UnorderdList
public class UnorderdListToken: Token {
    public var prefix: NSRange { return range(for: OutlineParser.Key.Element.UnorderedList.prefix) ?? NSRange(location: self.range.location, length: 0) }
}

// MARK: - OrderedListToken
public class OrderedListToken: Token {
    public var prefix: NSRange { return range(for: OutlineParser.Key.Element.OrderedList.prefix) ?? NSRange(location: self.range.location, length: 0) }
}

// MARK: - CheckboxToken
public class CheckboxToken: Token {
    public var status: NSRange { return range(for: OutlineParser.Key.Element.Checkbox.status) ?? NSRange(location: self.range.location, length: 0) }
}

// MARK: - LinkToken
public class LinkToken: Token {
    func isDocumentLink(textStorage: OutlineTextStorage) -> Bool {
        if let urlRange = self.range(for: OutlineParser.Key.Element.Link.url) {
            return textStorage.substring(urlRange).hasPrefix(OutlineParser.Values.Link.x3)
        } else {
            return false
        }
    }
    
    func isDocumentLink(string: String) -> Bool {
        if let urlRange = self.range(for: OutlineParser.Key.Element.Link.url) {
            return (string as NSString).substring(with: urlRange).hasPrefix(OutlineParser.Values.Link.x3)
        } else {
            return false
        }
    }
}

// MARK: - AttachmentToken
public class AttachmentToken: Token {
    public var keyRange: NSRange? {
        return self.range(for: OutlineParser.Key.Element.Attachment.value)
    }
}

// MARK: - SeparatorToken
public class SeparatorToken: Token {}

// MARK: - DateAndTimeToken
public class DateAndTimeToken: Token {}

// MARK: - Block

public class BlockToken: Token {
    public let blockType: BlockType
    fileprivate init(range: NSRange, name: String, data: [String: NSRange], blockType: BlockType) {
        self.blockType = blockType
        super.init(range: range, name: name, data: data)
    }
    
    public var isPaired: Bool { return false }
    
    public var contentRange: NSRange? { return nil }
    
    public var isPropertyDrawer: Bool = false
}

/// if block is paired, BlockBeginToken means the whole block
public class BlockBeginToken: BlockToken {
    public weak var endToken: BlockEndToken?
    public init(data: [String: NSRange], blockType: BlockType) {
        switch blockType {
        case .quote:
            super.init(range: data[OutlineParser.Key.Node.quoteBlockBegin]!, name: OutlineParser.Key.Node.quoteBlockBegin, data: data, blockType: blockType)
        case .sourceCode:
            super.init(range: data[OutlineParser.Key.Node.codeBlockBegin]!, name: OutlineParser.Key.Node.codeBlockBegin, data: data, blockType: blockType)
        case .drawer:
            super.init(range: data[OutlineParser.Key.Node.drawerBlockBegin]!, name: OutlineParser.Key.Node.drawerBlockBegin, data: data, blockType: blockType)
        }
    }
    
    public override var isPaired: Bool { return self.endToken != nil }
    
    /// the range from first of begin token to last of end token
    public override var range: NSRange {
        if let endToken = self.endToken {
            return NSRange(location: super.range.location, length: endToken.range.upperBound - super.range.location)
        } else {
            return super.range
        }
    }
    
    public override var tokenRange: NSRange {
        return super.range
    }
    
    /// the range of the part exclude the block token
    public override var contentRange: NSRange? {
        if let endToken = self.endToken {
            return self.range.moveLeftBound(by: self.tokenRange.length).moveRightBound(by: -endToken.tokenRange.length)
        } else {
            return nil
        }
    }
    
    public override func renderDecoration(textStorage: OutlineTextStorage) {
        self.decorationAttributesAction?(textStorage, self)
        
        if let endToken = self.endToken {
            endToken.decorationAttributesAction?(textStorage, endToken)
        }
    }
}

public class BlockEndToken: BlockToken {
    public weak var beginToken: BlockBeginToken?
    public init(data: [String: NSRange], blockType: BlockType) {
        switch blockType {
        case .quote:
            super.init(range: data[OutlineParser.Key.Node.quoteBlockEnd]!, name: OutlineParser.Key.Node.quoteBlockEnd, data: data, blockType: blockType)
        case .sourceCode:
            super.init(range: data[OutlineParser.Key.Node.codeBlockEnd]!, name: OutlineParser.Key.Node.codeBlockEnd, data: data, blockType: blockType)
        case .drawer:
            super.init(range: data[OutlineParser.Key.Node.drawerBlockEnd]!, name: OutlineParser.Key.Node.drawerBlockEnd, data: data, blockType: blockType)
        }
    }
    
    public override var isPaired: Bool { return self.beginToken != nil }
    
    // the range from first of begin token to last of end token
    public override var range: NSRange {
        if let beginToken = self.beginToken {
            return NSRange(location: beginToken.tokenRange.location, length: super.range.upperBound - beginToken.tokenRange.location)
        } else {
            return super.range
        }
    }
    
    public override var tokenRange: NSRange {
        return super.range
    }
    
    /// the range of the part exclude the block token
    public override var contentRange: NSRange? {
        if let beginToken = self.beginToken {
            return self.range.moveLeftBound(by: beginToken.tokenRange.length).moveRightBound(by: -self.tokenRange.length)
        } else {
            return nil
        }
    }
    
    public override func renderDecoration(textStorage: OutlineTextStorage) {
        self.decorationAttributesAction?(textStorage, self)
        
        if let beginToken = self.beginToken {
            beginToken.decorationAttributesAction?(textStorage, beginToken)
        }
    }
}

public class Keywork: Token {
    public var key: NSRange?
    public var value: NSRange?
}


// MARK: - Heading

public class HeadingToken: Token {
    
    /// 当前的 heading 的 planning TODO|DONE|CANCELD 等
    public var planning: NSRange? {
        return self.range(for: OutlineParser.Key.Element.Heading.planning)
    }
    /// 当前 heading 的 tag 数组
    public var tags: NSRange? {
        return self.range(for: OutlineParser.Key.Element.Heading.tags)
    }
    /// 当前的 heading level
    public var level: Int {
        return self.range(for: OutlineParser.Key.Element.Heading.level)!.length
    }
    /// 当前的 heading level
    public var priority: NSRange? {
        return self.range(for: OutlineParser.Key.Element.Heading.priority)
    }
    /// close 标记
    public var closed: NSRange? {
        return self.range(for: OutlineParser.Key.Element.Heading.closed)
    }
    
    public var id: NSRange? {
        return self.range(for: OutlineParser.Key.Element.Heading.id)
    }
    
    /// the prefix part, containing level and id
    public var prefix: NSRange {
        if let id = id {
            return NSRange(location: self.range.location, length: self.level + id.length)
        } else {
            return self.levelRange
        }
    }
    
    /// the heading after id and level
    public var headingContent: NSRange? {
        return self.range(for: OutlineParser.Key.Element.Heading.content)
    }
    
    public var contentLocation: Int {
        return (self.headingContent?.head(0) ?? self.id?.tail(0).offset(1) ?? self.range.tail(0)).location
    }
    
    public func tagsArray(string: String) -> [String] {
        if let tagRange = self.tags {
            return string.nsstring.substring(with: tagRange).components(separatedBy: ":").filter { $0.count > 0 }
        } else {
            return []
        }
    }
    
    public weak var outlineTextStorage: OutlineTextStorage?
    
    /// tag 的位置，如果没有 tag，则为应该放 tag 的位置
    public var tagLocation: Int {
        if let tags = self.tags {
            return tags.location
        }
        
        return range.upperBound
    }
        
    public var headingTextRange: NSRange {
        return self.headingContent ?? NSRange(location: self.contentLocation, length: self.range.upperBound - self.contentLocation)
    }
    
    public var headingTextWithoutOtherTags: NSRange {
        let planningUpperBound = self.planning?.upperBound ?? 0
        let prioerityUpperBound = self.priority?.upperBound ?? 0
        let otherTagsLocation = max(planningUpperBound, prioerityUpperBound)
        
        let location = max(self.headingTextRange.location, otherTagsLocation)
        return NSRange(location: location, length: self.headingTextRange.upperBound - location - (self.tags?.length ?? 0))
    }
    
    public var levelRange: NSRange {
        return NSRange(location: self.range.location, length: self.level)
    }
    
    public var contentRange: NSRange? {
        let calculatedContentRange = self.paragraphRange.moveLeftBound(by: self.range.length)
        
        // 如果计算出的 contentRange 长度为 0，表示没有内容，这个 range 的 location 实际上是不可用的
        if calculatedContentRange.length == 0 {
            return nil
        } else {
            return calculatedContentRange
        }
    }
        
    public var paragraphRange: NSRange {
        return self.outlineTextStorage?.parangraphsRange(at: self.range.location) ?? self.range
    }
    
    public var contentWithSubHeadingsRange: NSRange {
        let lastChild = self.outlineTextStorage?.subheadings(of: self).last ?? self
        return NSRange(location: self.range.upperBound, length: lastChild.paragraphRange.upperBound - self.range.upperBound)
    }
    
    public var contentWithFirstLevelSubHeadingsRange: NSRange {
        let lastChild = self.outlineTextStorage?.firstLevelSubheadings(of: self).last ?? self
        return NSRange(location: self.range.upperBound, length: lastChild.paragraphRange.upperBound - self.range.upperBound)
    }
    
    public var paragraphWithSubRange: NSRange {
        return self.range.union(self.contentWithSubHeadingsRange)
    }
    
    public var upperBoundWithoutLineBreak: Int {
        if self.range.upperBound == self.outlineTextStorage?.length {
            return self.range.upperBound
        } else {
            return self.range.upperBound - 1
        }
    }
    
    public convenience init(data: [String: NSRange]) {
        self.init(range: data[OutlineParser.Key.Node.heading]!, name: OutlineParser.Key.Node.heading, data: data)
    }
}

extension Token: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
        
        \(self.name)
        \(self.range)
        """
    }
}
