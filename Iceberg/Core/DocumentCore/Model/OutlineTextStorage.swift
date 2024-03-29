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
    func logs() -> DocumentLog?
    func markFoldingState(heading: HeadingToken, isFolded: Bool)
}

/// 提供渲染的对象，如 attachment, checkbox 等
public protocol OutlineTextStorageDataSource: class {
    // TODO: outline text storage data source
}

public class OutlineTextStorage: TextStorage {
    public var parser: OutlineParser!
    
    public var isReadingMode: Bool = false
    
    private var attachmentManager: AttachmentManager!
    
    public convenience init(attachmentManager: AttachmentManager) {
        self.init()
        self.attachmentManager = attachmentManager
    }
    
    public override var string: String {
        set { super.replaceCharacters(in: NSRange(location: 0, length: self.string.nsstring.length), with: newValue) }
        get { return super.string }
    }
    
    public weak var outlineDelegate: OutlineTextStorageDelegate?
    
    /// 用于 cache 已经找到的 heading
    private var _savedHeadings: [HeadingToken] = []
    // cache parsed block border line
    private var _blocks: [BlockToken] = []
    
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
//        {
//            didSet {
//                if let _ = oldValue {
//                    self.addAttribute(NSAttributedString.Key.backgroundColor, value: InterfaceTheme.Color.background1, range: NSRange(location: 0, length: self.string.nsstring.length))
//                }
//            }
//        }
    
    // return the references of saved heading token
    public var headingTokens: [HeadingToken] {
        return self._savedHeadings
    }
    
    public var blocks: [BlockBeginToken] {
        return self._pairedBlocks
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
    
    public func propertyContentForHeading(at location: Int) -> [String: String]? {
        if let drawer = self.propertyForHeading(at: location) {
            if let contentRange = drawer.contentRange {
                let drawerContent = self.substring(contentRange).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let pair = drawerContent.components(separatedBy: "\n")
                let matcher = try! NSRegularExpression(pattern: "^\\:(.*)\\:[\\t ]*(.*)$", options: [.anchorsMatchLines])
                
                return pair.reduce([:]) { result, next in
                    var result = result
                    if let matched = matcher.firstMatch(in: next, options: [], range: NSRange(location: 0, length: next.count)) {
                        let key = next.nsstring.substring(with: matched.range(at: 1))
                        let value = next.nsstring.substring(with: matched.range(at: 2))
                        result?[key] = value
                    }
                    return result
                }
            }
        }

        return nil
    }
    
    public func propertyForHeading(at location: Int) -> BlockToken? {
        for case let currentHeading in self.headingTokens where currentHeading.paragraphRange.contains(location) {
            for case let drawer in self.blocks where drawer.isPropertyDrawer && currentHeading.paragraphRange.contains(drawer.range.location) {
                return drawer
            }
        }
        
        return nil
    }
    
    public func heading(id: String) -> HeadingToken? {
        for case let heading in self.headingTokens where heading.identifier == id {
            return heading
        }

        	return nil
    }
    
    // 用于解析过程中临时数据处理, only useful during parsing, 在开始解析的时候重置
    private var tempParsingTokenResult: [Token] = []
    // 某些范围要忽略掉文字的样式，比如 link 内的文字样式, only usefule during parsing
    private var ignoreTextMarkRanges: [NSRange] = []
    // 目前有 quote 和 source code
    // 可以包含其他 token 的 token
    private var _embedableTokenRanges: [NSRange] = []
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
            _ = self._remove(in: deletionRange, from: &self._blocks)
        }
        
        // 更新 item 偏移
        self.updateTokenRangeOffset(delta: delta, from: range.location)

        // 调整需要解析的字符串范围
        self.currentParseRange = self._adjustParseRange(range)
        
        guard let currentParseRange = self.currentParseRange else { return }
        
