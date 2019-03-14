//
//  TextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol OutlineTextStorageDelegate: class {
    func didSetCurrentHeading(newHeading: HeadingToken?, oldHeading: HeadingToken?)
    func didUpdateHeadings(newHeadings:[HeadingToken], oldHeadings: [HeadingToken])
}

/// 提供渲染的对象，如 attachment, checkbox 等
public protocol OutlineTextStorageDataSource: class {
    // TODO: outline text storage data source
}

public class OutlineTextStorage: TextStorage {
    public var parser: OutlineParser!
    
    private let _eventObserver: EventObserver
    private let _attachmentManager: AttachmentManager
    
    public init(eventObserver: EventObserver, attachmentManager: AttachmentManager) {
        self._attachmentManager = attachmentManager
        self._eventObserver = eventObserver
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var string: String {
        set { super.replaceCharacters(in: NSRange(location: 0, length: self.string.count), with: newValue) }
        get { return super.string }
    }
    
    public var theme: OutlineTheme = OutlineTheme()
    
    public weak var outlineDelegate: OutlineTextStorageDelegate?
    
    /// 用于 cache 已经找到的 heading
    private var _savedHeadings: WeakArray<HeadingToken> = WeakArray()
    // cache parsed code block border line
    private var _codeBlocks: WeakArray<BlockToken> = WeakArray()
    // cache parsed quote block border line
    private var _quoteBlocks: WeakArray<BlockToken> = WeakArray()
    
    /// 当前交互的文档位置，当前解析部分相对于文档开始的偏移量，不同于 currentParseRange 中的 location
    public var currentLocation: Int = 0
    
    // refering to current heading, when use change selection, this value changes
    public weak var currentHeading: HeadingToken?
    
    /// 当前的解析范围，需要进行解析的字符串范围，用于对 item，索引 等缓存数据进行重新组织
    public var currentParseRange: NSRange?
    // MARK: - Selection highlight
        {
            didSet {
                if let _ = oldValue {
                    self.removeAttribute(NSAttributedString.Key.backgroundColor, range: NSRange(location: 0, length: self.string.count))
                }
            }
        }
    
    // return the references of saved heading token
    public var headingTokens: [HeadingToken] {
        return self._savedHeadings.allObjects
    }
    
    public var codeBlocks: [BlockBeginToken] {
        return self._pairedCodeBlocks
    }
    
    public var quoteBlocks: [BlockBeginToken] {
        return self._pairedQuoteBlocks
    }
    
    /// 当前所在编辑位置的最外层，或者最前面的 item 类型, 某些 item 在某些编辑操作是会有特殊行为，例如:
    /// 当前 item 为 unordered list 时，换行将会自动添加一个新的 unordered list 前缀
    public var currentItem: Token? {
        return self.token(after: self.currentLocation)
    }
    
    /// 所有解析获得的 token, 对应当前的文档结构解析状态
    public var allTokens: [Token] = []
    
    // 用于解析过程中临时数据处理, only useful during parsing
    private var _tempParsingTokenResult: [Token] = []
    // 某些范围要忽略掉文字的样式，比如 link 内的文字样式, only usefule during parsing
    private var _ignoreTextMarkRanges: [NSRange] = []
}

// MARK: - Update Attributes
extension OutlineTextStorage: ContentUpdatingProtocol {
    public func performContentUpdate(_ string: String!, range: NSRange, delta: Int, action: NSTextStorage.EditActions) {

        guard self.editedMask != .editedAttributes else { return } // 如果是修改属性，则不进行解析
        guard self.string.count > 0 else { return }
        
        /// 更新当前交互的位置
        self.currentLocation = editedRange.location

        // 更新 item 索引缓存
        self.updateTokenRangeOffset(delta: self.changeInLength)

        // 调整需要解析的字符串范围
        self._adjustParseRange(editedRange)

        if let parsingRange = self.currentParseRange {
            // 清空 attributes (折叠的状态除外) // FIXME: after editing, folded attributes and ranges are lost, including heading ranges
            var effectiveRange: NSRange = NSRange(location:0, length: 0)
            let value = self.attribute(OutlineAttribute.hidden, at: parsingRange.location, longestEffectiveRange: &effectiveRange, in: parsingRange)
            if let value = value as? NSNumber, value.intValue == OutlineAttribute.hiddenValueFolded.intValue {
                self.setAttributes([:], range: parsingRange)
                self.addAttribute(OutlineAttribute.Heading.folded, value: OutlineAttribute.hiddenValueFolded, range: effectiveRange)
            }
            self.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.red.withAlphaComponent(0.5)], range: self.currentParseRange!)
        }

