//
//  TextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol OutlineTextStorageDelegate: class {
    func didSetHeading(newHeading: Document.Heading?, oldHeading: Document.Heading?)
}

/// 提供渲染的对象，如 attachment, checkbox 等
public protocol OutlineTextStorageDataSource: class {
    // TODO: outline text storage data source
}

public class OutlineTextStorage: TextStorage {
    public var parser: OutlineParser!
    
    public override var string: String {
        set { super.replaceCharacters(in: NSRange(location: 0, length: self.string.count), with: newValue) }
        get { return super.string }
    }

    public var theme: OutlineTheme = OutlineTheme()
    
    public weak var outlineDelegate: OutlineTextStorageDelegate?
    
    /// 用于保存已经找到的 heading
    public var savedHeadings: [Document.Heading] = []
    
    /// 当前交互的文档位置，当前解析部分相对于文档开始的偏移量，不同于 currentParseRange 中的 location
    public var currentLocation: Int = 0
    
    public var currentHeading: Document.Heading?
    
    /// 当前的解析范围，需要进行解析的字符串范围，用于对 item，索引 等缓存数据进行重新组织
    public var currentParseRange: NSRange?
    // MARK: - Selection highlight
//    {
//        didSet {
//            if let _ = oldValue {
//                self.removeAttribute(NSAttributedString.Key.backgroundColor, range: NSRange(location: 0, length: self.string.count))
//            }
//            self.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.red.withAlphaComponent(0.5)], range: currentParseRange!)
//        }
//    }
    
    /// 当前所在编辑位置的最外层，或者最前面的 item 类型, 某些 item 在某些编辑操作是会有特殊行为，例如:
    /// 当前 item 为 unordered list 时，换行将会自动添加一个新的 unordered list 前缀
    public var currentItem: Document.Item? {
        return self.item(after: self.currentLocation)
    }
    
    /// 找到的 node 的 location 在此，用于保存 element 的索引，在编辑过后，更新所有的索引，从而不需要把所有的字符串都重新解析一次
    public var itemRanges: [NSRange] = []
    
    /// 找到的 node 的 location 与之 data 的映射
    public var itemRangeDataMapping: [NSRange: Document.Item] = [:]
    
    // 用于解析过程中临时数据处理
    private var tempParsingResult: [[String: NSRange]] = []
    // 某些范围要忽略掉文字的样式，比如 link 内的文字样式
    private var ignoreTextMarkRanges: [NSRange] = []
    
    private var parsedActionsAfterLayout: [() -> Void] = []
    private var isParsedActionsAfterLayoutInprocess: Bool = false
}