        guard currentParseRange.upperBound <= self.string.count else { return }
        
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
                           range: currentParseRange)
        
        self.tempParsingTokenResult.forEach {
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
            self.tempParsingTokenResult.forEach { token in
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
    
    public func parentHeading(contains location: Int) -> HeadingToken? {
        if let headingToken = self.heading(contains: location) {
            guard headingToken.range.location  > 0 else { return nil }
            
            if let maybeParent = self.heading(contains: headingToken.range.location - 1) {
                if maybeParent.level < headingToken.level {
                    return maybeParent
                } else if maybeParent.level == headingToken.level { // find sibline's parent
                    return parentHeading(contains: maybeParent.range.location)
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    public func subheadings(of heading: HeadingToken) -> [HeadingToken] {
        var subheadings: [HeadingToken] = []
        var mark: Bool = false // mark is the current heading is found
        var firstSubHeadingLevel: Int? // the first subheading's level should be the sub heading's level, lower than than should be ignored, which should be long to the sub' sub heading
        
        for h in self.headingTokens {
            if heading.identifier == h.identifier
              && !mark {
                mark = true
            } else if mark {
                if h.level > heading.level {
                    if firstSubHeadingLevel == nil { firstSubHeadingLevel = h.level }
                    
                    guard h.level >= firstSubHeadingLevel! else { continue }
                        
                    subheadings.append(h)
                } else {
                    break
                }
            }
        }
        
        return subheadings
    }
    
    public func firstLevelSubheadings(of heading: HeadingToken) -> [HeadingToken] {
        var subheadings: [HeadingToken] = []
        var mark: Bool = false // mark is the current heading is found
        var firstSubHeadingLevel: Int? // the first subheading's level should be the sub heading's level, lower than than should be ignored, which should be long to the sub' sub heading
        
        for h in self.headingTokens {
            if heading.identifier == h.identifier
              && !mark {
                mark = true
            } else if mark {
                if h.level > heading.level {
                    if firstSubHeadingLevel == nil { firstSubHeadingLevel = h.level }
                    
                    guard h.level == firstSubHeadingLevel! else { continue }
                        
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
            
            for ignorRange in self.ignoreTextMarkRanges {
                if ignorRange.intersection(range) != nil {
                    markRanges.remove(at: count - index)
                    break
                }
            }
        }
        
        
        for dict in markRanges {
            for (key, range) in dict {
                
                // ignore when key is content, this part is looking for different font style key
                guard key != OutlineParser.Key.Element.TextMark.content else { continue }

                
                let textMarkToken: TextMarkToken = TextMarkToken(range: range, name: key, data: dict)
                
                self.checkMarkEmbeded(token: textMarkToken)
                
                textMarkToken.decorationAttributesAction = { [weak self] textStorage, token in
                    self?._addMarkTokenAttributes(range: token.range)
                    
                    let contentRange = token.range(for: OutlineParser.Key.Element.TextMark.content) ?? token.range
                    if textStorage.isReadingMode {
                        textStorage.addAttribute(OutlineAttribute.hidden, value: 1, range: token.range.head(1))
                        textStorage.addAttribute(OutlineAttribute.hidden, value: 1, range: token.range.tail(1))
                    } else {
                        textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.range.head(1))
                        textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.range.tail(1))
                    }
                    
                    switch key {
                    case OutlineParser.Key.Element.TextMark.bold:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.bold.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.italic:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.italic.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.strikeThough:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.strikethrought.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.highlight:
                        var attributes = OutlineTheme.textMarkStyle.highlight.attributes
                        attributes[OutlineAttribute.backgroundColor] = InterfaceTheme.Color.background3
                        textStorage.addAttributes(attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.underscore:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.underscore.attributes, range: contentRange)
                    case OutlineParser.Key.Element.TextMark.verbatim:
                        textStorage.addAttributes(OutlineTheme.textMarkStyle.verbatim.attributes, range: contentRange)
                    default: break
                    }
                }
                
                self.tempParsingTokenResult.append(textMarkToken)
            }
        }
    }
    
    public func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {
        
        urlRanges.forEach { linkRangeData in
            
            guard let range = linkRangeData[OutlineParser.Key.Element.link] else { return }
            
            self.ignoreTextMarkRanges.append(contentsOf: urlRanges.map { $0[OutlineParser.Key.Element.link]! })
            
            let linkToken = LinkToken(range: range, name: OutlineParser.Key.Element.link, data: linkRangeData)
            self.tempParsingTokenResult.append(linkToken)
            
            self.checkMarkEmbeded(token: linkToken)
            
            linkToken.decorationAttributesAction = { textStorage, token in
                textStorage.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueDefault, range: token.range)
                
                if let titleRange = token.range(for: OutlineParser.Key.Element.Link.title),
                    let urlRange = token.range(for: OutlineParser.Key.Element.Link.url) {
                    // 添加自定义属性，值为解析的链接结构
                    textStorage.addAttributes([OutlineAttribute.hidden: 0, // 不隐藏
                        NSAttributedString.Key.foregroundColor: OutlineTheme.linkStyle.color,
                        NSAttributedString.Key.font: OutlineTheme.linkStyle.font,
                        OutlineAttribute.Link.title: [OutlineParser.Key.Element.Link.title: textStorage.string.nsstring.substring(with: titleRange),
                                                      OutlineParser.Key.Element.Link.url: textStorage.string.nsstring.substring(with: urlRange)]],
                                              range: titleRange)
                    
                    let hiddenRange = urlRange.moveLeftBound(by: 1)
                    let attachmentRange = token.range.head(1)
                    
                    let attachment = (token as? LinkToken)?.isDocumentLink(textStorage: textStorage) ?? false ? OutlineAttribute.documentLink : OutlineAttribute.Link.url
                    textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                               OutlineAttribute.showAttachment: attachment],
                                              range: attachmentRange)
                    
                    textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueDefault],
                                              range: hiddenRange)
                }
            }
        }
    }
    
    public func didFoundRawHttpLink(text: String, urlRanges: [[String : NSRange]]) {
        urlRanges.forEach { linkRangeData in
            guard let range = linkRangeData[OutlineParser.Key.Element.link] else { return }
            
            self.ignoreTextMarkRanges.append(contentsOf: urlRanges.map { $0[OutlineParser.Key.Element.link]! })
            
            let linkToken = LinkToken(range: range, name: OutlineParser.Key.Element.link, data: linkRangeData)
            self.tempParsingTokenResult.append(linkToken)
            
            self.checkMarkEmbeded(token: linkToken)
            
            linkToken.decorationAttributesAction = { textStorage, token in
                let linkText = textStorage.string.nsstring.substring(with: token.range)
                textStorage.addAttributes([NSAttributedString.Key.foregroundColor: OutlineTheme.linkStyle.color,
                    NSAttributedString.Key.font: OutlineTheme.linkStyle.font,
                    OutlineAttribute.Link.title: [OutlineParser.Key.Element.Link.title: linkText,
                                                  OutlineParser.Key.Element.Link.url: linkText]],
                                          range: token.range)
            }
        }
    }
    
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        attachmentRanges.forEach { rangeData in
            
            
            let attachmentToken = AttachmentToken(range: rangeData[OutlineParser.Key.Node.attachment]!, name: OutlineParser.Key.Node.attachment, data: rangeData)
            self.tempParsingTokenResult.append(attachmentToken)
            self.ignoreTextMarkRanges.append(attachmentToken.range)
            
            self.checkMarkEmbeded(token: attachmentToken)
            
            attachmentToken.decorationAttributesAction = { textStorage, token in
                
                guard let attachmentRange = token.range(for: OutlineParser.Key.Node.attachment) else { return }
                guard let typeRange = token.range(for: OutlineParser.Key.Element.Attachment.type) else { return }
                guard let valueRange = token.range(for: OutlineParser.Key.Element.Attachment.value) else { return }
                
                let type = textStorage.string.nsstring.substring(with: typeRange)
                let value = textStorage.string.nsstring.substring(with: valueRange)
                
                var attachment: RenderAttachment!
                if let a = super.cachedAttachment(with: value) as? RenderAttachment {
                    attachment = a
                } else {
                    attachment = RenderAttachment(type: type, value: value, manager: self.attachmentManager)
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
                    
                    attachment.didLoadImage = { [weak self, weak textStorage] in
                        // make sure the attachment displays
                        if textStorage?.isFolded(location: attachmentRange.head(1).location) != true {
                            self?.layoutManagers.first?.invalidateLayout(forCharacterRange: attachmentRange.head(1), actualCharacterRange: nil)
                            self?.layoutManagers.first?.invalidateDisplay(forCharacterRange: attachmentRange.head(1))
                        }
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
            
            self.checkMarkEmbeded(token: checkboxToken)
            
            self.tempParsingTokenResult.append(checkboxToken)
            
            checkboxToken.decorationAttributesAction = { textStorage, token in
                
                if let checkboxToken = token as? CheckboxToken {
                    textStorage.addAttribute(OutlineAttribute.checkbox, value: textStorage.string.nsstring.substring(with: checkboxToken.status), range: checkboxToken.status)
                    textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueDefault], range: checkboxToken.status.moveLeftBound(by: 1).moveRightBound(by: -1))
                    let status = textStorage.string.nsstring.substring(with: checkboxToken.status)
                    if status == OutlineParser.Values.Checkbox.checked {
                        textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                                   OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_ATTACHMENT_CHECKBOX_CHECKED], range: checkboxToken.status.head(1))
                    } else {
                        textStorage.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment,
                                                   OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_ATTACHMENT_CHECKBOX_UNCHECKED], range: checkboxToken.status.head(1))
                    }
                    
                }
            }
        }
    }
    
    public func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {
        
        orderedListRnages.forEach { list in
            guard let range = list[OutlineParser.Key.Node.ordedList] else { return }
            
            let orderedListToken = OrderedListToken(range: range, name: OutlineParser.Key.Node.ordedList, data: list)
            self.tempParsingTokenResult.append(orderedListToken)
            
            self.checkMarkEmbeded(token: orderedListToken)
            
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
            
            self.tempParsingTokenResult.append(unorderedListToken)
            
            self.checkMarkEmbeded(token: unorderedListToken)
            
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
            
            self.checkMarkEmbeded(token: seperatorToken)
            
            self.tempParsingTokenResult.append(seperatorToken)
            
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
            self.tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                
                guard let token = token as? BlockBeginToken else { return }
                textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                
                if textStorage.isReadingMode {
                    textStorage.addAttribute(NSAttributedString.Key.foregroundColor, value: OutlineTheme.codeBlockStyle.backgroundColor, range: token.tokenRange)
                } else {
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                }
                
                textStorage.addAttributes([OutlineAttribute.Block.code: OutlineTheme.codeBlockStyle.backgroundColor], range: token.range)
                
                if let contentRange = token.contentRange {
                    self.addAttributes(OutlineTheme.codeBlockStyle.attributes, range: contentRange)
                }
                
            }
            
        }
    }
    
    public func didFoundCodeBlockEnd(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let token = BlockEndToken(data: rangeData, blockType: BlockType.sourceCode)
            self.tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                
                if textStorage.isReadingMode {
                    textStorage.addAttribute(NSAttributedString.Key.foregroundColor, value: OutlineTheme.codeBlockStyle.backgroundColor, range: token.tokenRange)
                } else {
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                }
                
            }
            
        }
    }
    
    public func didFoundQuoteBlockBegin(text: String, ranges: [[String : NSRange]]) {
        
        ranges.forEach { rangeData in
            
            let token = BlockBeginToken(data: rangeData, blockType: BlockType.quote)
            self.tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let token = token as? BlockBeginToken else { return }
                                
                if let contentRange = token.contentRange {
                    self.addAttributes(OutlineTheme.quoteBlockStyle.attributes, range: contentRange)
                }
                
                if textStorage.isReadingMode {
                    textStorage.addAttribute(NSAttributedString.Key.foregroundColor, value: OutlineTheme.quoteBlockStyle.backgroundColor, range: token.tokenRange)
                } else {
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                }
                
                textStorage.addAttributes([OutlineAttribute.Block.quote: OutlineTheme.quoteBlockStyle.backgroundColor], range: token.range)
            }
            
        }
    }
    
    public func didFoundQuoteBlockEnd(text: String, ranges: [[String : NSRange]]) {

        ranges.forEach { quoteRange in
            
            let token = BlockEndToken(data: quoteRange, blockType: BlockType.quote)
            self.tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let token = token as? BlockEndToken else { return }
                
                if textStorage.isReadingMode {
                    textStorage.addAttribute(NSAttributedString.Key.foregroundColor, value: OutlineTheme.quoteBlockStyle.backgroundColor, range: token.tokenRange)
                } else {
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: token.tokenRange)
                }
                
                
                if let contentRange = token.beginToken?.contentRange {
                    textStorage.addAttributes(OutlineTheme.quoteBlockStyle.attributes, range: contentRange)
                }
            }
        }
    }
    
    public func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {
        headingDataRanges.forEach { headingData in
            let token = HeadingToken(data: headingData)
            token.outlineTextStorage = self

            self.tempParsingTokenResult.append(token)
            self.ignoreTextMarkRanges.append(token.levelRange)
            
            self.checkMarkEmbeded(token: token)
            
            token.decorationAttributesAction = { textStorage, token in
                guard let headingRange = token.range(for: OutlineParser.Key.Node.heading) else { return }
                guard let headingToken = token as? HeadingToken else { return }
                
                textStorage.addAttribute(OutlineAttribute.Heading.content, value: 1, range: headingRange)
                
                if let levelRange = token.range(for: OutlineParser.Key.Element.Heading.level) {
                    textStorage.addAttribute(OutlineAttribute.Heading.level, value: 1, range: levelRange)
                }
                
                textStorage.addAttributes(OutlineTheme.headingStyle(level: token.range(for: OutlineParser.Key.Element.Heading.level)?.length ?? 1).attributes, range: headingRange)
                                
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
                                
                if let idRange = headingToken.id {
                    textStorage.addAttribute(NSAttributedString.Key.font, value: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote), range: idRange)
                    
                    textStorage.addAttributes([OutlineAttribute.onePiease: 1,
                                               OutlineAttribute.hidden: OutlineAttribute.hiddenValueDefault], range: NSRange(location: headingToken.range.location, length: idRange.length + headingToken.level))
                    headingToken.identifier = textStorage.substring(idRange)
                } else {
                    textStorage.addAttribute(OutlineAttribute.onePiease, value: 1, range: headingToken.levelRange)
                    headingToken.identifier = UUID().uuidString
                }
                
                textStorage.addHeadingFoldingStatus(heading: headingToken)

            }
            
        }
    }
    
    public func didFoundDateAndTime(text: String, rangesData: [[String: NSRange]]) {
        
        for data in rangesData {
            guard let range = data[OutlineParser.Key.Element.dateAndTIme] else { return }
            
            let dateAndTimeToken = DateAndTimeToken(range: range, name: OutlineParser.Key.Element.dateAndTIme, data: data)
            self.tempParsingTokenResult.append(dateAndTimeToken)
            
            self.checkMarkEmbeded(token: dateAndTimeToken)
            
            dateAndTimeToken.decorationAttributesAction = { textStorage, token in
                guard let range = token.range(for: OutlineParser.Key.Element.dateAndTIme) else { return }
                
                var shouldRenderDateColor = true
                if let statusRange = textStorage.heading(contains: range.location)?.planning,
                    SettingsAccessor.shared.finishedPlanning.contains(textStorage.substring(statusRange)) {
                    shouldRenderDateColor = false
                }
                
                // render date and time interactive attributes
                let dataAndTimeString = textStorage.substring(range)
                let dateAndTime = DateAndTimeType(dataAndTimeString)
                let datesFromToday = dateAndTime?.closestDate(to: Date(), after: true).daysFrom(Date()) ?? 4 // 默认为 4 天, normal 颜色®
                let dateAndTimeStyle = OutlineTheme.dateAndTimeStyle(datesFromToday: datesFromToday)
                textStorage.addAttributes([OutlineAttribute.dateAndTime: dataAndTimeString], range: range)
                
                if shouldRenderDateColor {
                    textStorage.addAttributes(dateAndTimeStyle.textStyle.attributes, range: range)
                    
                    if let dataAndTimeObj = dateAndTime {
                        if dataAndTimeObj.isSchedule {
                            textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range.moveLeftBound(by: OutlineParser.Values.Other.scheduled.count + 2).head(1)) // set the left '<' to mark style
                        } else if dataAndTimeObj.isDue {
                            textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range.moveLeftBound(by: OutlineParser.Values.Other.due.count + 2).head(1)) // set the left '<' to mark style
                        } else {
                            textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range.head(1)) // set the left '<' to mark style
                        }
                        textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range.tail(1)) // set the right '>' to mark style
                    }
                } else {
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range)
                }
            }
        }
    }
    
    public func didFoundDrawerBegin(text: String, rangesData: [[String: NSRange]]) {
        for data in rangesData {
            guard let range = data[OutlineParser.Key.Node.drawerBlockBegin] else { return }
            let token = BlockBeginToken(data: data, blockType: BlockType.drawer)
            
            self.tempParsingTokenResult.append(token)
            
            if let nameRange = token.range(for: OutlineParser.Key.Element.Drawer.drawerName) {
                token.isPropertyDrawer = text.nsstring.substring(with: nameRange) == OutlineParser.Values.Block.Drawer.nameProperty
            }
            
            token.decorationAttributesAction = { textStorage, t in
                guard let drawer = t as? BlockToken else { return }
                
                if drawer.isPaired {
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range)
                }
            }
        }
    }
    
    public func didFoundDrawerEnd(text: String, rangesData: [[String: NSRange]]) {
        for data in rangesData {
            guard let range = data[OutlineParser.Key.Node.drawerBlockEnd] else { return }
            let token = BlockEndToken(data: data, blockType: BlockType.drawer)
            
            self.tempParsingTokenResult.append(token)
            
            token.decorationAttributesAction = { textStorage, t in
                guard let drawer = t as? BlockToken else { return }
                
                if drawer.isPaired {
                    textStorage.addAttributes(OutlineTheme.markStyle.attributes, range: range)
                }
            }
        }
    }
    
    public func didStartParsing(text: String) {
        self.tempParsingTokenResult = []
        self.ignoreTextMarkRanges = []
    }
    
    public func didCompleteParsing(text: String) {
        self._updateTokens(new: self.tempParsingTokenResult)
        
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
            if !removedHeadintToken.isHeadingChanged(newHeadings) {
                self.outlineDelegate?.didUpdateHeadings(newHeadings: newHeadings,
                                                        oldHeadings: removedHeadintToken)
            }
        }
        
        // 更新 block 缓存
        let newCodeBlocks = newTokens.filter {
            if $0 is BlockToken {
                return true
            } else {
                return false
            }
        }
        .map { $0 as! BlockToken }
        
        let removedblockToken = self._remove(in: currentParseRange, from: &self._blocks)
        self._insert(tokens: newCodeBlocks, into: &self._blocks)
        
        if newCodeBlocks.count > 0 || removedblockToken.count > 0 {
            self._figureOutBlocks(&self._blocks)
        }
        
        // remove tokens inside block
        for block in self._blocks {
            var count = self.allTokens.count
            for (index, token) in self.allTokens.reversed().enumerated() {
                if !(token is LinkToken) && block.range.intersection(token.range) != nil && !(token is BlockToken) {
                    self.allTokens.remove(at: count - 1 - index)
                }
            }
            
            count = self.tempParsingTokenResult.count
            for (index, token) in self.tempParsingTokenResult.reversed().enumerated() {
                if !(token is LinkToken) && block.range.intersection(token.range) != nil && !(token is BlockToken) {
                    self.tempParsingTokenResult.remove(at: count - 1 - index)
                }
            }
        }
    }
    
    // MARK: - utils
    
    public func isFolded(location: Int) -> Bool {
        if let headingToken = self.heading(contains: location) {
            return self.isHeadingFolded(heading: headingToken)
        } else {
            return false
        }
    }
    
    /// to check if the heading  is folded
    /// for now, first check if there's mark in the token in memory, if so, simply return that, if not, whic mean the user never interacted with this heading, then returnt he folding status  in theattributes
    public func isHeadingFolded(heading: HeadingToken) -> Bool {
//        if let lastFoldMaker = self.outlineDelegate?.logs()?.headings[heading.identifier]?.isFold {
//            return lastFoldMaker
//        }
//
        if heading.contentRange != nil {
            var effectiveRange: NSRange = NSRange(location: 0, length: 0)
            if let foldingTempAttachmentAttribute = self.attribute(OutlineAttribute.tempShowAttachment, at: heading.contentRange!.location, effectiveRange: &effectiveRange) as? String {
                return foldingTempAttachmentAttribute == OutlineAttribute.Heading.folded.rawValue
            } else if let folded = self.attribute(OutlineAttribute.hidden, at: heading.contentRange!.location, effectiveRange: nil) as? NSNumber {
                return folded.intValue == OutlineAttribute.hiddenValueFolded.intValue
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    public func addHeadingFoldingStatus(heading: HeadingToken) {
        
        
        self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueWithAttachment, range: heading.levelRange.head(1))
        self.addAttribute(OutlineAttribute.hidden, value: OutlineAttribute.hiddenValueDefault, range: heading.levelRange.tail(heading.levelRange.length - 1))
        
        let isFolded = self.outlineDelegate?.logs()?.headings[heading.identifier]?.isFold
                
        // only if the heading have content, can show the folded status icon
        if isFolded == true && heading.contentWithSubHeadingsRange.length > 1 {
            self.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingFolded, range: heading.levelRange)
        } else {
            self.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingUnfolded, range: heading.levelRange)
        }
    }
    
    private func _addStylesForCodeBlock() {
        guard let currentRange = self.currentParseRange else { return }
        
        for blockBeginToken in self._pairedBlocks {
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
    private var _pairedBlocks: [BlockBeginToken] {
        return self._blocks.filter {
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
            if token.tokenRange.intersection(range) != nil
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
        paragraphStyle.firstLineHeadIndent = CGFloat(heading.level * 24 + 4) // FIXME: 设置 indent 的宽度
        paragraphStyle.headIndent = paragraphStyle.firstLineHeadIndent
        
        let applyingRange = range ?? heading.paragraphRange
        
        guard applyingRange.upperBound <= self.string.count else { return }
        
        (self.string as NSString).enumerateSubstrings(in: applyingRange, options: .byLines) { (_, range, inclosingRange, stop) in
            // 第一行缩进比正文少一个 level
            if range.location == heading.range.location {
                let firstLine = NSMutableParagraphStyle()
                firstLine.firstLineHeadIndent = CGFloat((heading.level - 1) * 24)
                firstLine.headIndent = paragraphStyle.firstLineHeadIndent
                self.addAttributes([NSAttributedString.Key.paragraphStyle: firstLine], range: inclosingRange)
            } else {
                self.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: inclosingRange)
            }
        }
        
        // make sure the end of document have correctly indent
        if self.substring(applyingRange.tail(1)) == "\n" {
            self.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: applyingRange.tail(1))
        }
    }
    
    internal func _adjustParseRange(_ range: NSRange) -> NSRange {
        var newRange = range
        
        let line1Start = (string as NSString).lineRange(for: NSRange(location: newRange.location, length: 0)).location
        let line2End = (string as NSString).lineRange(for: NSRange(location: max(newRange.location, newRange.upperBound - 1), length: 0)).upperBound
        
        // if the end of line contains '\n', exclude from parsing range
        var tailCount = 0
        if self.string.count > line2End && self.string.nsstring.substring(with: NSRange(location: line2End - 1, length: 1)) == "\n" {
            tailCount = 1
        }
        
        newRange = NSRange(location: line1Start, length: line2End - tailCount - line1Start) // minus one, remove the last line break character
        
        // 如果范围在某个 item 内，并且小于这个 item 原来的范围，则扩大至这个 item 原来的范围
        for item in self.blocks {
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
        
        if newRange.upperBound > self.string.count {
            newRange = NSRange(location: newRange.location, length: self.string.count - newRange.location)
        }
        // 不包含已经折叠的部分
//        if let folded = self.foldedRange(at: newRange.location) {
//            newRange = NSRange(location: folded.upperBound, length: max(0, newRange.upperBound - folded.upperBound))
//        }
        
        return newRange
    }
    
    public func foldedRange(at location: Int) -> NSRange? {
        guard location < self.string.nsstring.length else { return nil }
        
        var folded: NSRange = NSRange(location: 0, length: 0)
        if let value = self.attribute(OutlineAttribute.tempHidden, at: location, longestEffectiveRange: &folded, in: NSRange(location: 0, length: self.length)) as? NSNumber,
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
    
    private func checkMarkEmbeded(token: Token) {
        for embedable in self._embedableTokenRanges {
            if token.range.intersection(embedable) != nil {
                token.isEmbeded = true
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
    public func flushTokens() {
        for token in self.allTokens {
            if token.needsRender {
                token.renderDecoration(textStorage: self)
                token.needsRender = false
            }
        }
    }
    
    public func setAttributeForHeading(_ heading: HeadingToken, isFolded: Bool) {        
        if isFolded == true {
            var range: NSRange = heading.contentWithSubHeadingsRange
            
            // keep the last line break
            if range.upperBound != self.string.nsstring.length {
                range = range.moveRightBound(by: -1)
            }
            
            guard range.length > 0 else { return }
            
            self.setParagraphIndent(heading: heading)
            
            self.setAttributes(nil, range: range)
            
            self.addAttributes([OutlineAttribute.tempHidden: OutlineAttribute.hiddenValueFolded,
                                       OutlineAttribute.tempShowAttachment: OutlineAttribute.Heading.folded],
                                      range: range)
            
            self.removeAttribute(OutlineAttribute.showAttachment, range: heading.levelRange)

            self.addAttribute(OutlineAttribute.showAttachment, value: OutlineAttribute.Heading.foldingFolded, range: heading.levelRange.head(1))
        } else {
            let range: NSRange = heading.paragraphRange
            
            self.setAttributes(nil, range: range)
            
            // 设置文字默认样式
            self.setAttributes(OutlineTheme.paragraphStyle.attributes,
                               range: range)
            
            // 折叠状态图标
            self.addAttributes([OutlineAttribute.showAttachment: OutlineAttribute.Heading.foldingUnfolded,
                                       OutlineAttribute.hidden: OutlineAttribute.hiddenValueWithAttachment],
                                      range: heading.levelRange.head(1))
            
            if heading.levelRange.length > 1 {
                self.addAttributes([OutlineAttribute.hidden: OutlineAttribute.hiddenValueDefault], range: heading.levelRange.tail(heading.levelRange.length - 1))
            }
            
            for token in self.allTokens {
                if heading.paragraphRange.contains(token.range.location) {
                    token.needsRender = true
                }
            }
        }
    }
}

extension Array where Element: HeadingToken {
    fileprivate func isHeadingChanged(_ another: [HeadingToken]) -> Bool {
        return self.count != another.count
    }
}

extension OutlineTextStorage {
    public override var debugDescription: String {
        return """
        length: \(self.string.nsstring.length)
        heading count: \(self._savedHeadings.count)
        codeBlock count: \(self._blocks.count)
        items count: \(self.allTokens.count)
        """
    }
}