        // 设置文字默认样式
        self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive,
                            NSAttributedString.Key.font: InterfaceTheme.Font.body],
                           range: self.currentParseRange!)

        // 解析文字，添加样式
        parser.parse(str: self.string,
                     range: self.currentParseRange!)

        // 更新当前状态缓存
        self.updateCurrentInfo()
    }
}

// MARK: -
extension OutlineTextStorage {
    /// 找到对应位置之后的第一个 token
    public func token(after: Int) -> Token? {
        for item in self.allTokens {
            if item.range.upperBound >= after {
                return item
            }
        }
        
        return nil
    }
    
    /// 获取范围内的 item range 的索引
    private func _indexsOfToken(in: NSRange) -> [Int]? {
        var items: [Int] = []
        for (index, item) in self.allTokens.enumerated() {
            if item.range.location >= `in`.location &&
                item.range.upperBound <= `in`.upperBound {
                items.append(index)
            }
        }
        
        return items.count > 0 ? items : nil
    }
    
    public func updateTokenRangeOffset(delta: Int) {
        self.allTokens
            .filter { $0.range.location > self.currentLocation }
            .forEach { $0.offset(delta) }
    }
    
    public func heading(contains location: Int) -> HeadingToken? {
        for heading in self.headingTokens {
            if heading.paragraphRange.contains(location) {
                return heading
            }
        }
        
        return nil
    }
    
    /// 更新和当前位置相关的其他信息
    public func updateCurrentInfo() {
        
        guard self._savedHeadings.count > 0 else { return }
        
        let oldHeading = self.currentHeading
        self.currentHeading = self.heading(contains: self.currentLocation)
        self.outlineDelegate?.didSetCurrentHeading(newHeading: self.currentHeading, oldHeading: oldHeading)
    }
}

// MARK: - Parse result -
extension OutlineTextStorage: OutlineParserDelegate {
    public func didFoundTextMark(text: String, markRanges: [[String: NSRange]]) {
        var markRanges = markRanges
        let count = markRanges.count - 1
        for (index, dict) in markRanges.reversed().enumerated() {
            let range = dict.first!.value
            
            for ignorRange in self._ignoreTextMarkRanges {
                if ignorRange.location <= range.location && ignorRange.upperBound >= range.upperBound {
                    markRanges.remove(at: count - index)
                    break
                }
            }
        }
        
        
        for dict in markRanges {
            for (key, range) in dict {
                switch key {
                case OutlineParser.Key.Element.TextMark.bold:
                    self._tempParsingTokenResult.append(Token(range: range, name: key, data: dict))
                    self.addAttributes(OutlineTheme.Attributes.TextMark.bold, range: range)
                case OutlineParser.Key.Element.TextMark.italic:
                    self._tempParsingTokenResult.append(Token(range: range, name: key, data: dict))
                    self.addAttributes(OutlineTheme.Attributes.TextMark.italic, range: range)
                case OutlineParser.Key.Element.TextMark.strikeThough:
                    self._tempParsingTokenResult.append(Token(range: range, name: key, data: dict))
                    self.addAttributes(OutlineTheme.Attributes.TextMark.strikeThough, range: range)
                case OutlineParser.Key.Element.TextMark.code:
                    self._tempParsingTokenResult.append(Token(range: range, name: key, data: dict))
                    self.addAttributes(OutlineTheme.Attributes.TextMark.code, range: range)
                case OutlineParser.Key.Element.TextMark.underscore:
                    self._tempParsingTokenResult.append(Token(range: range, name: key, data: dict))
                    self.addAttributes(OutlineTheme.Attributes.TextMark.underscore, range: range)
                case OutlineParser.Key.Element.TextMark.verbatim:
                    self._tempParsingTokenResult.append(Token(range: range, name: key, data: dict))
                    self.addAttributes(OutlineTheme.Attributes.TextMark.verbatim, range: range)
                default: break
                }
            }
        }
    }
    
