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
//        set { _range = newValue }
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
            return self.range.moveLeft(by: super.range.length).moveRight(by: -endToken.range.length)
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
    /// 当前 heading 的 schedule
    public var schedule: NSRange? {
        return data[OutlineParser.Key.Element.Heading.schedule]?.offset(offset)
    }
    /// 当前 heading 的 due
    public var due: NSRange? {
        return data[OutlineParser.Key.Element.Heading.due]?.offset(offset)
    }
    /// 当前的 heading level
    public var level: Int {
        return data[OutlineParser.Key.Element.Heading.level]!.length
    }
    
    /// close 标记
    public var closed: NSRange? {
        return data[OutlineParser.Key.Element.Heading.closed]?.offset(offset)
    }
    
    /// tag 的位置，如果没有 tag，则为应该放 tag 的位置
    public var tagLocation: Int {
        if let tags = self.tags {
            return tags.location
        }
        
        if let schedule = self.schedule, let due = self.due {
            return min(schedule.location, due.location)
        }
        
        if let schedule = self.schedule {
            return schedule.location
        }
        
        if let due = self.due {
            return due.location
        }
        
        return range.upperBound
    }
    
    public var contentLength: Int = 0
    
    public var headingTextRange: NSRange {
        var headingContentRange: NSRange = self.range.offset(-self.range.location).moveLeft(by: self.level + 1)
        
        if let schedule = self.schedule {
            let dateRange = schedule.offset(-self.range.location)
            let newUpperBound = min(dateRange.lowerBound, headingContentRange.upperBound)
            headingContentRange = headingContentRange.withNewUpperBound(newUpperBound)
        }
        
        if let due = self.due {
            let dateRange = due.offset(-self.range.location)
            let newUpperBound = min(dateRange.lowerBound, headingContentRange.upperBound)
            headingContentRange = headingContentRange.withNewUpperBound(newUpperBound)
        }
        
        if let planning = self.planning {
            let planningRange = planning.offset(-self.range.location)
            let newLowerBound = max(headingContentRange.lowerBound, planningRange.upperBound + 1)
            headingContentRange = headingContentRange.withNewLowerBound(newLowerBound)
        }
        
        if let tags = self.tags {
            let tagsRange = tags.offset(-self.range.location)
            let newUpperBound = min(tagsRange.lowerBound - 1, headingContentRange.upperBound)
            headingContentRange = headingContentRange.withNewUpperBound(newUpperBound)
        }
        
        return headingContentRange
    }
    
    public var levelRange: NSRange {
        return NSRange(location: self.range.location, length: self.level)
    }
    
    public var contentRange: NSRange {
        return NSRange(location: self.range.upperBound, length: self.contentLength)
    }
    
    public var paragraphRange: NSRange {
        return NSRange(location: range.location, length: contentLength + range.length)
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
