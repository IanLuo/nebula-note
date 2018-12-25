//
//  TextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class OutlineTextStorage: NSTextStorage {
    /// Node 和 element 都是 Item
    public class Item {
        public var offset: Int = 0 {
            didSet {
                log.verbose("offset did set: \(offset)")
            }
        }
        private var previouse: Item?
        private var next: Item?
        private var _range: NSRange
        public var range: NSRange {
            set { _range = newValue }
            get { return offset == 0 ? _range : _range.offset(self.offset) }
        }
        public var name: String
        public var data: [String: NSRange]
        
        public init(range: NSRange, name: String, data: [String: NSRange]) {
            self._range = range
            self.name = name
            self.data = data
        }
        
        public func offset(_ offset: Int) {
            self.offset += offset
            next?.offset(offset)
        }
    }
    
    public class Heading: Item {
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
        
        public var contentLength: Int = 0
        
        public var paragraphRange: NSRange {
            return NSRange(location: range.location, length: contentLength)
        }
        
        public convenience init(data: [String: NSRange]) {
            self.init(range: data[OutlineParser.Key.Node.heading]!, name: OutlineParser.Key.Node.heading, data: data)
            log.verbose("new heading: \(range)")
        }
    }
    
    public var theme: OutlineTheme = OutlineTheme()
    
    /// 用于保存已经找到的 heading
    public var savedHeadings: [Heading] = []
    
    /// 当前交互的文档位置，当前解析部分相对于文档开始的偏移量，不同于 currentParseRange 中的 location
    public var currentLocation: Int = 0
    
    public var currentHeading: Heading?
    
    /// 当前的解析范围，需要进行解析的字符串范围，用于对 item，索引 等缓存数据进行重新组织
    public var currentParseRange: NSRange? {
        didSet {
            if let _ = oldValue {
                self.removeAttribute(NSAttributedString.Key.backgroundColor, range: NSRange(location: 0, length: self.string.count))
            }
            self.addAttributes([NSAttributedString.Key.backgroundColor: UIColor.red.withAlphaComponent(0.1)], range: currentParseRange!)
        }
    }
    
    /// 找到的 node 的 location 在此，用于保存 element 的索引，在编辑过后，更新所有的索引，从而不需要把所有的字符串都重新解析一次
    public var itemRanges: [NSRange] = []
    
    /// 找到的 node 的 location 与之 data 的映射
    public var itemRangeDataMapping: [NSRange: Item] = [:]
    
    // 用于解析过程中临时数据处理
    private var tempParsingResult: [[String: NSRange]] = []
    // 某些范围要忽略掉文字的样式，比如 link 内的文字样式
    private var ignoreTextMarkRanges: [NSRange] = []
    
    /// 找到对应位置之后的第一个 item
    public func item(after: Int) -> Item? {
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
    
    private var backingStore: NSMutableAttributedString = NSMutableAttributedString()
    
    public override var string: String {
        set { self.replaceCharacters(in: NSRange(location: 0, length: backingStore.string.count), with: newValue) }
        get { return backingStore.string }
    }
    
    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return backingStore.attributes(at: location, effectiveRange: range)
    }
    
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        backingStore.setAttributes(attrs, range: range)
        edited(NSTextStorage.EditActions.editedCharacters, range: range, changeInLength: 0)
    }
    
    /// 替换显示样式, 比如渲染 code block
    public override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        backingStore.replaceCharacters(in: range, with: attrString)
        edited(NSTextStorage.EditActions.editedAttributes,
               range: range,
               changeInLength: attrString.string.count - range.length)
    }
    
    public override func replaceCharacters(in range: NSRange, with str: String) {
        backingStore.replaceCharacters(in: range, with: str)
        edited(NSTextStorage.EditActions.editedAttributes,
               range: range,
               changeInLength: str.count - range.length)
    }
    
    public override func processEditing() {
        super.processEditing()
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
    
    public func headingIndex(at characterIndex: Int) -> Int {
        var index: Int = 0
        for (i, heading) in self.savedHeadings.reversed().enumerated() {
            if heading.range.location <= characterIndex {
                index = self.savedHeadings.count - 1 - i
                break
            }
        }
        
        return index
    }
    
    public func updateCurrentInfo() {
        guard self.savedHeadings.count > 0 else { return }
        
        self.currentHeading = self.savedHeadings[self.headingIndex(at: self.currentLocation)]
    }
}

extension OutlineTextStorage: OutlineParserDelegate {
    /// 更新找到的 heading
    /// - Parameter newHeadings:
    ///   新找到的 heading 数据
    private func updateHeadingIfNeeded(_ newHeadings: [[String: NSRange]]) {
        // 如果已保存的 heading 为空，直接全部添加
        if savedHeadings.count == 0 {
            self.savedHeadings = newHeadings.map { Heading(data: $0) } // OutlineParser.Key.Node.heading 总是存在
        } else {
            // 删除 currentParsingRange 范围内包含的所有 heading, 删除后，将新的 headings 插入删除掉的位置
            if let currentRange = self.currentParseRange {
                var indexsToRemove: [Int] = []
                for (index, heading) in self.savedHeadings.enumerated() {
                    if heading.range.location >= currentRange.location
                        && heading.range.upperBound <= currentRange.upperBound {
                        indexsToRemove.append(index)
                    }
                }
                
                indexsToRemove.reversed().forEach {
                    self.savedHeadings.remove(at: $0)
                }
                
                if indexsToRemove.count > 0 {
                    let newHeadingRanges = newHeadings.map { Heading(data: $0) }
                    self.savedHeadings.insert(contentsOf: newHeadingRanges, at: indexsToRemove[0])
                }
            }
        }
    }
    