    public func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {
        
        urlRanges.forEach { urlRangeData in
            
            self._ignoreTextMarkRanges.append(contentsOf: urlRanges.map { $0[OutlineParser.Key.Element.link]! })
            
            if let range = urlRangeData[OutlineParser.Key.Element.link] {
                self._tempParsingTokenResult.append(Token(range: range, name: OutlineParser.Key.Element.link, data: urlRangeData))
                
                self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueDefault, range: range)
            }
            urlRangeData.forEach {
                // range 为整个链接时，添加自定义属性，值为解析的链接结构
                if $0.key == OutlineParser.Key.Element.Link.title {
                    self.addAttributes([NSAttributedString.Key.link: 1], range: $0.value)
                    self.removeAttribute(OutlineAttribute.hidden, range: $0.value)
                } else if $0.key == OutlineParser.Key.Element.Link.url {
                    self.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                        OutlineAttribute.showAttachment: OutlineAttribute.Link.url],
                                       range: $0.value)
                }
            }
        }
    }
    
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        attachmentRanges.forEach { rangeData in
            
            guard let attachmentRange = rangeData[OutlineParser.Key.Node.attachment] else { return }
            guard let typeRange = rangeData[OutlineParser.Key.Element.Attachment.type] else { return }
            guard let valueRange = rangeData[OutlineParser.Key.Element.Attachment.value] else { return }
            
            self._tempParsingTokenResult.append(Token(range: attachmentRange, name: OutlineParser.Key.Node.attachment, data: rangeData))
            
            self.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment],
                               range: attachmentRange)
        
            let type = text.substring(typeRange)
            let value = text.substring(valueRange)
            if let attachment: NSTextAttachment = RenderAttachment(type: type, value: value, manager: self._attachmentManager) {
                if !super.isAttachmentExists(withKey: value) {
                    super.add(attachment, for: value)
                }
                
                self.addAttributes([OutlineAttribute.showAttachment: value],
                                  range: attachmentRange.head(1))
            } else {
                self.addAttributes([OutlineAttribute.showAttachment: OutlineAttribute.Attachment.unavailable],
                                   range: attachmentRange.head(1))
            }
        }
    }
    
    public func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {
        
        checkboxRanges.forEach { rangeData in
            
            guard let checkboxRange = rangeData[OutlineParser.Key.Node.checkbox] else { return }
            
            self._tempParsingTokenResult.append(Token(range: checkboxRange, name: OutlineParser.Key.Node.checkbox, data: rangeData))
            
            for (key, range) in rangeData {
                if key == OutlineParser.Key.Element.Checkbox.status {
                    self.addAttribute(OutlineAttribute.Checkbox.box, value: rangeData, range: range)
                    self.addAttribute(OutlineAttribute.Checkbox.status, value: range, range: NSRange(location: range.location, length: 1))
                    self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.spotlight,
                                        NSAttributedString.Key.font: InterfaceTheme.Font.title], range: range)
                }
            }
        }
    }
    
    public func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {
        
        orderedListRnages.forEach { list in
            if let index = list[OutlineParser.Key.Element.OrderedList.index] {
                self.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.title,
                                    NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    OutlineAttribute.OrderedList.index: index], range: index)
            }
            
            if let range = list[OutlineParser.Key.Node.ordedList] {
                self._tempParsingTokenResult.append(Token(range: range, name: OutlineParser.Key.Node.ordedList, data: list))
                
                self.addAttribute(OutlineAttribute.OrderedList.range, value: range, range: range)
            }
        }
    }
    
    public func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {
        
        unOrderedListRnages.forEach { list in
            guard let listRange = list[OutlineParser.Key.Node.unordedList] else { return }
            
            self._tempParsingTokenResult.append(Token(range: listRange, name: OutlineParser.Key.Node.unordedList, data: list))
            
            if let prefix = list[OutlineParser.Key.Element.UnorderedList.prefix] {
                self.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.title,
                                    NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive], range: prefix)
            }
        }
    }
    
    public func didFoundSeperator(text: String, seperatorRanges: [[String: NSRange]]) {
        
        seperatorRanges.forEach { range in
            
            guard let separatorRange = range[OutlineParser.Key.Node.seperator] else { return }
            
            self._tempParsingTokenResult.append(Token(range: separatorRange, name: OutlineParser.Key.Node.seperator, data: range))
            
            if let seperatorRange = range[OutlineParser.Key.Node.seperator] {
                self.addAttributes([OutlineAttribute.hidden: 2,
                                    OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_SEPARATOR], range: seperatorRange)
            }
        }
    }
    
    public func didFoundCodeBlockBegin(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            guard let range = rangeData[OutlineParser.Key.Node.codeBlockBegin] else { return }
            
            self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                                NSAttributedString.Key.backgroundColor: InterfaceTheme.Color.background2], range: range)
            
            let token = BlockBeginToken(data: rangeData, blockType: BlockType.sourceCode)
            self._tempParsingTokenResult.append(token)
        }
    }
    
    public func didFoundCodeBlockEnd(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            guard let range = rangeData[OutlineParser.Key.Node.codeBlockEnd] else { return }
            
            self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                                NSAttributedString.Key.backgroundColor: InterfaceTheme.Color.background2], range: range)
            
            let token = BlockEndToken(data: rangeData, blockType: BlockType.sourceCode)
            self._tempParsingTokenResult.append(token)
        }
    }
    
    public func didFoundQuoteBlockBegin(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.paragraphSpacingBefore = 10
            paragraph.headIndent = 100
            
            guard let range = rangeData[OutlineParser.Key.Node.quoteBlockBegin] else { return }
            
            self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                                NSAttributedString.Key.paragraphStyle: paragraph], range: range)
            
            
            let token = BlockBeginToken(data: rangeData, blockType: BlockType.quote)
            self._tempParsingTokenResult.append(token)
        }
    }
    
    public func didFoundQuoteBlockEnd(text: String, ranges: [[String : NSRange]]) {

        ranges.forEach { quoteRange in
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.paragraphSpacingBefore = 10
            paragraph.headIndent = 100
            
            guard let range = quoteRange[OutlineParser.Key.Node.quoteBlockEnd] else { return }
            
            self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                                NSAttributedString.Key.paragraphStyle: paragraph], range: range)
            
            let token = BlockEndToken(data: quoteRange, blockType: BlockType.quote)
            self._tempParsingTokenResult.append(token)
        }
    }
    
    public func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {
        
        headingDataRanges.forEach {
            guard let headingRange = $0[OutlineParser.Key.Node.heading] else { return }
            
            let token = HeadingToken(data: $0)
            
            self._tempParsingTokenResult.append(token)
            
            self.addAttribute(OutlineAttribute.Heading.content, value: headingRange, range: headingRange)
            
            if let levelRange = $0[OutlineParser.Key.Element.Heading.level] {
                self.addAttribute(OutlineAttribute.Heading.level, value: $0, range: levelRange)
                self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueWithAttachment, range: levelRange)
                // 默认状态为 unfolded
                self.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingUnfolded, range: levelRange)
            }
            
            if let scheduleRange = $0[OutlineParser.Key.Element.Heading.schedule],
                let scheduleDateAndTimeRange = $0[OutlineParser.Key.Element.Heading.scheduleDateAndTime] {
                self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueDefault, range: scheduleRange.moveLeft(by: 1))
                self.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                    OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_HEADING_SCHEDULE], range: scheduleRange.head(1))
                self.addAttributes([OutlineAttribute.Heading.schedule: scheduleRange,
                                    OutlineAttribute.button: InterfaceTheme.Color.descriptive], range: scheduleRange)
                self.removeAttribute(OutlineAttribute.hidden, range: scheduleDateAndTimeRange)
            }
            
            if let dueRange = $0[OutlineParser.Key.Element.Heading.due],
                let dueDateAndTimeRange = $0[OutlineParser.Key.Element.Heading.dueDateAndTime] {
                self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueDefault, range: dueRange.moveLeft(by: 1))
                self.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                    OutlineAttribute.showAttachment: OutlineAttribute.Heading.due], range: dueRange.head(1))
                self.addAttributes([OutlineAttribute.Heading.due: dueRange,
                                    OutlineAttribute.button: InterfaceTheme.Color.descriptive], range: dueRange)
                self.removeAttribute(OutlineAttribute.hidden, range: dueDateAndTimeRange)
            }
            
            if let tagsRange = $0[OutlineParser.Key.Element.Heading.tags] {
                self.addAttribute(OutlineAttribute.Heading.tags, value: tagsRange, range: tagsRange)
                self.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                    OutlineAttribute.showAttachment: OutlineAttribute.Heading.tags], range: tagsRange.head(1))
                self.addAttributes([OutlineAttribute.Heading.tags: tagsRange,
                                    OutlineAttribute.button: InterfaceTheme.Color.descriptive], range: tagsRange)
            }
            
            if let planningRange = $0[OutlineParser.Key.Element.Heading.planning] {
                self.addAttribute(OutlineAttribute.Heading.planning, value: planningRange, range: planningRange)
                self.addAttribute(NSAttributedString.Key.font, value: InterfaceTheme.Font.title, range: planningRange)
                self.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: planningRange)
            }
        }
    }
    
    public func didStartParsing(text: String) {
        self._tempParsingTokenResult = []
        self._ignoreTextMarkRanges = []
    }
    
    public func didCompleteParsing(text: String) {
        self._updateTokens(new: self._tempParsingTokenResult)
        
        // 更新段落长度信息
        self._updateHeadingParagraphLength()
        
        // 更新段落缩进样式
        self._setParagraphIndent()
        
        print(self.debugDescription)
    }
    
    /// 更新 items 中的数据
    private func _updateTokens(new tokens: [Token]) {
        var newTokens: [Token] = tokens

        // 对新的 token 进行排序
        newTokens.sort { (lhs: Token, rhs: Token) -> Bool in
            if lhs.range.location != rhs.range.location {
                return lhs.range.location < rhs.range.location
            } else {
                return lhs.range.length >= rhs.range.length
            }
        }
        
        // 第一次解析，将所有结果直接加入缓存
        if self.allTokens.count == 0 {
            self.allTokens.append(contentsOf: newTokens)
        } else {
            guard let currentParseRange = self.currentParseRange else { return }
            let oldCount = self.allTokens.count
            for index in self._findIntersectionTokenIndex(in: currentParseRange, tokens: self.allTokens).reversed() {
                self.allTokens.remove(at: index)
            }
            
            // add new found items
            self.allTokens.insert(contentsOf: newTokens, at: self._findNextTokenIndex(after: currentParseRange, tokens: self.allTokens))
            log.info("[item count changed] \(self.allTokens.count - oldCount)")
        }
        
        _ = self._savedHeadings.compact()
        let newHeadings = newTokens.filter { $0 is HeadingToken }.map { $0 as! HeadingToken }
        
        self._updateTokenCache(self._savedHeadings, with: newHeadings)
        
        let codeBlocksRemovedCount = self._codeBlocks.compact()
        let newCodeBlocks = newTokens.filter {
            if let t = $0 as? BlockToken, t.blockType == .sourceCode {
                return true
            } else {
                return false
            }
        }
        .map { $0 as! BlockToken }
        
        self._updateTokenCache(self._codeBlocks, with: newCodeBlocks)
        
        if newCodeBlocks.count > 0 || codeBlocksRemovedCount > 0 {
            self._figureOutBlocks(self._codeBlocks)
            self._addStylesForCodeBlock()
        }
        
        let quoteBlocksRemovedCount = self._quoteBlocks.compact()
        let newQuoteBlocks = newTokens.filter {
            if let t = $0 as? BlockToken, t.blockType == .quote {
                return true
            } else {
                return false
            }
        }
        .map { $0 as! BlockToken }
        
        self._updateTokenCache(self._quoteBlocks, with: newQuoteBlocks)
        
        if newQuoteBlocks.count > 0 || quoteBlocksRemovedCount > 0 {
            self._figureOutBlocks(self._quoteBlocks)
            self._addStylesForQuoteBlock()
        }
    }
    
    // MARK: - utils
    
    private func _addStylesForCodeBlock() {
        guard let currentRange = self.currentParseRange else { return }
        
        for blockBeginToken in self._pairedCodeBlocks {
            // find current block range
            if blockBeginToken.range.intersection(currentRange) != nil {
                if let contentRange = blockBeginToken.contentRange {
                    self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                        NSAttributedString.Key.font: InterfaceTheme.Font.body], range: contentRange)
                }
            }
        }
    }
    
    private func _addStylesForQuoteBlock() {
        guard let currentRange = self.currentParseRange else { return }
        
        for blockBeginToken in self._pairedQuoteBlocks {
            // find current block range
            if blockBeginToken.range.intersection(currentRange) != nil {
                if let contentRange = blockBeginToken.contentRange {
                    self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.spotlight,
                                        NSAttributedString.Key.font: InterfaceTheme.Font.title], range: contentRange)
                }
            }
        }
    }
    
    // make internal begin-end connection to build paired block ranges
    private func _figureOutBlocks<T: BlockToken>(_ blocks: WeakArray<T>) {
        for i in 0..<blocks.count {
            // condition 1. i 为 BlockBeginToken
            if let token = blocks[i] as? BlockBeginToken,
                // condition 2. i 不为最后一个 token
                blocks.count - 1 >= i + 1,
                 // condition 3. i + 1 为 BlockEndToken
                let endToken = blocks[i + 1] as? BlockEndToken {
                token.endToken = endToken
            }
        }
    }
    
    /// find pared code blocks, only return begin token, the end token is refered by begin token(weakly)
    private var _pairedCodeBlocks: [BlockBeginToken] {
        return self._codeBlocks.allObjects.filter {
            if let begin = $0 as? BlockBeginToken {
                return begin.endToken != nil
            } else {
                return false
            }
            }.map { $0 as! BlockBeginToken }
    }
    
    /// find pared code blocks, only return begin token, the end token is refered by begin token(weakly)
    private var _pairedQuoteBlocks: [BlockBeginToken] {
        return self._quoteBlocks.allObjects.filter {
            if let begin = $0 as? BlockBeginToken {
                return begin.endToken != nil
            } else {
                return false
            }
        }.map { $0 as! BlockBeginToken }
    }
    
    private func _updateTokenCache<T: Token>(_ cache: WeakArray<T>, with newTokens: [T]) {
        if cache.count == 0 {
            cache.insert(newTokens, at: 0)
        } else {
            if let first = newTokens.first {
                for i in 0..<cache.count {
                    if let token = cache[i] {
                        if first.range.upperBound < token.range.location {
                            cache.insert(newTokens, at: i)
                            return
                        }
                    }
                }
            }
        }
    }
    
    private func _findIntersectionTokenIndex(in range: NSRange, tokens: [Token]) -> [Int] {
        var indexes: [Int] = []
        for (index, token) in tokens.enumerated() {
            if token.range.intersection(range) != nil {
                indexes.append(index)
            }
        }
        return indexes
    }
    
    private func _findNextTokenIndex(after range: NSRange, tokens: [Token]) -> Int {
        var indexToInserNewHeadings: Int = tokens.count - 1
        for (index, heading) in tokens.enumerated() {
            if heading.range.upperBound <= range.upperBound {
                if index + 1 < tokens.count - 1 {
                    indexToInserNewHeadings = index + 1
                } else {
                    indexToInserNewHeadings = index
                }
                break
            }
        }
        return indexToInserNewHeadings
    }
    
    private func _setParagraphIndent() {
        for heading in self.headingTokens {
//            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.firstLineHeadIndent = CGFloat(heading.level * 8) // FIXME: 设置 indent 的宽度
//            paragraphStyle.headIndent = paragraphStyle.firstLineHeadIndent
            
//            (self.string as NSString)
//                .enumerateSubstrings(
//                    in: heading.paragraphRange,
//                    options: .byLines
//                ) { (_, range, inclosingRange, stop) in
//                    if range.location == heading.range.location {
//                        let headParagraphStyle = NSMutableParagraphStyle()
//                        headParagraphStyle.headIndent = paragraphStyle.firstLineHeadIndent
//                        self.addAttributes([NSAttributedString.Key.paragraphStyle: headParagraphStyle], range: inclosingRange)
//                    } else {
//                        self.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: inclosingRange)
//                    }
//            }
        }
    }
    
    /// 获得用 heading 分割的段落的 range 列表
    private func _updateHeadingParagraphLength() {
        var endOfParagraph = self.string.count
        self.headingTokens.reversed().forEach {
            $0.contentLength = endOfParagraph - $0.range.upperBound - 1
            endOfParagraph = $0.range.location
        }
    }
    
    internal func _adjustParseRange(_ range: NSRange) {
        let range = range._expandFoward(string: self.string, lineCount: 1)._expandBackward(string: self.string, lineCount: 1)
        self.currentParseRange = range
        
        // 如果范围在某个 item 内，并且小于这个 item 原来的范围，则扩大至这个 item 原来的范围
        if let currentParseRange = self.currentParseRange {
            for item in self.allTokens {
                if item.range.intersection(currentParseRange) != nil {
                    self.currentParseRange = item.range.union(currentParseRange)
                    return
                }
            }
        }
    }
}