// MARK: - Update Attributes
extension OutlineTextStorage: ContentUpdatingProtocol {
    public func performContentUpdate(_ string: String!, range: NSRange, delta: Int, action: NSTextStorage.EditActions) {
//        log.info("editing in range: \(range), is non continouse: \(self.layoutManagers[0].hasNonContiguousLayout)")
//        
        guard action != .editedAttributes else { return } // 如果是修改属性，则不进行解析
        guard string.count > 0 else { return }
        
        /// 更新当前交互的位置
        self.currentLocation = editedRange.location
        
        // 更新 item 索引缓存
        self.updateItemIndexAndRange(delta: delta)
        
        // 调整需要解析的字符串范围
        self.adjustParseRange(editedRange)
        
        if let parsingRange = self.currentParseRange {
            // 清空 attributes (折叠的状态除外)
            for (key, _) in self.attributes(at: parsingRange.location, longestEffectiveRange: nil, in: parsingRange) {
                if key == OutlineAttribute.Heading.folded { continue }
                if key == NSAttributedString.Key.backgroundColor { continue }
                self.removeAttribute(key, range: parsingRange)
            }
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
    public func item(after: Int) -> Document.Item? {
        for itemRange in self.itemRanges {
            if itemRange.upperBound >= after {
                return self.itemRangeDataMapping[itemRange]
            }
        }
        
        return nil
    }
    
    /// 获取范围内的 item range 的索引
    public func indexsOfItem(in: NSRange) -> [Int]? {
        var items: [Int] = []
        for (index, itemRange) in self.itemRanges.enumerated() {
            if itemRange.location >= `in`.location &&
                itemRange.upperBound <= `in`.upperBound {
                items.append(index)
            }
        }
        
        return items.count > 0 ? items : nil
    }
    
    public func updateItemIndexAndRange(delta: Int) {
        guard let currentParseRange = self.currentParseRange else { return }
        
        if let indexs = self.indexsOfItem(in: currentParseRange) {
            // 清除 currentParseRange 内的所有保存的 index 和对应的 Item
            
            log.verbose("remove indexs: \(indexs)")
            indexs.reversed().forEach {
                self.itemRangeDataMapping.removeValue(forKey: self.itemRanges.remove(at: $0))
            }
            
            // 没有在 currentParseRange 内的 item 和 index，修改 offset
            if let lastDeletedIndex = indexs.last {
                if lastDeletedIndex < self.itemRanges.count - 1 {
                    self.itemRangeDataMapping[self.itemRanges[lastDeletedIndex]]?.offset(delta)
                }
            }
        }
        
        self.savedHeadings
            .filter { $0.range.location > self.currentLocation }
            .forEach { $0.offset(delta) }
        
        self.currentHeading?.contentLength += delta
    }
    
    private func findInsertPosition(new: Int, ranges: [NSRange]) -> Int {
        guard ranges.count > 0 else { return 0 }
        
        for (index, range) in ranges.enumerated() {
            if new <= range.location {
                return index
            }
        }
        
        return ranges.count - 1
    }
    
    public func heading(at location: Int) -> Document.Heading? {
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
        self.currentHeading = self.heading(at: self.currentLocation)
        self.outlineDelegate?.didSetHeading(newHeading: self.currentHeading, oldHeading: oldHeading)
    }
}

// MARK: - Parse result -
extension OutlineTextStorage: OutlineParserDelegate {
    /// 更新找到的 heading
    /// - Parameter newHeadings:
    ///   新找到的 heading 数据
    private func updateHeadingIfNeeded(_ newHeadings: [[String: NSRange]]) {
        // 如果已保存的 heading 为空，直接全部添加
        if savedHeadings.count == 0 {
            self.savedHeadings = newHeadings.map { Document.Heading(data: $0) } // OutlineParser.Key.Node.heading 总是存在
        } else {
            // 删除 currentParsingRange 范围内包含的所有 heading, 删除后，将新的 headings 插入删除掉的位置
            if let currentRange = self.currentParseRange {
                var indexsToRemove: [Int] = []
                for (index, heading) in self.savedHeadings.enumerated() {
                    if heading.range.intersection(currentRange) != nil {
                        indexsToRemove.append(index)
                    }
                }
                
                indexsToRemove.reversed().forEach {
                    self.savedHeadings.remove(at: $0)
                }
                
                if indexsToRemove.count > 0 {
                    let newHeadingRanges = newHeadings.map { Document.Heading(data: $0) }
                    self.savedHeadings.insert(contentsOf: newHeadingRanges, at: indexsToRemove[0])
                }
            }
        }
    }
    
    /// 添加数据到 itemRanges 以及 itemRangeDataMapping 中
    private func insertItems(items: [[String: NSRange]]) {
        var newItems: [Document.Item] = []
        items.forEach {
            for (key, value) in $0 {
                newItems.append(Document.Item(range: value, name: key, data: [key: value]))
            }
        }

        newItems.sort { (lhs: Document.Item, rhs: Document.Item) -> Bool in
            if lhs.range.location != rhs.range.location {
                return lhs.range.location < rhs.range.location
            } else {
                return lhs.range.length >= rhs.range.length
            }
        }
        
        newItems.forEach {
            self.itemRangeDataMapping[$0.range] = $0
        }
        
        if let first = newItems.first {
            if self.itemRanges.count == 0 {
                self.itemRanges = newItems.map { $0.range }
            } else {
                let index = findInsertPosition(new: first.range.location, ranges: self.itemRanges)
                log.info("insert at: \(index)")
                if index == self.itemRanges.count - 1 {
                    self.itemRanges.append(contentsOf: newItems.map { $0.range })
                } else {
                    self.itemRanges.insert(contentsOf: newItems.map { $0.range }, at: index)
                }
            }
        }
    }
    
    // MARK: - handle parse result
    
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
        
        self.tempParsingResult.append(contentsOf: markRanges)
        
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
        self.tempParsingResult.append(contentsOf: urlRanges)
        self.ignoreTextMarkRanges.append(contentsOf: urlRanges.map { $0[OutlineParser.Key.Element.link]! })
        
        urlRanges.forEach { urlRangeData in
            if let range = urlRangeData[OutlineParser.Key.Element.link] {
                self.addAttribute(OutlineAttribute.Link.other, value: range, range: range)
            }
            urlRangeData.forEach {
                // range 为整个链接时，添加自定义属性，值为解析的链接结构
                if $0.key == OutlineParser.Key.Element.Link.title {
                    self.addAttributes([OutlineAttribute.Link.title: $0.value,
                                        NSAttributedString.Key.link: 1], range: $0.value)
                    self.removeAttribute(OutlineAttribute.Link.other, range: $0.value)
                } else if $0.key == OutlineParser.Key.Element.Link.url {
                    self.addAttribute(OutlineAttribute.Link.url, value: $0.value, range: $0.value)
                    self.removeAttribute(OutlineAttribute.Link.other, range: $0.value)
                }
            }
        }
    }
    
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        attachmentRanges.forEach { rangeData in
            guard let attachmentRange = rangeData[OutlineParser.Key.Node.attachment] else { return }
            guard let typeRange = rangeData[OutlineParser.Key.Element.Attachment.type] else { return }
            guard let valueRange = rangeData[OutlineParser.Key.Element.Attachment.value] else { return }
            
            self.addAttributes([OutlineAttribute.Attachment.attachment: 1,
                                OutlineAttribute.Attachment.type: self.string.substring(typeRange),
                                OutlineAttribute.Attachment.value: self.string.substring(valueRange)],
                               range: attachmentRange)
        }
    }
    
