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
                    self.addAttribute(NSAttributedString.Key.backgroundColor, value: InterfaceTheme.Color.background1, range: NSRange(location: 0, length: self.string.count))
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

    /// 所有解析获得的 token, 对应当前的文档结构解析状态
    public var allTokens: [Token] = []
    
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
        return self.string.substring(range)
    }
    
    // 用于解析过程中临时数据处理, only useful during parsing, 在开始解析的时候重置
    private var _tempParsingTokenResult: [Token] = []
    // 某些范围要忽略掉文字的样式，比如 link 内的文字样式, only usefule during parsing
    private var _ignoreTextMarkRanges: [NSRange] = []
}

// MARK: - Update Attributes
extension OutlineTextStorage: ContentUpdatingProtocol {
    public func performContentUpdate(_ string: String!, range: NSRange, delta: Int, action: NSTextStorage.EditActions) {

        guard self.editedMask != .editedAttributes else { return } // 如果是修改属性，则不进行解析
        guard self.string.count > 0 else { return }

        // 更新 item 索引缓存
        self.updateTokenRangeOffset(delta: self.changeInLength, from: editedRange.location)

        // 调整需要解析的字符串范围
        self.currentParseRange = self._adjustParseRange(editedRange)
        
        guard let currentParseRange = self.currentParseRange else { return }
        
        // 清空解析范围内已有的 attributes
        self.setAttributes(nil, range:  currentParseRange)
        
        // 解析文字，添加样式
        self.parser.parse(str: self.string,
                     range: currentParseRange)

        // -> DEBUG
        // 解析范围提示
//        self.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.gray.withAlphaComponent(0.5)], range: currentParseRange)
//        // 添加 token 提示
//        self._tempParsingTokenResult.forEach { token in
//            self.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow.withAlphaComponent(0.3), range: token.range)
//        }
        // <- DEBUG

        // 更新当前状态缓存
        self.updateCurrentInfo(at: editedRange.location)
        
        // 设置文字默认样式
        self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive,
                            NSAttributedString.Key.font: InterfaceTheme.Font.body],
                           range: self.currentParseRange!)
        
        self._tempParsingTokenResult.forEach {
            if $0.range.intersection(currentParseRange) != nil {
                $0.renderDecoration(textStorage: self)
            }
        }
        
        // 更新段落缩进样式
        (self.string as NSString).enumerateSubstrings(in: currentParseRange, options: NSString.EnumerationOptions.byLines) { [unowned self] (string, range, enclosedRange, stop) in
            if let heading = self.heading(contains: range.location) {
                self.setParagraphIndent(heading: heading, for: enclosedRange)
            }
        }
        
    }
}