extension OutlineTextStorage: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage,
                            willProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
        
    }
    
    /// 添加文字属性
    public func textStorage(_ textStorage: NSTextStorage,
                            didProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
    }
}

extension NSRange {
    /// 将在字符串中的选择区域扩展到前一个换行符之后，后一个换行符之前
    internal func _expandBackward(string: String, lineCount: Int) -> NSRange {
        var extendedRange = self
        var characterBuf: String = ""

        while extendedRange.location > 0
            && !self._checkShouldContinueExpand(buf: &characterBuf, next: string.substring(NSRange(location: extendedRange.location - 1, length: 1)), lineCount: lineCount) {
                extendedRange = NSRange(location: extendedRange.location - 1, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
    
    internal func _expandFoward(string: String, lineCount: Int) -> NSRange {
        var extendedRange = self
        var characterBuf: String = ""
        
        while extendedRange.upperBound < string.count - 1
            && !self._checkShouldContinueExpand(buf: &characterBuf, next: string.substring(NSRange(location: extendedRange.upperBound, length: 1)), lineCount: lineCount) {
                extendedRange = NSRange(location: extendedRange.location, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
    
    // 检查是否继续 expand
    private func _checkShouldContinueExpand(buf: inout String, next character: String, lineCount: Int) -> Bool {
        if character == OutlineParser.Values.Character.linebreak {
            buf.append(character)
        }
        
        return buf.count == lineCount
    }
}

extension OutlineTextStorage {
    public override var debugDescription: String {
        return """
        length: \(self.string.count)
        heading count: \(self._savedHeadings.count)
        codeBlock count: \(self._codeBlocks.count)
        quoteBlock count: \(self._quoteBlocks.count)
        items count: \(self.allTokens.count)
        """
    }
}