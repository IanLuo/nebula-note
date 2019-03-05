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
    
    private let eventObserver: EventObserver
    
    public init(eventObserver: EventObserver) {
        self.eventObserver = eventObserver
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
    
    /// 用于保存已经找到的 heading
    public var savedHeadings: [HeadingToken] = []
    
    /// 当前交互的文档位置，当前解析部分相对于文档开始的偏移量，不同于 currentParseRange 中的 location
    public var currentLocation: Int = 0
    
    public var currentHeading: HeadingToken?
    
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
    
    /// 当前所在编辑位置的最外层，或者最前面的 item 类型, 某些 item 在某些编辑操作是会有特殊行为，例如:
    /// 当前 item 为 unordered list 时，换行将会自动添加一个新的 unordered list 前缀
    public var currentItem: Token? {
        return self.item(after: self.currentLocation)
    }
    
    /// 所有解析获得的 item, 对应当前的文档结构解析状态
    public var allTokens: [Token] = []
    
    // 用于解析过程中临时数据处理
    private var tempParsingTokenResult: [[String: NSRange]] = []
    private var tempParsingHeadingTokenResult: [[String: NSRange]] = []
    // 某些范围要忽略掉文字的样式，比如 link 内的文字样式
    private var ignoreTextMarkRanges: [NSRange] = []
}