    /// 添加数据到 itemRanges 以及 itemRangeDataMapping 中
    private func insertItems(items: [[String: NSRange]]) {
        var newItems: [Item] = []
        items.forEach {
            for (key, value) in $0 {
                newItems.append(Item(range: value, name: key, data: [key: value]))
            }
        }
        
        newItems.sort { (lhs: OutlineTextStorage.Item, rhs: OutlineTextStorage.Item) -> Bool in
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
                log.verbose("insert at: \(index)")
                if index == self.itemRanges.count - 1 {
                    self.itemRanges.append(contentsOf: newItems.map { $0.range })
                } else {
                    self.itemRanges.insert(contentsOf: newItems.map { $0.range }, at: index)
                }
            }
        }
    }
    
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
        urlRanges.forEach {
            $0.forEach {
                if $0.key == OutlineParser.Key.Element.link {
                    self.addAttribute(OutlineAttribute.link, value: $0.value, range: $0.value)
                    self.addAttribute(NSAttributedString.Key.link, value: 1, range: $0.value)
                } else if $0.key == OutlineParser.Key.Element.Link.title {
                    self.addAttribute(OutlineAttribute.Link.title, value: $0.value, range: $0.value)
                }
            }
        }
    }
    
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: attachmentRanges)
    }
    
    public func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: checkboxRanges)
        
        checkboxRanges.forEach {
            for (key, range) in $0 {
                if key == OutlineParser.Key.Element.Checkbox.status {
                    let attachment = NSTextAttachment()
                    attachment.bounds = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
                    let status = (self.string as NSString).substring(with: range)
                    let color = status == OutlineParser.Values.Checkbox.unchecked
                        ? UIColor.green
                        : status == OutlineParser.Values.Checkbox.checked ? UIColor.red : UIColor.lightGray
                    
                    attachment.image = UIImage.create(with: color, size: attachment.bounds.size)
                    self.addAttribute(NSAttributedString.Key.attachment, value: attachment, range: NSRange(location: range.location, length: 1))
                    self.addAttribute(OutlineAttribute.Checkbox.box, value: range, range: NSRange(location: range.location, length: 1))
                    self.addAttribute(OutlineAttribute.Checkbox.status, value: range, range: range)
                }
            }
        }
    }
    
    public func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: orderedListRnages)
    }
    
    public func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: unOrderedListRnages)
    }
    
    public func didFoundSeperator(text: String, seperatorRanges: [[String: NSRange]]) {
        self.tempParsingResult.append(contentsOf: seperatorRanges)
    }
    
    public func didFoundCodeBlock(text: String, codeBlockRanges: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: codeBlockRanges)
    }
    
    public func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {
        self.tempParsingResult.append(contentsOf: headingDataRanges)
        self.updateHeadingIfNeeded(headingDataRanges)
        
        headingDataRanges.forEach {
            if let levelRange = $0[OutlineParser.Key.Element.Heading.level] {
                let attachment = NSTextAttachment()
                attachment.bounds = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
                attachment.image = UIImage.create(with: UIColor.lightGray, size: attachment.bounds.size)
                self.addAttribute(NSAttributedString.Key.attachment, value: attachment, range: levelRange)
                self.addAttribute(OutlineAttribute.Heading.level, value: levelRange, range: levelRange)
            }
            
            if let scheduleRange = $0[OutlineParser.Key.Element.Heading.schedule] {
                self.addAttribute(OutlineAttribute.Heading.schedule, value: scheduleRange, range: scheduleRange)
                self.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.orange, range: scheduleRange)
            }
            
            if let dueRange = $0[OutlineParser.Key.Element.Heading.due] {
                self.addAttribute(OutlineAttribute.Heading.due, value: dueRange, range: dueRange)
                self.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.purple, range: dueRange)
            }
            
            if let tagsRange = $0[OutlineParser.Key.Element.Heading.tags] {
                self.addAttribute(OutlineAttribute.Heading.due, value: tagsRange, range: tagsRange)
                self.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.cyan, range: tagsRange)
            }
            
            if let planningRange = $0[OutlineParser.Key.Element.Heading.planning] {
                self.addAttribute(OutlineAttribute.Heading.due, value: planningRange, range: planningRange)
                self.addAttribute(NSAttributedString.Key.font, value: UIFont.boldSystemFont(ofSize: 12), range: planningRange)
                self.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: planningRange)
            }
        }
    }
    
    public func didStartParsing(text: String) {
        tempParsingResult = []
        ignoreTextMarkRanges = []
    }
    
    public func didCompleteParsing(text: String) {
        if self.tempParsingResult.count > 0 {
            self.insertItems(items: self.tempParsingResult)
        }
        
        self.updateHeadingParagraphLength()
        
        self.setParagraphIndent()
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
    
    /// 获得用 heading 分割的段落的 range 列表
    private func updateHeadingParagraphLength() {
        var paragrphs: [NSRange] = []
        if var last = self.savedHeadings.first {
            for i in 1..<self.savedHeadings.count {
                let next = self.savedHeadings[i]
                let range = NSRange(location: last.range.location,
                                    length: next.range.location - last.range.location - 1)
                paragrphs.append(range)
                last = self.savedHeadings[i]
            }
            
            let lastRange = NSRange(location: last.range.location, length: self.string.count - last.range.location)
            paragrphs.append(lastRange)
        }
        
        for (index, range) in paragrphs.enumerated() {
            self.savedHeadings[index].contentLength = range.length
        }
        
    }
}