// MARK: -
extension OutlineTextStorage {
    /// 找到对应位置之后的第一个 token
    public func token(at location: Int) -> [Token] {
        let isFromStart = self.string.count / 2 > location // diceide from which end to search
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
            if token.range.lowerBound >= location {
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
        guard location <= self.string.count else { return nil }
        
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

        var range = NSRange(location: 0, length: self.string.count)
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
                    range.length = self.string.count - heading.range.location
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
                if ignorRange.location <= range.location && ignorRange.upperBound >= range.upperBound {
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
                    textStorage.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                               NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: token.range.head(1))
                    textStorage.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                               NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: token.range.tail(1))
                    
                    switch key {
                    case OutlineParser.Key.Element.TextMark.bold:
                        textStorage.addAttributes(OutlineTheme.Attributes.TextMark.bold, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.italic:
                        textStorage.addAttributes(OutlineTheme.Attributes.TextMark.italic, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.strikeThough:
                        textStorage.addAttributes(OutlineTheme.Attributes.TextMark.strikeThough, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.code:
                        textStorage.addAttributes(OutlineTheme.Attributes.TextMark.code, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.underscore:
                        textStorage.addAttributes(OutlineTheme.Attributes.TextMark.underscore, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.verbatim:
                        textStorage.addAttributes(OutlineTheme.Attributes.TextMark.verbatim, range: contentRange)
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
                        NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.spotlight,
                        NSAttributedString.Key.font: InterfaceTheme.Font.body,
                        OutlineAttribute.Link.title: [OutlineParser.Key.Element.Link.title: text.substring(titleRange),
                                                      OutlineParser.Key.Element.Link.url: text.substring(urlRange)]],
                                              range: titleRange)
                    
                    textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                               OutlineAttribute.showAttachment: OutlineAttribute.Link.url],
                                              range: urlRange)
                }
            }
        }
    }
    
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        attachmentRanges.forEach { rangeData in
            
            
            let attachmentToken = AttachmentToken(range: rangeData[OutlineParser.Key.Node.attachment]!, name: OutlineParser.Key.Node.attachment, data: rangeData)
            self._tempParsingTokenResult.append(attachmentToken)
            
            attachmentToken.decorationAttributesAction = { textStorage, token in
                
                guard let attachmentRange = token.range(for: OutlineParser.Key.Node.attachment) else { return }
                guard let typeRange = token.range(for: OutlineParser.Key.Element.Attachment.type) else { return }
                guard let valueRange = token.range(for: OutlineParser.Key.Element.Attachment.value) else { return }
                
                let type = text.substring(typeRange)
                let value = text.substring(valueRange)
                let attachment = RenderAttachment(type: type, value: value, manager: self._attachmentManager)
                
                textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment],
                                   range: attachmentRange)
                
                if let attachment = attachment {
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
    }

    public func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {
        
        checkboxRanges.forEach { rangeData in
            
            guard let checkboxRange = rangeData[OutlineParser.Key.Node.checkbox] else { return }
            
            let checkboxToken = CheckboxToken(range: checkboxRange, name: OutlineParser.Key.Node.checkbox, data: rangeData)
            
            self._tempParsingTokenResult.append(checkboxToken)
            
            checkboxToken.decorationAttributesAction = { textStorage, token in
                
                if let checkboxRange = token.range(for: OutlineParser.Key.Node.checkbox) {
                    textStorage.addAttribute(OutlineAttribute.checkbox, value: textStorage.string.substring(checkboxRange), range: checkboxRange)
                    textStorage.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.spotlight,
                                               NSAttributedString.Key.font: InterfaceTheme.Font.title], range: checkboxRange.moveLeftBound(by: 1))
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
                    textStorage.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.title,
                                        NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
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
                    textStorage.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.title,
                                        NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive], range: prefix)
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
                guard let range = token.range(for: OutlineParser.Key.Node.codeBlockBegin) else { return }
                
                textStorage.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: range)
                
                textStorage._addStylesForQuoteBlock()
            }
            
        }
    }
    
    public func didFoundCodeBlockEnd(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let token = BlockEndToken(data: rangeData, blockType: BlockType.sourceCode)
            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let range = token.range(for: OutlineParser.Key.Node.codeBlockEnd) else { return }
                
                textStorage.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: range)
            }
            
        }
    }
    
    public func didFoundQuoteBlockBegin(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let token = BlockBeginToken(data: rangeData, blockType: BlockType.quote)
            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let range = token.range(for: OutlineParser.Key.Node.quoteBlockBegin) else { return }
                
                textStorage.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: range)
                
                textStorage._addStylesForQuoteBlock()
            }
            
        }
    }
    
    public func didFoundQuoteBlockEnd(text: String, ranges: [[String : NSRange]]) {

        ranges.forEach { quoteRange in
            
            let token = BlockEndToken(data: quoteRange, blockType: BlockType.quote)
            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let range = token.range(for: OutlineParser.Key.Node.quoteBlockEnd) else { return }
                
                textStorage.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: range)
                
            }
        }
    }
    
    public func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {
        headingDataRanges.forEach { headingData in
            let token = HeadingToken(data: headingData)
            token.outlineTextStorage = self

            self._tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let headingRange = token.range(for: OutlineParser.Key.Node.heading) else { return }
                
                textStorage.addAttribute(NSAttributedString.Key.font, value: InterfaceTheme.Font.title, range: headingRange)
                textStorage.addAttribute(OutlineAttribute.Heading.content, value: 1, range: headingRange)
                
                if let levelRange = token.range(for: OutlineParser.Key.Element.Heading.level) {
                    textStorage.addAttribute(OutlineAttribute.Heading.level, value: 1, range: levelRange)
                }
                
                if let tagsRange = token.range(for: OutlineParser.Key.Element.Heading.tags) {
                    textStorage.addAttribute(OutlineAttribute.Heading.tags, value: textStorage.string.substring(tagsRange).components(separatedBy: ":").filter { $0.count > 0 }, range: tagsRange)
                    textStorage._addButtonAttributes(range: tagsRange, color: InterfaceTheme.Color.descriptive)
                    textStorage.addAttribute(NSAttributedString.Key.font, value: InterfaceTheme.Font.footnote, range: tagsRange)
                }
                
                if let priorityRange = token.range(for: OutlineParser.Key.Element.Heading.priority) {
                    textStorage.addAttribute(OutlineAttribute.Heading.priority, value: textStorage.string.substring(priorityRange), range: priorityRange)
                    textStorage._addButtonAttributes(range: priorityRange, color: InterfaceTheme.Color.descriptive)
                    textStorage.addAttribute(NSAttributedString.Key.font, value: InterfaceTheme.Font.footnote, range: priorityRange)
                }
                
                if let planningRange = token.range(for: OutlineParser.Key.Element.Heading.planning) {
                    textStorage.addAttributes([OutlineAttribute.Heading.planning: textStorage.string.substring(planningRange),
                                        NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive,
                                        NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: planningRange)
                    
                    let planningString = textStorage.string.substring(planningRange)
                    if SettingsAccessor.shared.finishedPlanning.contains(planningString) {
                        textStorage._addButtonAttributes(range: planningRange, color: InterfaceTheme.Color.spotlight)
                    } else {
                        textStorage._addButtonAttributes(range: planningRange, color: InterfaceTheme.Color.warning)
                    }
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
                
                textStorage._addButtonAttributes(range: range, color: InterfaceTheme.Color.descriptive)
                textStorage.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                                    OutlineAttribute.dateAndTime: textStorage.string.substring(range)], range: range)
            }
            
        }
    }
    
    public func didStartParsing(text: String) {
        self._tempParsingTokenResult = []
        self._ignoreTextMarkRanges = []
    }
    
    public func didCompleteParsing(text: String) {
        self._updateTokens(new: self._tempParsingTokenResult)
        
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
        var removedToken: [Token] = []
        if self.allTokens.count == 0 {
            self.allTokens.append(contentsOf: newTokens)
        } else {
            guard let currentParseRange = self.currentParseRange else { return }
            let oldCount = self.allTokens.count
            for index in self._findIntersectionTokenIndex(in: currentParseRange, tokens: self.allTokens).reversed() {
                removedToken.append(self.allTokens.remove(at: index))
            }
            
            // add new found items
            self.allTokens.insert(contentsOf: newTokens, at: self._findNextTokenIndex(after: currentParseRange, tokens: self.allTokens))
            log.info("[item count changed] \(self.allTokens.count - oldCount)")
        }
        
        let removedHeadings = removedToken.filter{ $0 is HeadingToken }.map { $0 as! HeadingToken }
        let cachedHeadingRemoveCount = self._savedHeadings.remove { s in removedHeadings.contains { $0.identifier == s.identifier } }
        let newHeadings = newTokens.filter { $0 is HeadingToken }.map { $0 as! HeadingToken }
        
        self._updateTokenCache(self._savedHeadings, with: newHeadings)
        
        if cachedHeadingRemoveCount > 0 || newHeadings.count > 0 {
            self.outlineDelegate?.didUpdateHeadings(newHeadings: newHeadings,
                                                    oldHeadings: removedToken.filter { $0 is HeadingToken }.map { $0 as! HeadingToken })
        }
        
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
        }
    }
    
    // MARK: - utils
    
    public func isHeadingFolded(heading: HeadingToken) -> Bool {
        if heading.contentRange.location < self.string.count {
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
        self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueWithAttachment, range: heading.levelRange)
    }
    
    private func _addStylesForCodeBlock() {
        guard let currentRange = self.currentParseRange else { return }
        
        for blockBeginToken in self._pairedCodeBlocks {
            // find current block range
            if blockBeginToken.range.intersection(currentRange) != nil {
                if let contentRange = blockBeginToken.contentRange {
                    self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.spotlight,
                                        NSAttributedString.Key.font: InterfaceTheme.Font.footnote], range: contentRange)
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
                    if let cachedToken = cache[i] {
                        if first.range.upperBound < cachedToken.range.location {
                            cache.insert(newTokens, at: i)
                            return
                        }
                    }
                }
                
                /// 如果没有找到合适的插入位置，添加到最后
                cache.append(contentsOf: newTokens)
            }
        }
    }
    
    private func _findIntersectionTokenIndex(in range: NSRange, tokens: [Token]) -> [Int] {
        var indexes: [Int] = []
        for (index, token) in tokens.enumerated() {
            if token.range.intersection(range) != nil || token.range.upperBound == range.location //|| token.range.location == range.upperBound
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
        paragraphStyle.firstLineHeadIndent = CGFloat(heading.level * 10) // FIXME: 设置 indent 的宽度
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
                    firstLine.firstLineHeadIndent = CGFloat((heading.level - 1) * 10) // FIXME: 设置 indent 的宽度
                    firstLine.headIndent = paragraphStyle.firstLineHeadIndent
                    self.addAttributes([NSAttributedString.Key.paragraphStyle: firstLine], range: inclosingRange)
                } else {
                    self.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: inclosingRange)
                }
        }
    }
    
    internal func _adjustParseRange(_ range: NSRange) -> NSRange {
        var paragraphStart = 0
        var paragraphEnd = 0
        var contentsEnd = 0
        
        var newRange = range
//        (string as NSString).getParagraphStart(&paragraphStart, end: &paragraphEnd, contentsEnd: &contentsEnd, for: newRange)
        
        let line1Start = (string as NSString).lineRange(for: NSRange(location: newRange.location, length: 0)).location
        let line2End = (string as NSString).lineRange(for: NSRange(location: newRange.upperBound - 1, length: 0)).upperBound
        
        newRange = NSRange(location: line1Start, length: line2End - line1Start)
        
        // 如果范围在某个 item 内，并且小于这个 item 原来的范围，则扩大至这个 item 原来的范围
        for item in self.allTokens {
            if item.range.intersection(newRange) != nil && item is BlockToken {
                newRange = item.range.union(newRange)
                break
            }
        }
        
        if newRange.upperBound >= self.string.count {
            newRange = NSRange(location: newRange.location, length: self.string.count - newRange.location)
        }
        
        if newRange.length < 0 {
            newRange = NSRange(location: newRange.location - newRange.location, length: -newRange.location)
        }
        
        if newRange.location < 0 {
            newRange = NSRange(location: 0, length: newRange.length - (-newRange.location))
        }
        
        return newRange
    }
    
    
    private func _addButtonAttributes(range: NSRange, color: UIColor) {
        self.addAttributes([OutlineAttribute.button: color], range: range)
        self.addAttribute(OutlineAttribute.buttonBorder, value: 1, range: range.head(1))
        self.addAttribute(OutlineAttribute.buttonBorder, value: 2, range: range.tail(1))
    }
    
    private func _addMarkTokenAttributes(range: NSRange) {
        self.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                            NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive], range: range.head(1))
        
        self.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                            NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive], range: range.tail(1))
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
