//
//  Token.swift
//  Business
//
//  Created by ian luo on 2019/2/28.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public enum BlockType {
    case quote
    case sourceCode
}

public class Token {
    public var offset: Int = 0 {
        didSet {
            log.verbose("offset did set: \(offset)")
        }
    }
    
    public let identifier: String
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
    
    public var name: String
    private var _rawData: [String: NSRange]
    
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
        textStorage.setAttributes(nil, range: self.range)
    }
    
    public func renderDecoration(textStorage: OutlineTextStorage) {
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
public class CheckboxToken: Token {}

// MARK: - LinkToken
public class LinkToken: Token {}

// MARK: - AttachmentToken
public class AttachmentToken: Token {}

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
        }
    }
    
    // the range from first of begin token to last of end token
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
    
    public var contentRange: NSRange? {
        if let endToken = self.endToken {
            return self.range.moveLeftBound(by: super.range.length).moveRightBound(by: -endToken.tokenRange.length)
        } else {
            return nil
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
        }
    }
    
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
        let levelUpperBound = self.levelRange.upperBound
        let planningUpperBound = self.planning?.upperBound ?? 0
        let priorityUpperBound = self.priority?.upperBound ?? 0
        
        let lowerBound = max(levelUpperBound, max(planningUpperBound, priorityUpperBound))
        let upperBound = min(self.range.upperBound, self.tags?.location ?? self.range.upperBound)
        
        return NSRange(location: lowerBound, length: upperBound - lowerBound)
    }
    
    public var levelRange: NSRange {
        return NSRange(location: self.range.location, length: self.level)
    }
    
    public var contentRange: NSRange {
        return self.paragraphRange.moveLeftBound(by: self.range.length)
    }
    
    public var paragraphRange: NSRange {
        return self.outlineTextStorage?.parangraphsRange(at: self.range.location) ?? self.range
    }
    
    public var subheadingsRange: NSRange {
        let lastChild = self.outlineTextStorage?.subheadings(of: self).last ?? self
        return NSRange(location: self.range.upperBound, length: lastChild.paragraphRange.upperBound - self.range.upperBound)
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
