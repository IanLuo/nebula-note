//
//  TextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Interface

public protocol OutlineTextStorageDelegate: class {
    func didSetCurrentHeading(newHeading: HeadingToken?, oldHeading: HeadingToken?)
    func didUpdateHeadings(newHeadings:[HeadingToken], oldHeadings: [HeadingToken])
    func didUpdateCurrentTokens(_ tokens: [Token])
}

/// 提供渲染的对象，如 attachment, checkbox 等
public protocol OutlineTextStorageDataSource: class {
    // TODO: outline text storage data source
}

public class OutlineTextStorage: TextStorage {
    public var parser: OutlineParser!
    
    private var _attachmentManager: AttachmentManager!
    
    public convenience init(attachmentManager: AttachmentManager) {
        self.init()
        self._attachmentManager = attachmentManager
    }
    
    public override var string: String {
        set { super.replaceCharacters(in: NSRange(location: 0, length: self.string.nsstring.length), with: newValue) }
        get { return super.string }
    }
    
    public weak var outlineDelegate: OutlineTextStorageDelegate?
    
    /// 用于 cache 已经找到的 heading
    private var _savedHeadings: [HeadingToken] = []
    // cache parsed code block border line
    private var _codeBlocks: [BlockToken] = []
    // cache parsed quote block border line
    private var _quoteBlocks: [BlockToken] = []
    
    // refering to current heading, when use change selection, this value changes
    public weak var currentHeading: HeadingToken?
    
    public var cursorLocation: Int = 0 {
        didSet {
            self.currentTokens = self.token(at: cursorLocation)
        }
    }
    
    public var currentTokens: [Token] = []
    
    /// 当前的解析范围，需要进行解析的字符串范围，用于对 item，索引 等缓存数据进行重新组织
    public var currentParseRange: NSRange?
    // MARK: - Selection highlight
        {
            didSet {
                if let _ = oldValue {
                    self.addAttribute(NSAttributedString.Key.backgroundColor, value: InterfaceTheme.Color.background1, range: NSRange(location: 0, length: self.string.nsstring.length))
                }
            }
        }
    
    // return the references of saved heading token
    public var headingTokens: [HeadingToken] {
        return self._savedHeadings
    }
    
    public var codeBlocks: [BlockBeginToken] {
        return self._pairedCodeBlocks
    }
    
    public var quoteBlocks: [BlockBeginToken] {
        return self._pairedQuoteBlocks
    }

    /// 所有解析获得的 token, 对应当前的文档结构解析状态
    public var allTokens: [Token] = []
    
    public var allTokenText: [String] {
        return self.allTokens.map {
            self.string.nsstring.substring(with: $0.range)
        }
    }
    
    public func lineRange(at location: Int) -> NSRange {
        return (self.string as NSString).lineRange(for: NSRange(location: location, length: 0))
    }
    
    public func lineStart(at location: Int) -> Int {
        return self.lineRange(at: location).location
    }
    
    public func lineEnd(at location: Int) -> Int {
        return self.lineRange(at: location).upperBound
    }
    
    public func substring(_ range: NSRange) -> String {
        return self.string.nsstring.substring(with: range)
    }
    
    // 用于解析过程中临时数据处理, only useful during parsing, 在开始解析的时候重置
    private var _tempParsingTokenResult: [Token] = []
    // 某些范围要忽略掉文字的样式，比如 link 内的文字样式, only usefule during parsing
    private var _ignoreTextMarkRanges: [NSRange] = []
}