// MARK: - Update Attributes
extension OutlineTextStorage: ContentUpdatingProtocol {
    public func performContentUpdate(_ string: String!, range: NSRange, delta: Int, action: NSTextStorage.EditActions) {
        //        log.info("editing in range: \(range), is non continouse: \(self.layoutManagers[0].hasNonContiguousLayout)")
        //
        guard self.editedMask != .editedAttributes else { return } // 如果是修改属性，则不进行解析
        guard self.string.count > 0 else { return }
        
        /// 更新当前交互的位置
        self.currentLocation = editedRange.location

        // 更新 item 索引缓存
        self.updateItemIndexAndRange(delta: self.changeInLength)

        // 调整需要解析的字符串范围
        self.adjustParseRange(editedRange)

        if let parsingRange = self.currentParseRange {
            // 清空 attributes (折叠的状态除外)
            var effectiveRange: NSRange = NSRange(location:0, length: 0)
            let value = self.attribute(OutlineAttribute.hidden, at: parsingRange.location, longestEffectiveRange: &effectiveRange, in: parsingRange)
            self.setAttributes([:], range: parsingRange)
            if let value = value as? NSNumber, value.intValue == OutlineAttribute.hiddenValueFolded.intValue {
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
    /// 找到对应位置之后的第一个 item
    public func item(after: Int) -> Token? {
        for item in self.allTokens {
            if item.range.upperBound >= after {
                return item
            }
        }
        
        return nil
    }
    
    /// 获取范围内的 item range 的索引
    public func indexsOfItem(in: NSRange) -> [Int]? {
        var items: [Int] = []
        for (index, item) in self.allTokens.enumerated() {
            if item.range.location >= `in`.location &&
                item.range.upperBound <= `in`.upperBound {
                items.append(index)
            }
        }
        
        return items.count > 0 ? items : nil
    }
    
    public func updateItemIndexAndRange(delta: Int) {
        self.allTokens
            .filter { $0.range.location > self.currentLocation }
            .forEach { $0.offset(delta) }
        
        self.savedHeadings
            .filter { $0.range.location > self.currentLocation }
            .forEach { $0.offset(delta) }
        
        self.currentHeading?.contentLength += delta
    }
    
    public func heading(contains location: Int) -> HeadingToken? {
        for heading in self.savedHeadings {
            if heading.paragraphRange.contains(location) {
                return heading
            }
        }
        
        return nil
    }
    
    /// 更新和当前位置相关的其他信息
    public func updateCurrentInfo() {
        guard self.savedHeadings.count > 0 else { return }
        
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
            
            for ignorRange in self.ignoreTextMarkRanges {
                if ignorRange.location <= range.location && ignorRange.upperBound >= range.upperBound {
                    markRanges.remove(at: count - index)
                    break
                }
            }
        }
        
        self.tempParsingTokenResult.append(contentsOf: markRanges)
        
        for dict in markRanges {
            for (key, range) in dict {
                switch key {
                case OutlineParser.Key.Element.TextMark.bold:
                    self.addAttributes(OutlineTheme.Attributes.TextMark.bold, range: range)
                case OutlineParser.Key.Element.TextMark.italic:
                    self.addAttributes(OutlineTheme.Attributes.TextMark.italic, range: range)
                case OutlineParser.Key.Element.TextMark.strikeThough:
                    self.addAttributes(OutlineTheme.Attributes.TextMark.strikeThough, range: range)
                case OutlineParser.Key.Element.TextMark.code:
                    self.addAttributes(OutlineTheme.Attributes.TextMark.code, range: range)
                case OutlineParser.Key.Element.TextMark.underscore:
                    self.addAttributes(OutlineTheme.Attributes.TextMark.underscore, range: range)
                case OutlineParser.Key.Element.TextMark.verbatim:
                    self.addAttributes(OutlineTheme.Attributes.TextMark.verbatim, range: range)
                default: break
                }
            }
        }
    }
    
    public func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {
        self.tempParsingTokenResult.append(contentsOf: urlRanges)
        self.ignoreTextMarkRanges.append(contentsOf: urlRanges.map { $0[OutlineParser.Key.Element.link]! })
        
        urlRanges.forEach { urlRangeData in
            if let range = urlRangeData[OutlineParser.Key.Element.link] {
                self.addAttribute(OutlineAttribute.hidden, value: 1, range: range)
            }
            urlRangeData.forEach {
                // range 为整个链接时，添加自定义属性，值为解析的链接结构
                if $0.key == OutlineParser.Key.Element.Link.title {
                    self.addAttributes([NSAttributedString.Key.link: 1], range: $0.value)
                    self.removeAttribute(OutlineAttribute.hidden, range: $0.value)
                } else if $0.key == OutlineParser.Key.Element.Link.url {
                    self.addAttributes([OutlineAttribute.hidden: 2,
                                        OutlineAttribute.showAttachment: OutlineAttribute.Link.url], range: $0.value)
                }
            }
        }
    }
    
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        attachmentRanges.forEach { rangeData in
            guard let attachmentRange = rangeData[OutlineParser.Key.Node.attachment] else { return }
            guard let typeRange = rangeData[OutlineParser.Key.Element.Attachment.type] else { return }
            guard let valueRange = rangeData[OutlineParser.Key.Element.Attachment.value] else { return }
            
            self.addAttributes([OutlineAttribute.Attachment.attachment: OUTLINE_ATTRIBUTE_ATTACHMENT,
                                OutlineAttribute.Attachment.type: self.string.substring(typeRange),
                                OutlineAttribute.Attachment.value: self.string.substring(valueRange)],
                               range: attachmentRange)
        }
    }
    
    public func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {
        self.tempParsingTokenResult.append(contentsOf: checkboxRanges)
        
        checkboxRanges.forEach { checkbox in
            for (key, range) in checkbox {
                if key == OutlineParser.Key.Element.Checkbox.status {
                    self.addAttribute(OutlineAttribute.Checkbox.box, value: checkbox, range: range)
                    self.addAttribute(OutlineAttribute.Checkbox.status, value: range, range: NSRange(location: range.location, length: 1))
                    self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.spotLight,
                                        NSAttributedString.Key.font: InterfaceTheme.Font.title], range: range)
                }
            }
        }
    }
    
    public func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {
        self.tempParsingTokenResult.append(contentsOf: orderedListRnages)
        
        orderedListRnages.forEach { list in
            if let index = list[OutlineParser.Key.Element.OrderedList.index] {
                self.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.title,
                                    NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    OutlineAttribute.OrderedList.index: index], range: index)
            }
            
            if let range = list[OutlineParser.Key.Node.ordedList] {
                self.addAttribute(OutlineAttribute.OrderedList.range, value: range, range: range)
            }
        }
    }
    
    public func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {
        self.tempParsingTokenResult.append(contentsOf: unOrderedListRnages)
        
        unOrderedListRnages.forEach { list in
            if let prefix = list[OutlineParser.Key.Element.UnorderedList.prefix] {
                self.addAttributes([NSAttributedString.Key.font: InterfaceTheme.Font.title,
                                    NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive], range: prefix)
            }
        }
    }
    
    public func didFoundSeperator(text: String, seperatorRanges: [[String: NSRange]]) {
        seperatorRanges.forEach { range in
            if let seperatorRange = range[OutlineParser.Key.Node.seperator] {
                self.addAttributes([OutlineAttribute.hidden: 2,
                                    OutlineAttribute.showAttachment: OUTLINE_ATTRIBUTE_SEPARATOR], range: seperatorRange)
            }
        }
    }
    
    public func didFoundCodeBlock(text: String, codeBlockRanges: [[String : NSRange]]) {
        self.tempParsingTokenResult.append(contentsOf: codeBlockRanges)
        
        codeBlockRanges.forEach { range in
            if let range = range[OutlineParser.Key.Node.codeBlock] {
                self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                                    NSAttributedString.Key.backgroundColor: InterfaceTheme.Color.background2], range: range)
            }
            
            if let content = range[OutlineParser.Key.Element.CodeBlock.content] {
                self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.body], range: content)
            }
        }
    }
    
    public func didFoundQuote(text: String, quoteRanges: [[String : NSRange]]) {
        self.tempParsingTokenResult.append(contentsOf: quoteRanges)
        
        quoteRanges.forEach { quoteRange in
            let paragraph = NSMutableParagraphStyle()
            paragraph.paragraphSpacingBefore = 10
            paragraph.headIndent = 100
            
            if let range = quoteRange[OutlineParser.Key.Node.quote] {
                self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.descriptive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.footnote,
                                    NSAttributedString.Key.paragraphStyle: paragraph], range: range)
            }
            
            if let content = quoteRange[OutlineParser.Key.Element.Quote.content] {
                self.addAttributes([NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive,
                                    NSAttributedString.Key.font: InterfaceTheme.Font.body], range: content)
            }
        }
    }
    
    public func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {
        self.tempParsingTokenResult.append(contentsOf: headingDataRanges)
        self.tempParsingHeadingTokenResult.append(contentsOf: headingDataRanges)
        
        headingDataRanges.forEach {
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
        self.tempParsingTokenResult = []
        self.ignoreTextMarkRanges = []
        self.tempParsingHeadingTokenResult = []
    }
    
    public func didCompleteParsing(text: String) {
        self.updateItems(new: self.tempParsingTokenResult)
        self.updateHeadings(new: self.tempParsingHeadingTokenResult)
        
        // 更新段落长度信息
        self.updateHeadingParagraphLength()
        
        // 更新段落缩进样式
        self.setParagraphIndent()
        
        print(self.debugDescription)
    }
    
    // MARK: -
    /// 更新找到的 heading
    /// - Parameter newHeadings:
    ///   新找到的 heading 数据
    private func updateHeadings(new headings: [[String: NSRange]]) {
        // 如果已保存的 heading 为空，直接全部添加
        if savedHeadings.count == 0 {
            self.savedHeadings = headings.map { HeadingToken(data: $0) } // OutlineParser.Key.Node.heading 总是存在
        } else {
            // 删除 currentParsingRange 范围内包含的所有 heading, 删除后，将新的 headings 插入删除掉的位置
            if let currentRange = self.currentParseRange {
                var removedHeadings: [HeadingToken] = []
                for index in self.findIntersectionTokenIndex(in: currentRange, tokens: self.savedHeadings).reversed() {
                    removedHeadings.append(self.savedHeadings.remove(at: index))
                }
                
                let newHeadingRanges = headings.map { HeadingToken(data: $0) }
                self.savedHeadings.insert(contentsOf: newHeadingRanges, at: self.findNextTokenIndex(after: currentRange, tokens: self.savedHeadings))
                
                // notify everyone that using headings
                self.outlineDelegate?.didUpdateHeadings(newHeadings: newHeadingRanges, oldHeadings: removedHeadings)
            }
        }
    }
    
    /// 更新 items 中的数据
    private func updateItems(new items: [[String: NSRange]]) {
        var newItems: [Token] = []
        items.forEach {
            for (key, value) in $0 {
                newItems.append(Token(range: value, name: key, data: [key: value]))
            }
        }
        
        newItems.sort { (lhs: Token, rhs: Token) -> Bool in
            if lhs.range.location != rhs.range.location {
                return lhs.range.location < rhs.range.location
            } else {
                return lhs.range.length >= rhs.range.length
            }
        }
        
        if self.allTokens.count == 0 {
            self.allTokens.append(contentsOf: newItems)
        } else {
            guard let currentParseRange = self.currentParseRange else { return }
            let oldCount = self.allTokens.count
            for index in self.findIntersectionTokenIndex(in: currentParseRange, tokens: self.allTokens).reversed() {
                self.allTokens.remove(at: index)
            }
            
            // add new found items
            self.allTokens.insert(contentsOf: newItems, at: self.findNextTokenIndex(after: currentParseRange, tokens: self.allTokens))
            log.info("[item count changed] \(self.allTokens.count - oldCount)")
        }
    }
    
    
    // MARK: - utils
    
    private func findIntersectionTokenIndex(in range: NSRange, tokens: [Token]) -> [Int] {
        var indexes: [Int] = []
        for (index, token) in tokens.enumerated() {
            if token.range.intersection(range) != nil {
                indexes.append(index)
            }
        }
        return indexes
    }
    
    
    private func findNextTokenIndex(after range: NSRange, tokens: [Token]) -> Int {
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
    
    private func setParagraphIndent() {
        for heading in self.savedHeadings {
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
    private func updateHeadingParagraphLength() {
        var endOfParagraph = self.string.count
        self.savedHeadings.reversed().forEach {
            $0.contentLength = endOfParagraph - $0.range.upperBound - 1
            endOfParagraph = $0.range.location
        }
    }
    
    internal func adjustParseRange(_ range: NSRange) {
        let range = range.expandFoward(string: self.string).expandBackward(string: self.string)
        self.currentParseRange = range
        
        // 如果范围在某个 item 内，并且小于这个 item 原来的范围，则扩大至这个 item 原来的范围
        if let currrentParseRange = self.currentParseRange {
            for item in self.allTokens {
                if item.range.location <= currrentParseRange.location
                    && item.range.upperBound >= currrentParseRange.upperBound {
                    self.currentParseRange = item.range
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
    internal func expandBackward(string: String) -> NSRange {
        var extendedRange = self
        var characterBuf: String = ""

        while extendedRange.location > 0
            && !self.checkShouldContinueExpand(buf: &characterBuf, next: string.substring(NSRange(location: extendedRange.location - 1, length: 1)), lineCount: 2) {
                extendedRange = NSRange(location: extendedRange.location - 1, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
    
    internal func expandFoward(string: String) -> NSRange {
        var extendedRange = self
        var characterBuf: String = ""
        
        while extendedRange.upperBound < string.count - 1
            && !self.checkShouldContinueExpand(buf: &characterBuf, next: string.substring(NSRange(location: extendedRange.upperBound, length: 1)), lineCount: 3) {
                extendedRange = NSRange(location: extendedRange.location, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
    
    // 检查是否继续 expand
    private func checkShouldContinueExpand(buf: inout String, next character: String, lineCount: Int) -> Bool {
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
        heading count: \(self.savedHeadings.count)
        items count: \(self.allTokens.count)
        """
    }
}
