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
    public var name: String
    public var data: [String: NSRange]
    
    public init(range: NSRange, name: String, data: [String: NSRange]) {
        self._range = range
        self.name = name
        self.data = data
        self.identifier = UUID().uuidString
    }
    
    public func offset(_ offset: Int) {
        self.offset += offset
    }
}

// MARK: - TextMark
public class TextMarkToken: Token {}

// MARK: - UnorderdList
public class UnorderdListToken: Token {}

// MARK: - OrderedListToken
public class OrderedListToken: Token {}

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
    
    public var contentRange: NSRange? {
        if let endToken = self.endToken {
            return self.range.moveLeftBound(by: super.range.length).moveRightBound(by: -endToken.range.length)
        } else {
            return nil
        }
    }
}

public class BlockEndToken: BlockToken {
//    public weak var beginToken: BlockBeginToken?
    public init(data: [String: NSRange], blockType: BlockType) {
        switch blockType {
        case .quote:
            super.init(range: data[OutlineParser.Key.Node.quoteBlockEnd]!, name: OutlineParser.Key.Node.quoteBlockEnd, data: data, blockType: blockType)
        case .sourceCode:
            super.init(range: data[OutlineParser.Key.Node.codeBlockEnd]!, name: OutlineParser.Key.Node.codeBlockEnd, data: data, blockType: blockType)
        }
    }
}

// MARK: - Heading

public class HeadingToken: Token {
    /// 当前的 heading 的 planning TODO|DONE|CANCELD 等
    public var planning: NSRange? {
        return data[OutlineParser.Key.Element.Heading.planning]?.offset(offset)
    }
    /// 当前 heading 的 tag 数组
    public var tags: NSRange? {
        return data[OutlineParser.Key.Element.Heading.tags]?.offset(offset)
    }
    /// 当前的 heading level
    public var level: Int {
        return data[OutlineParser.Key.Element.Heading.level]!.length
    }
    /// 当前的 heading level
    public var priority: NSRange? {
        return data[OutlineParser.Key.Element.Heading.priority]?.offset(offset)
    }
    /// close 标记
    public var closed: NSRange? {
        return data[OutlineParser.Key.Element.Heading.closed]?.offset(offset)
    }
    
    public weak var outlineTextStorage: OutlineTextStorage?
    
    /// tag 的位置，如果没有 tag，则为应该放 tag 的位置
    public var tagLocation: Int {
        if let tags = self.tags {
            return tags.location
        }
        
        return range.upperBound - 1
    }
    
    public var headingTextRange: NSRange {
        let levelUpperBound = self.level
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
        from \(self.range.location) to \(self.range.upperBound)
        """
    }
}