// MARK: - Update Attributes
extension OutlineTextStorage: ContentUpdatingProtocol {
    public func performContentUpdate(_ string: String!, range: NSRange, delta: Int, action: NSTextStorage.EditActions) {

        guard action != .editedAttributes else { return } // 如果是修改属性，则不进行解析
//        guard self.string.nsstring.length > 0 else { return }

        // 如果是删除操作，直接删除已删除的部分的 token
        if delta < 0 {
            let deletionRange = NSRange(location: range.upperBound, length: -delta)
            _ = self._remove(in: deletionRange, from: &self.allTokens)
            _ = self._remove(in: deletionRange, from: &self._savedHeadings)
            _ = self._remove(in: deletionRange, from: &self._codeBlocks)
            _ = self._remove(in: deletionRange, from: &self._quoteBlocks)
        }
        
        // 更新 item 偏移
        self.updateTokenRangeOffset(delta: delta, from: range.location)

        // 调整需要解析的字符串范围
        self.currentParseRange = self._adjustParseRange(range)
        
        guard let currentParseRange = self.currentParseRange else { return }
        
        guard currentParseRange.length > 0 else { return }
        
        // 清空解析范围内已有的 attributes
        self.setAttributes(nil, range:  currentParseRange)
        
        // 解析文字，添加样式
        self.parser.parse(str: self.string,
                     range: currentParseRange)

        // 更新当前状态缓存
        self.updateCurrentInfo(at: editedRange.location)
        
        // 设置文字默认样式
        self.addAttributes(OutlineTheme.paragraphStyle.attributes,
                           range: self.currentParseRange!)
        
        self._tempParsingTokenResult.forEach {
            if $0.range.intersection(currentParseRange) != nil {
                $0.renderDecoration(textStorage: self)
            }
        }
        
        // 更新段落缩进样式
        (self.string as NSString).enumerateSubstrings(in: currentParseRange, options: NSString.EnumerationOptions.byLines) { [unowned self] (string, range, enclosedRange, stop) in
            if let heading = self.heading(contains: range.location), heading.paragraphRange.intersection(range) != nil {
                for sub in self.subheadings(of: heading) {
                    self.setParagraphIndent(heading: sub, for: heading.paragraphRange)
                }
                
                self.setParagraphIndent(heading: heading, for: heading.paragraphRange)
            }
        }
        
        // -> DEBUG
        // 解析范围提示
        #if DEBUG
        if CommandLine.arguments.contains("SHOW_EDITING_RANGE") {
            self.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.gray.withAlphaComponent(0.5)], range: currentParseRange)
        }
        // 添加 token 提示
        if CommandLine.arguments.contains("SHOW_PARSING_TOKEN_RANGE") {
            self._tempParsingTokenResult.forEach { token in
                self.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow.withAlphaComponent(0.3), range: token.range)
            }
        }
        // 所有 token 提示
        if CommandLine.arguments.contains("SHOW_ALL_TOKEN_RANGE") {
            self.allTokens.forEach { token in
                self.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.green.withAlphaComponent(0.3), range: token.range)
            }
        }
        #endif
        // <- DEBUG
    }
}

// MARK: -
extension OutlineTextStorage {
    /// 找到对应位置之后的第一个 token
    public func token(at location: Int) -> [Token] {
        let isFromStart = self.string.nsstring.length / 2 > location // diceide from which end to search
        var isHitBefore = false // if hit before, then then dosen't more, stop search
        var tokensFound: [Token] = []
        
        let allTokens = isFromStart ? self.allTokens : self.allTokens.reversed()
        
        for token in allTokens {
            if token.range.contains(location) || token.range.upperBound == location {
                isHitBefore = true
                tokensFound.append(token)
            } else {
                if isHitBefore {
                    break
                }
            }
        }
        
        return tokensFound
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
    
    public func updateTokenRangeOffset(delta: Int, from location: Int) {
        for token in self.allTokens {
            if token.tokenRange.lowerBound >= location {
                token.offset(delta)
            }
        }
    }
    
    // 查找最外层层的 heading
    public var topLevelHeadings: [HeadingToken] {
        var headings: [HeadingToken] = []
        
        for heading in self.headingTokens {
            if let last = headings.last {
                if heading.level <= last.level {
                    headings.append(heading)
                }
            } else {
                headings.append(heading)
            }
        }
        
        return headings
    }
    
    public func heading(contains location: Int) -> HeadingToken? {
        guard location <= self.string.nsstring.length else { return nil }
        
        for heading in self.headingTokens.reversed() {
            if location >= heading.range.location {
                return heading
            }
        }
        
        return nil
    }
    
    public func subheadings(of heading: HeadingToken) -> [HeadingToken] {
        var subheadings: [HeadingToken] = []
        var mark: Bool = false // mark is the current heading is found
        
        for h in self.headingTokens {
            if heading.identifier == h.identifier
              && !mark {
                mark = true
            } else if mark {
                if h.level > heading.level {
                    subheadings.append(h)
                } else {
                    break
                }
            }
        }
        
        return subheadings
    }
    
    public func nextHeading(of heading: HeadingToken) -> HeadingToken? {
        var mark: Bool = false // mark is the current heading is found
        
        for h in self.headingTokens {
            if heading.identifier == h.identifier
                && !mark {
                mark = true
            } else if mark {
                return h
            }
        }
        
        return nil
    }
    
    
    /// 计算 heading 所在的内容长度(包含 heading)
    public func parangraphsRange(at location: Int) -> NSRange {

        var range = NSRange(location: 0, length: self.string.nsstring.length)
        let reversedIndex: (Int) -> Int = { index in
            return self.headingTokens.count - index - 1
        }

        for (index, heading) in self.headingTokens.reversed().enumerated() {
            if location >= heading.range.location {
                range.location = heading.range.location
                let reversedIndex = reversedIndex(index)
                if reversedIndex + 1 < self.headingTokens.count {
                    range.length = self.headingTokens[reversedIndex + 1].range.location - heading.range.location
                } else {
                    range.length = self.string.nsstring.length - heading.range.location
                }
                
                break
            }
        }
        
        return range
    }
    
    /// 更新和当前位置相关的其他信息
    public func updateCurrentInfo(at location: Int) {
        
        guard self._savedHeadings.count > 0 else { return }
        
        let oldHeading = self.currentHeading
        self.currentHeading = self.heading(contains: location)
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
                if ignorRange.intersection(range) != nil {
                    markRanges.remove(at: count - index)
                    break
                }
            }
        }
        
        
        for dict in markRanges {
            for (key, range) in dict {
                
                self._addMarkTokenAttributes(range: range)
                
                let textMarkToken: TextMarkToken = TextMarkToken(range: range, name: key, data: dict)
                
                textMarkToken.decorationAttributesAction = { textStorage, token in
                    let contentRange = token.range.tail(range.length - 1).head(range.length - 2)
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.range.head(1))
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.range.tail(1))
                    
                    switch key {
                    case OutlineParser.Key.Element.TextMark.bold:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.bold.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.italic:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.italic.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.strikeThough:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.strikethrought.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.code:
                        var attributes = OutlineTheme.textMarkStyle.code.attributes
                        attributes[OutlineAttribute.button] = InterfaceTheme.Color.background3
                        textStorage.addAttributes(attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.underscore:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.underscore.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.verbatim:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.verbatim.attributes, range: contentRange)
                    default: break
                    }
                }
                