    public func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: checkboxRanges)
        
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
        self.tempParsingResult.append(contentsOf: orderedListRnages)
        
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
        self.tempParsingResult.append(contentsOf: unOrderedListRnages)
        
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
                self.addAttributes([OutlineAttribute.separator: 1], range: seperatorRange)
            }
        }
    }
    
    public func didFoundCodeBlock(text: String, codeBlockRanges: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: codeBlockRanges)
        
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
        self.tempParsingResult.append(contentsOf: quoteRanges)
        
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
        self.tempParsingResult.append(contentsOf: headingDataRanges)
        self.updateHeadingIfNeeded(headingDataRanges)
        
        headingDataRanges.forEach {
            if let levelRange = $0[OutlineParser.Key.Element.Heading.level] {
                self.addAttribute(OutlineAttribute.Heading.level, value: $0, range: levelRange)
                self.addAttribute(NSAttributedString.Key.font, value: UIFont.boldSystemFont(ofSize: 20), range: levelRange)
                
                // display arrow based on wheather the next character is hidden (if there is one)
                if let range = $0[OutlineParser.Key.Node.heading] {
                    let nextCharacterLocation: Int = range.upperBound + 1
                    let nextCharacter: String = self.string.substring(NSRange(location: nextCharacterLocation, length: 1))
                    
                    let isEndOfFile: Bool = range.upperBound >= self.string.count - 1
                    let isEndOfHeading: Bool = nextCharacter == OutlineParser.Values.Heading.level
                    
                    if !isEndOfFile && !isEndOfHeading {
                        if self.attributes(at: nextCharacterLocation, effectiveRange: nil)[OutlineAttribute.Heading.folded] == nil {
                            
                        } else {
                            
                        }
                    }
                }
            }
            
            if let scheduleRange = $0[OutlineParser.Key.Element.Heading.schedule] {
                self.addAttribute(OutlineAttribute.Heading.schedule, value: scheduleRange, range: scheduleRange)
                self.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.orange, range: scheduleRange)
            }
            
            if let dueRange = $0[OutlineParser.Key.Element.Heading.due] {
                self.addAttribute(OutlineAttribute.Heading.due, value: dueRange, range: dueRange)
                self.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.purple, range: dueRange)
            }
            
            if let tagsRange = $0[OutlineParser.Key.Element.Heading.tags] {
                self.addAttribute(OutlineAttribute.Heading.due, value: tagsRange, range: tagsRange)
                self.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.cyan, range: tagsRange)
            }
            
            if let planningRange = $0[OutlineParser.Key.Element.Heading.planning] {
                self.addAttribute(OutlineAttribute.Heading.due, value: planningRange, range: planningRange)
                self.addAttribute(NSAttributedString.Key.font, value: InterfaceTheme.Font.title, range: planningRange)
                self.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: planningRange)
            }
        }
    }
    
    public func didStartParsing(text: String) {
        self.tempParsingResult = []
        self.ignoreTextMarkRanges = []
        self.parsedActionsAfterLayout = []
    }
    
    public func didCompleteParsing(text: String) {
        // 添加接续出来的 item 到 items 列表
        if self.tempParsingResult.count > 0 {
            self.insertItems(items: self.tempParsingResult)
        }
        
        // 更新段落长度信息
        self.updateHeadingParagraphLength()
        
        // 更新段落缩进样式
        self.setParagraphIndent()
        
        print(self.debugDescription)
    }
    
    private func setParagraphIndent() {
        for heading in self.savedHeadings {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.firstLineHeadIndent = CGFloat(heading.level * 8) // FIXME: 设置 indent 的宽度
            paragraphStyle.headIndent = paragraphStyle.firstLineHeadIndent
            
            (self.string as NSString)
                .enumerateSubstrings(
                    in: heading.paragraphRange,
                    options: .byLines
                ) { (_, range, inclosingRange, stop) in
                    if range.location == heading.range.location {
                        let headParagraphStyle = NSMutableParagraphStyle()
                        headParagraphStyle.headIndent = paragraphStyle.firstLineHeadIndent
                        self.addAttributes([NSAttributedString.Key.paragraphStyle: headParagraphStyle], range: inclosingRange)
                    } else {
                        self.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: inclosingRange)
                    }
            }
        }
    }
    
    // MARK: - utils

    /// 获得用 heading 分割的段落的 range 列表
    private func updateHeadingParagraphLength() {
        var endOfParagraph = self.string.count
        self.savedHeadings.reversed().forEach {
            $0.contentLength = endOfParagraph - $0.range.upperBound - 1
            endOfParagraph = $0.range.location
        }
    }
    
    internal func adjustParseRange(_ range: NSRange) {
        var start: Int = 0, end: Int = 0
        (self.string as NSString).getParagraphStart(&start, end: &end, contentsEnd: nil, for: range)
        self.currentParseRange = NSRange(location: start, length: end - start)
        
        // 如果范围在某个 item 内，并且小于这个 item 原来的范围，则扩大至这个 item 原来的范围
        if let currrentParseRange = self.currentParseRange {
            for item in self.itemRanges {
                if item.location <= currrentParseRange.location
                    && item.upperBound >= currrentParseRange.upperBound {
                    self.currentParseRange = item
                    return
                }
            }
        }
    }
}