                self._tempParsingTokenResult.append(textMarkToken)
            }
        }
    }
    
    public func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {
        
        urlRanges.forEach { linkRangeData in
            
            guard let range = linkRangeData[OutlineParser.Key.Element.link] else { return }
            
            self._ignoreTextMarkRanges.append(contentsOf: urlRanges.map { $0[OutlineParser.Key.Element.link]! })
            
            let linkToken = LinkToken(range: range, name: OutlineParser.Key.Element.link, data: linkRangeData)
            self._tempParsingTokenResult.append(linkToken)
            
            linkToken.decorationAttributesAction = { textStorage, token in
                textStorage.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueDefault, range: token.range)
                
                if let titleRange = token.range(for: OutlineParser.Key.Element.Link.title),
                    let urlRange = token.range(for: OutlineParser.Key.Element.Link.url) {
                    // 添加自定义属性，值为解析的链接结构
                    textStorage.addAttributes([OutlineAttribute.hidden: 0, // 不隐藏
                        NSAttributedString.Key.foregroundColor: OutlineTheme.linkStyle.color,
                        NSAttributedString.Key.font: OutlineTheme.linkStyle.font,
                        OutlineAttribute.Link.title: [OutlineParser.Key.Element.Link.title: text.nsstring.substring(with: titleRange),
                                                      OutlineParser.Key.Element.Link.url: text.nsstring.substring(with: urlRange)]],
                                              range: titleRange)
                    
                    let hiddenRange = urlRange.moveLeftBound(by: 1)
                    let attachmentRange = urlRange.head(1)
                    
                    textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                               OutlineAttribute.showAttachment: OutlineAttribute.Link.url],
                                              range: attachmentRange)
                    
                    textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueDefault],
                                              range: hiddenRange)
                }
            }
        }
    }
    
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        attachmentRanges.forEach { rangeData in
            
            
            let attachmentToken = AttachmentToken(range: rangeData[OutlineParser.Key.Node.attachment]!, name: OutlineParser.Key.Node.attachment, data: rangeData)
            self._tempParsingTokenResult.append(attachmentToken)
            self._ignoreTextMarkRanges.append(attachmentToken.range)
            
            attachmentToken.decorationAttributesAction = { textStorage, token in
                
                guard let attachmentRange = token.range(for: OutlineParser.Key.Node.attachment) else { return }
                guard let typeRange = token.range(for: OutlineParser.Key.Element.Attachment.type) else { return }
                guard let valueRange = token.range(for: OutlineParser.Key.Element.Attachment.value) else { return }
                
                let type = text.nsstring.substring(with: typeRange)
                let value = text.nsstring.substring(with: valueRange)
                
                var attachment: RenderAttachment!
                if let a = super.cachedAttachment(with: value) as? RenderAttachment {
                    attachment = a
                } else {
                    attachment = RenderAttachment(type: type, value: value, manager: self._attachmentManager)
                }
                
                textStorage.addAttributes([OutlineAttribute.Attachment.type: type,
                                           OutlineAttribute.Attachment.value: value],
                                          range: attachmentRange)
                textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment],
                                          range: attachmentRange.head(1))
                textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueDefault],
                                          range: attachmentRange.tail(attachmentRange.length - 1))
                
                if let attachment = attachment {
                    if super.cachedAttachment(with: value) == nil {
                        super.add(attachment, for: value)
                    }
                    
                    textStorage.addAttributes([OutlineAttribute.showAttachment: value],
                                       range: attachmentRange.head(1))
                    
                    attachment.didLoadImage = { [weak self] in
                        self?.layoutManagers.first?.invalidateLayout(forCharacterRange: attachmentRange.head(1), actualCharacterRange: nil)
                        self?.layoutManagers.first?.invalidateDisplay(forCharacterRange: attachmentRange.head(1))
                    }
                } else {
                    textStorage.addAttributes([OutlineAttribute.showAttachment: OutlineAttribute.Attachment.unavailable],
                                       range: attachmentRange.head(1))
                }
            }
            
        }
    }

    public func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {
        
        checkboxRanges.forEach { rangeData in
            
            guard let checkboxRange = rangeData[OutlineParser.Key.Node.checkbox] else { return }
            
            let checkboxToken = CheckboxToken(range: checkboxRange, name: OutlineParser.Key.Node.checkbox, data: rangeData)
            
            self._tempParsingTokenResult.append(checkboxToken)
            
            checkboxToken.decorationAttributesAction = { textStorage, token in
                
                if let checkboxRange = token.range(for: OutlineParser.Key.Node.checkbox) {
                    textStorage.addAttribute(OutlineAttribute.checkbox, value: textStorage.string.nsstring.substring(with: checkboxRange), range: checkboxRange)
                    
                    if let statusRange = token.range(for: OutlineParser.Key.Node.checkbox)  {
                        textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueDefault], range: checkboxRange.moveLeftBound(by: 1).moveRightBound(by: -1))
                        let status = textStorage.string.nsstring.substring(with: statusRange)
                        if status == OutlineParser.Values.Checkbox.checked {
                            textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                                       OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_ATTACHMENT_CHECKBOX_CHECKED], range: checkboxRange.head(1))
                        } else {
                            textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                                       OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_ATTACHMENT_CHECKBOX_UNCHECKED], range: checkboxRange.head(1))
                        }
                    }
                    
                }
            }
        }
    }
    
    public func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {
        
        orderedListRnages.forEach { list in
            guard let range = list[OutlineParser.Key.Node.ordedList] else { return }
            
            let orderedListToken = OrderedListToken(range: range, name: OutlineParser.Key.Node.ordedList, data: list)
            self._tempParsingTokenResult.append(orderedListToken)
            
            orderedListToken.decorationAttributesAction = { textStorage, token in
                textStorage.addAttribute(OutlineAttribute.OrderedList.range, value: 1, range: token.range(for: OutlineParser.Key.Node.ordedList)!)
                
                if let index = token.range(for: OutlineParser.Key.Element.OrderedList.prefix) {
                    textStorage.addAttributes([NSAttributedString.Key.font: OutlineTheme.orderdedListStyle.font,
                                        NSAttributedString.Key.foregroundColor: OutlineTheme.orderdedListStyle.color,
                                        OutlineAttribute.OrderedList.index: index], range: index)
                }
            }
            
        }
    }
    
    public func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {
        
        unOrderedListRnages.forEach { list in
            guard let listRange = list[OutlineParser.Key.Node.unordedList] else { return }
            
            let unorderedListToken = UnorderdListToken(range: listRange, name: OutlineParser.Key.Node.unordedList, data: list)
            
            self._tempParsingTokenResult.append(unorderedListToken)
            
            unorderedListToken.decorationAttributesAction = { textStorage, token in
                if let prefix = token.range(for: OutlineParser.Key.Element.UnorderedList.prefix) {
                    textStorage.addAttributes([NSAttributedString.Key.font: OutlineTheme.unorderdedListStyle.font,
                                        NSAttributedString.Key.foregroundColor: OutlineTheme.unorderdedListStyle.color], range: prefix)
                }
            }
            
        }
    }
    
    public func didFoundSeperator(text: String, seperatorRanges: [[String: NSRange]]) {
        
        seperatorRanges.forEach { range in
            
            guard let separatorRange = range[OutlineParser.Key.Node.seperator] else { return }
            
            let seperatorToken = SeparatorToken(range: separatorRange, name: OutlineParser.Key.Node.seperator, data: range)
            
            self._tempParsingTokenResult.append(seperatorToken)
            
            seperatorToken.decorationAttributesAction = { textStorage, token in
                if let seperatorRange = token.range(for: OutlineParser.Key.Node.seperator) {
                    textStorage.addAttributes([OutlineAttribute.hidden: 2,
                                        OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_SEPARATOR], range: seperatorRange)
                }
            }
            
        }
    }
    
    public func didFoundCodeBlockBegin(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let token = BlockBeginToken(data: rangeData, blockType: BlockType.sourceCode)
            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let token = token as? BlockBeginToken else { return }
                textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                
                if let contentRange = token.contentRange {
                    self.addAttributes(OutlineTheme.codeBlockStyle.attributes, range: contentRange)
                }
                
                textStorage.addAttributes([OutlineAttribute.Block.code: OutlineTheme.codeBlockStyle.backgroundColor], range: token.range)
            }
            
        }
    }
    
    public func didFoundCodeBlockEnd(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let token = BlockEndToken(data: rangeData, blockType: BlockType.sourceCode)
            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let range = token.range(for: OutlineParser.Key.Node.codeBlockEnd) else { return }
                
                textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range)
            }
            
        }
    }
    
    public func didFoundQuoteBlockBegin(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let token = BlockBeginToken(data: rangeData, blockType: BlockType.quote)
            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let token = token as? BlockBeginToken else { return }
                
                if let contentRange = token.contentRange {
                    self.addAttributes(OutlineTheme.quoteBlockStyle.attributes, range: contentRange)
                }
                
                textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                
                textStorage.addAttributes([OutlineAttribute.Block.quote: OutlineTheme.quoteBlockStyle.backgroundColor], range: token.range)
            }
            
        }
    }
    
    public func didFoundQuoteBlockEnd(text: String, ranges: [[String : NSRange]]) {

        ranges.forEach { quoteRange in
            
            let token = BlockEndToken(data: quoteRange, blockType: BlockType.quote)
            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let token = token as? BlockEndToken else { return }
                
                textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                
            }
        }
    }
    
    public func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {
        headingDataRanges.forEach { headingData in
            let token = HeadingToken(data: headingData)
            token.outlineTextStorage = self

            self._tempParsingTokenResult.append(token)
            self._ignoreTextMarkRanges.append(token.levelRange)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let headingRange = token.range(for: OutlineParser.Key.Node.heading) else { return }
                textStorage.addAttributes(OutlineTheme.headingStyle(level: token.range(for: OutlineParser.Key.Element.Heading.level)?.length ?? 1).attributes, range: headingRange)
                
                textStorage.addAttribute(OutlineAttribute.Heading.content, value: 1, range: headingRange)
                
                if let levelRange = token.range(for: OutlineParser.Key.Element.Heading.level) {
                    textStorage.addAttribute(OutlineAttribute.Heading.level, value: 1, range: levelRange)
                }
                
                if let tagsRange = token.range(for: OutlineParser.Key.Element.Heading.tags) {
                    textStorage.addAttribute(OutlineAttribute.Heading.tags, value: textStorage.string.nsstring.substring(with: tagsRange).components(separatedBy: ":").filter { $0.count > 0 }, range: tagsRange)
                    textStorage._addButtonAttributes(range: tagsRange, color: OutlineTheme.tagStyle.buttonColor)
                    textStorage.addAttributes(OutlineTheme.tagStyle.textStyle.attributes, range: tagsRange)
                }
                
                if let priorityRange = token.range(for: OutlineParser.Key.Element.Heading.priority) {
                    let priorityText = textStorage.string.nsstring.substring(with: priorityRange)
                    textStorage.addAttribute(OutlineAttribute.Heading.priority, value: priorityText, range: priorityRange)
                    let priorityStyle = OutlineTheme.priorityStyle(priorityText)
                    textStorage._addButtonAttributes(range: priorityRange, color: priorityStyle.buttonColor)
                    textStorage.addAttributes(priorityStyle.textStyle.attributes, range: priorityRange)
                }
                
                if let planningRange = token.range(for: OutlineParser.Key.Element.Heading.planning) {
                    
                    let planningString = textStorage.string.nsstring.substring(with: planningRange)
                    
                    textStorage.addAttributes([OutlineAttribute.Heading.planning: planningString], range: planningRange)
                    
                    let planningStyle = OutlineTheme.planningStyle(isFinished: SettingsAccessor.shared.finishedPlanning.contains(planningString))
                    textStorage._addButtonAttributes(range: planningRange, color: planningStyle.buttonColor)
                    
                    textStorage.addAttributes(planningStyle.textStyle.attributes, range: planningRange)
                }
                
                textStorage.addHeadingFoldingStatus(heading: token as! HeadingToken)
            }
            
        }
    }
    
    public func didFoundDateAndTime(text: String, rangesData: [[String: NSRange]]) {
        
        for data in rangesData {
            guard let range = data[OutlineParser.Key.Element.dateAndTIme] else { return }
            
            let dateAndTimeToken = DateAndTimeToken(range: range, name: OutlineParser.Key.Element.dateAndTIme, data: data)
            self._tempParsingTokenResult.append(dateAndTimeToken)
            
            dateAndTimeToken.decorationAttributesAction = { textStorage, token in
                guard let range = token.range(for: OutlineParser.Key.Element.dateAndTIme) else { return }
                
                let dataAndTimeString = textStorage.substring(range)
                let dateAndTime = DateAndTimeType(dataAndTimeString)
                let datesFromToday = dateAndTime?.date.daysFrom(Date()) ?? 4 // 默认为 4 天, normal 颜色
                let dateAndTimeStyle = OutlineTheme.dateAndTimeStyle(datesFromToday: datesFromToday)
                textStorage.addAttributes([OutlineAttribute.dateAndTime: dataAndTimeString], range: range)
                textStorage.addAttributes(dateAndTimeStyle.textStyle.attributes, range: range)
                textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range.head(1))
                textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range.tail(1))
            }
        }
    }
    
    public func didStartParsing(text: String) {
        self._tempParsingTokenResult = []
        self._ignoreTextMarkRanges = []
    }
    
    public func didCompleteParsing(text: String) {
        self._updateTokens(new: self._tempParsingTokenResult)
        
        log.verbose(self.debugDescription)
    }
    
    private func _remove<T: Token>(in range: NSRange, from cache: inout [T]) -> [T] {
        var removedTokens: [T] = []
        for index in self._findIntersectionTokenIndex(in: range, tokens: cache).reversed() {
            let removed = cache.remove(at: index)
            removedTokens.append(removed)
            log.info("delete token: \(removed)")
        }
        return removedTokens
    }
    
    private func _insert<T: Token>(tokens: [T], into: inout [T]) {
        guard tokens.count > 0 else { return } // 如果是空数组进入，则直接返回
        
        let oldCount = into.count
        if into.count > 0 {
            let first = tokens[0] // 必然有超过一个对象在数组中
            
            // 待插入 tokens 处于文档最开始
            if first.range.location == 0 {
                into.insert(contentsOf: tokens, at: 0)
                
            // 待插入 tokens 处于文档最末尾
            } else if let last = into.last, first.range.location >= last.range.location {
                into.append(contentsOf: tokens)
            } else {
                // 从尾部开始，往前查找 cache 的最前端插入 tokens 的位置
                var isInsertIntoMiddel: Bool = false
                for (index, token) in into.reversed().enumerated() {
                    if first.range.location >= token.range.location, index < into.count {
                        into.insert(contentsOf: tokens, at: min(into.count - 1, into.count - index))
                        isInsertIntoMiddel = true
                        break
                    }
                }
                
                if isInsertIntoMiddel == false {
                    // cache 中没有 tokens 之前的位置，添加到 cache 最前端
                    into.insert(contentsOf: tokens, at: 0)
                }
            }
            
            log.info("[item count changed] \(into.count - oldCount)")
        } else {
            into.append(contentsOf: tokens)
        }
    }
    
    /// 更新 items 中的数据
    private func _updateTokens(new tokens: [Token]) {
        guard let currentParseRange = self.currentParseRange else { return }
        
        var newTokens: [Token] = tokens

        // 对新的 token 进行排序
        newTokens.sort { (lhs: Token, rhs: Token) -> Bool in
            if lhs.range.location != rhs.range.location {
                return lhs.range.location < rhs.range.location
            } else {
                return lhs.range.length <= rhs.range.length
            }
        }
        
        let _ = self._remove(in: currentParseRange, from: &self.allTokens)
        self._insert(tokens: newTokens, into: &self.allTokens)
        
        // 更新 heading 缓存
        let newHeadings = newTokens.filter { $0 is HeadingToken }.map { $0 as! HeadingToken }
        let removedHeadintToken = self._remove(in: currentParseRange, from: &self._savedHeadings)
        self._insert(tokens: newHeadings, into: &self._savedHeadings)
        
        if removedHeadintToken.count > 0 || newHeadings.count > 0 {
            self.outlineDelegate?.didUpdateHeadings(newHeadings: newHeadings,
                                                    oldHeadings: removedHeadintToken)
        }
        
        // 更新 code block 缓存
        let newCodeBlocks = newTokens.filter {
            if let t = $0 as? BlockToken, t.blockType == .sourceCode {
                return true
            } else {
                return false
            }
        }
        .map { $0 as! BlockToken }
        
        let removedCodeBlockToken = self._remove(in: currentParseRange, from: &self._codeBlocks)
        self._insert(tokens: newCodeBlocks, into: &self._codeBlocks)
        
        if newCodeBlocks.count > 0 || removedCodeBlockToken.count > 0 {
            self._figureOutBlocks(&self._codeBlocks)
        }
        
        // 更新 quote block 缓存
        let newQuoteBlocks = newTokens.filter {
            if let t = $0 as? BlockToken, t.blockType == .quote {
                return true
            } else {
                return false
            }
        }
        .map { $0 as! BlockToken }
        
        let removedQuoteBlockToken = self._remove(in: currentParseRange, from: &self._quoteBlocks)
        self._insert(tokens: newQuoteBlocks, into: &self._quoteBlocks)
        
        if newQuoteBlocks.count > 0 || removedQuoteBlockToken.count > 0 {
            self._figureOutBlocks(&self._quoteBlocks)
        }
    }
    
    // MARK: - utils
    
    public func isHeadingFolded(heading: HeadingToken) -> Bool {
        if heading.contentRange != nil {
            if let foldingAttribute = self.attribute(OutlineAttribute.showAttachment, at: heading.levelRange.location, effectiveRange: nil) as? String {
                return foldingAttribute == OutlineAttribute.Heading.foldingFolded.rawValue
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public func addHeadingFoldingStatus(heading: HeadingToken) {
        if isHeadingFolded(heading: heading) {
            self.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingFolded, range: heading.levelRange)
        } else {
            self.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingUnfolded, range: heading.levelRange)
        }
        self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueWithAttachment, range: heading.levelRange.head(1))
        self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueDefault, range: heading.levelRange.tail(heading.levelRange.length - 1))
    }
    
    private func _addStylesForCodeBlock() {
        guard let currentRange = self.currentParseRange else { return }
        
        for blockBeginToken in self._pairedCodeBlocks {
            // find current block range
            if blockBeginToken.range.intersection(currentRange) != nil {
                if let contentRange = blockBeginToken.contentRange {
                    self.addAttributes(OutlineTheme.codeBlockStyle.attributes, range: contentRange)
                }
            }
        }
    }
    
    // make internal begin-end connection to build paired block ranges
    private func _figureOutBlocks<T: BlockToken>(_ blocks: inout [T]) {
        for i in 0..<blocks.count {
            // condition 1. i 为 BlockBeginToken
            if let token = blocks[i] as? BlockBeginToken,
                // condition 2. i 不为最后一个 token
                blocks.count - 1 >= i + 1,
                 // condition 3. i + 1 为 BlockEndToken
                let endToken = blocks[i + 1] as? BlockEndToken {
                token.endToken = endToken
                
                endToken.beginToken = token
            }
        }
    }
    
    /// find pared code blocks, only return begin token, the end token is refered by begin token(weakly)
    private var _pairedCodeBlocks: [BlockBeginToken] {
        return self._codeBlocks.filter {
            if let begin = $0 as? BlockBeginToken {
                return begin.endToken != nil
            } else {
                return false
            }
            }.map { $0 as! BlockBeginToken }
    }
    
    /// find pared code blocks, only return begin token, the end token is refered by begin token(weakly)
    private var _pairedQuoteBlocks: [BlockBeginToken] {
        return self._quoteBlocks.filter {
            if let begin = $0 as? BlockBeginToken {
                return begin.endToken != nil
            } else {
                return false
            }
        }.map { $0 as! BlockBeginToken }
    }
    
    private func _findIntersectionTokenIndex(in range: NSRange, tokens: [Token]) -> [Int] {
        var indexes: [Int] = []
        for (index, token) in tokens.enumerated() {
            if token.tokenRange.intersection(range) != nil || token.tokenRange.upperBound == range.location
            {
                indexes.append(index)
            }
        }
        return indexes
    }
    
    private func _findNextTokenIndex(after range: NSRange, tokens: [Token]) -> Int {
        var indexToInserNewHeadings: Int = max(0, tokens.count - 1)
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
    
    /// 如果第二个参数 range 为空，则为整个 heading 的 paragraph 添加缩进
    public func setParagraphIndent(heading: HeadingToken, for range: NSRange? = nil) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = CGFloat(heading.level * 20 + 4) // FIXME: 设置 indent 的宽度
        paragraphStyle.headIndent = paragraphStyle.firstLineHeadIndent
        
        let applyingRange = range ?? heading.paragraphRange
        
        (self.string as NSString)
            .enumerateSubstrings(
                in: applyingRange,
                options: .byLines
            ) { (_, range, inclosingRange, stop) in
                // 第一行缩进比正文少一个 level
                if range.location == heading.range.location {
                    let firstLine = NSMutableParagraphStyle()
                    firstLine.firstLineHeadIndent = CGFloat((heading.level - 1) * 20)
                    firstLine.headIndent = paragraphStyle.firstLineHeadIndent
                    self.addAttributes([NSAttributedString.Key.paragraphStyle: firstLine], range: inclosingRange)
                } else {
                    self.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: inclosingRange)
                }
        }
    }
    
    internal func _adjustParseRange(_ range: NSRange) -> NSRange {
        var newRange = range
        
        let line1Start = (string as NSString).lineRange(for: NSRange(location: newRange.location, length: 0)).location
        let line2End = (string as NSString).lineRange(for: NSRange(location: max(newRange.location, newRange.upperBound - 1), length: 0)).upperBound
        
        newRange = NSRange(location: line1Start, length: line2End - line1Start)
        
        // 如果范围在某个 item 内，并且小于这个 item 原来的范围，则扩大至这个 item 原来的范围
        for item in self.codeBlocks {
            if item.range.intersection(newRange) != nil || newRange.location == item.range.upperBound {
                newRange = item.range.union(newRange)
                break
            }
        }
        
        for item in self.quoteBlocks {
            if item.range.intersection(newRange) != nil || newRange.location == item.range.upperBound {
                newRange = item.range.union(newRange)
                break
            }
        }
        
        if newRange.upperBound >= self.string.nsstring.length {
            newRange = NSRange(location: newRange.location, length: self.string.nsstring.length - newRange.location)
        }
        
        if newRange.length < 0 {
            newRange = NSRange(location: newRange.location - newRange.location, length: -newRange.location)
        }
        
        if newRange.location < 0 {
            newRange = NSRange(location: 0, length: newRange.length - (-newRange.location))
        }
        
        if newRange.location >= self.string.nsstring.length {
            newRange = NSRange(location: max(0, self.string.nsstring.length - 1), length: 0)
        }
        
        // 不包含已经折叠的部分
        if let folded = self.foldedRange(at: newRange.location) {
            newRange = NSRange(location: folded.upperBound, length: max(0, newRange.upperBound - folded.upperBound))
        }
        
        return newRange
    }
    
    public func foldedRange(at location: Int) -> NSRange? {
        guard location < self.string.nsstring.length else { return nil }
        
        var folded: NSRange = NSRange(location: 0, length: 0)
        if let value = self.attribute(OutlineAttribute.tempHidden, at: location, effectiveRange: &folded) as? NSNumber,
            value == OutlineAttribute.hiddenValueFolded {
            return folded
        } else {
            return nil
        }
    }
    
    
    private func _addButtonAttributes(range: NSRange, color: UIColor) {
        self.addAttributes([OutlineAttribute.button: color], range: range)
        self.addAttribute(OutlineAttribute.buttonBorder, value: 1, range: range.head(1))
        self.addAttribute(OutlineAttribute.buttonBorder, value: 2, range: range.tail(1))
    }
    
    private func _addMarkTokenAttributes(range: NSRange) {
        self.addAttributes(OutlineTheme.markStyle.attributes, range: range.head(1))
        
        self.addAttributes(OutlineTheme.markStyle.attributes, range: range.tail(1))
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
            && !self._checkShouldContinueExpand(buf: &characterBuf, next: string.nsstring.substring(with: NSRange(location: extendedRange.location - 1, length: 1)), lineCount: lineCount) {
                extendedRange = NSRange(location: extendedRange.location - 1, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
    
    internal func _expandFoward(string: String, lineCount: Int) -> NSRange {
        var extendedRange = self
        var characterBuf: String = ""
        
        while extendedRange.upperBound < string.nsstring.length - 1
            && !self._checkShouldContinueExpand(buf: &characterBuf, next: string.nsstring.substring(with: NSRange(location: extendedRange.upperBound, length: 1)), lineCount: lineCount) {
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
        length: \(self.string.nsstring.length)
        heading count: \(self._savedHeadings.count)
        codeBlock count: \(self._codeBlocks.count)
        quoteBlock count: \(self._quoteBlocks.count)
        items count: \(self.allTokens.count)
        """
    }
}