extension NSRange {
    /// 将在字符串中的选择区域扩展到前一个换行符之后，后一个换行符之前
    internal func expandBackward(string: String) -> NSRange {
        var extendedRange = self
        var characterBuf: String = ""
        // 向上, 到上一个空行之后
        while extendedRange.location > 0
            && !self.checkIsBlankLine(buf: &characterBuf, next: string.substring(NSRange(location: extendedRange.location - 1, length: 1))) {
                extendedRange = NSRange(location: extendedRange.location - 1, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
    
    internal func expandFoward(string: String) -> NSRange {
        // 向下，下一个空行之前
        var extendedRange = self
        var characterBuf: String = ""
        while extendedRange.upperBound < string.count - 1
            && !self.checkIsBlankLine(buf: &characterBuf, next: string.substring(NSRange(location: extendedRange.upperBound, length: 1))) {
                extendedRange = NSRange(location: extendedRange.location, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
    
    // 检查是否空行
    private func checkIsBlankLine(buf: inout String, next character: String) -> Bool {
        if character == OutlineParser.Values.Character.linebreak {
            buf.append(character)
        } else {
            buf = ""
        }
        
        return buf == (OutlineParser.Values.Character.linebreak)
    }
}

extension OutlineTextStorage {
    public override var debugDescription: String {
        return """
        length: \(self.string.count)
        heading count: \(self.savedHeadings.count)
        items count: \(self.itemRanges.count)
"""
    }
}
