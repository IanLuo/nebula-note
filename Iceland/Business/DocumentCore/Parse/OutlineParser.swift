//
//  OutlineParser.swift
//  Iceland
//
//  Created by ian luo on 2018/11/14.
//  Copyright © 2018 wod. All rights reserved.
//
// https://en.wikipedia.org/wiki/Regular_expression

import Foundation

public class OutlineParser {
    public weak var delegate: OutlineParserDelegate?
    
    public init() {}
    
    private func _safeSubstring(with str: String, range: NSRange) -> String {
        if range.location != Int.max {
            return (str as NSString).substring(with: range)
        }
        
        return ""
    }
    
    public var includeParsee: ParseeTypes = ParseeTypes.all
    
    
    /// 1. find heading
    /// 2. add attribute for element
    public func parse(str: String, range: NSRange? = nil) {
        let totalRange = range ?? NSRange(location: 0, length: str.count)
        
        self.delegate?.didStartParsing(text: str)
        // MARK: heading， 并且找出 level, planning, schedule, due 的 range
        if let heading = Matcher.Node.heading, includeParsee.contains(.heading) {
            let result: [[String: NSRange]] = heading
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    let headingRange = result.range(at: 0)
                    var comp: [String: NSRange] =
                        [Key.Node.heading: headingRange,
                         Key.Element.Heading.level: result.range(at: 1)]
                    
                    // 分别对 heading 中的其他部分进行解析
                    let headingContentParse: [(NSRegularExpression?, (NSTextCheckingResult) -> Void)] = [
                        (Matcher.Element.Heading.planning, { result in
                            guard result.range(at: 1).location != NSNotFound else { return }
                            comp[Key.Element.Heading.planning] = result.range(at: 1)
                        }),
                        (Matcher.Element.Heading.tags, { result in
                            guard result.range(at: 1).location != NSNotFound else { return }
                            comp[Key.Element.Heading.tags] = result.range(at: 1)
                        }),
                        (Matcher.Element.Heading.schedule, { result in
                            guard result.range(at: 1).location != NSNotFound else { return }
                            comp[Key.Element.Heading.schedule] = result.range(at: 1)
                            comp[Key.Element.Heading.scheduleDateAndTime] = result.range(at: 2)
                        }),
                        (Matcher.Element.Heading.due, { result in
                            guard result.range(at: 1).location != NSNotFound else { return }
                            comp[Key.Element.Heading.due] = result.range(at: 1)
                            comp[Key.Element.Heading.dueDateAndTime] = result.range(at: 2)
                        }),
                        (Matcher.Element.Heading.timeRange, { result in
                            guard result.range(at: 1).location != NSNotFound else { return }
                            comp[Key.Element.Heading.timeRange] = result.range(at: 1)
                        }),
                        (Matcher.Element.Heading.dateRange, { result in
                            guard result.range(at: 1).location != NSNotFound else { return }
                            comp[Key.Element.Heading.dateRange] = result.range(at: 1)
                        })
                        ]
                    
                    headingContentParse.forEach { regex, action in
                        if let r = regex {
                            if let result = r.firstMatch(in: str, options: [], range: headingRange) {
                                action(result)
                            }
                        }
                    }
                    
                    return comp
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundHeadings(text:str, headingDataRanges: result)
            }
        }
        
        // MARK: 解析 checkbox
        if let checkbox = Matcher.Node.checkbox, includeParsee.contains(.checkbox) {
            let result: [[String: NSRange]] = checkbox
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.checkbox] = result.range(at: 0)
                    comp[Key.Element.Checkbox.status] = result.range(at: 1)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundCheckbox(text: str, checkboxRanges: result)
            }
        }
        
        // MARK: 解析 code block begin
        if let codeBlockBegin = Matcher.Node.codeBlockBegin, includeParsee.contains(.codeBlockBegin) {
            let result: [[String: NSRange]] = codeBlockBegin
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.codeBlockBegin] = result.range(at: 0)
                    comp[Key.Element.CodeBlock.language] = result.range(at: 1)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundCodeBlockBegin(text: str, ranges: result)
            }
        }
        
        // MARK: 解析 code block end
        if let codeBlockEnd = Matcher.Node.codeBlockEnd, includeParsee.contains(.codeBlockEnd) {
            let result: [[String: NSRange]] = codeBlockEnd
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.codeBlockEnd] = result.range(at: 0)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundCodeBlockEnd(text: str, ranges: result)
            }
        }
        
        // MARK: 解析 quote begin
        if let quoteBlockBegin = Matcher.Node.quoteBlockBegin, includeParsee.contains(.quoteBlockBegin) {
            let result: [[String: NSRange]] = quoteBlockBegin
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.quoteBlockBegin] = result.range(at: 0)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundQuoteBlockBegin(text: str, ranges: result)
            }
        }
        
        // MARK: 解析 quote block end
        if let quoteBlockEnd = Matcher.Node.quoteBlockEnd, includeParsee.contains(.quoteBlockEnd) {
            let result: [[String: NSRange]] = quoteBlockEnd
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.quoteBlockEnd] = result.range(at: 0)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundQuoteBlockEnd(text: str, ranges: result)
            }
        }
        
        // MARK: 解析 ordered list
        if let orderedList = Matcher.Node.ordedList, includeParsee.contains(.orderedList) {
            let result: [[String: NSRange]] = orderedList
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.ordedList] = result.range(at: 0)
                    comp[Key.Element.OrderedList.index] = result.range(at: 1)
                    return comp
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundOrderedList(text: str, orderedListRnages: result)
            }
        }
        
        // MARK: 解析 unordered list
        if let unorderedList = Matcher.Node.unorderedList, includeParsee.contains(.unorderedList) {
            let result: [[String: NSRange]] = unorderedList
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.unordedList] = result.range(at: 0)
                    comp[Key.Element.UnorderedList.prefix] = result.range(at: 1)
                    return comp
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundUnOrderedList(text: str, unOrderedListRnages: result)
            }
        }
        
        // MARK: 解析 seperator
        if let seperator = Matcher.Node.seperator, includeParsee.contains(.seperator) {
            let result: [[String: NSRange]] = seperator
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    [Key.Node.seperator: result.range(at: 1)]
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundSeperator(text: str, seperatorRanges: result)
            }
        }
        
        // MARK: 解析 attachment
        if let attachment = Matcher.Node.attachment, includeParsee.contains(.attachment) {
            let result: [[String: NSRange]] = attachment
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.attachment] = result.range(at: 0)
                    comp[Key.Element.Attachment.type] = result.range(at: 1)
                    comp[Key.Element.Attachment.value] = result.range(at: 2)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundAttachment(text: str, attachmentRanges: result)
            }
        }
        
        // MARK: 解析 url
        if let url = Matcher.Element.link, includeParsee.contains(.link) {
            let result: [[String: NSRange]] = url
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Element.link] = result.range(at: 0)
                    comp[Key.Element.Link.url] = result.range(at: 1)
                    comp[Key.Element.Link.scheme] = result.range(at: 2)
                    comp[Key.Element.Link.title] = result.range(at: 3)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundLink(text: str, urlRanges: result)
            }
        }
        
        // MARK: 最后，解析带 mark 的文字
        let markResuls: [[String: NSRange]] =
            [(Key.Element.TextMark.bold, Matcher.Element.TextMark.bold),
             (Key.Element.TextMark.italic, Matcher.Element.TextMark.itatic),
             (Key.Element.TextMark.underscore, Matcher.Element.TextMark.underscore),
             (Key.Element.TextMark.strikeThough, Matcher.Element.TextMark.strikthrough),
             (Key.Element.TextMark.verbatim, Matcher.Element.TextMark.verbatim),
             (Key.Element.TextMark.code, Matcher.Element.TextMark.code)]
                .reduce([]) { (old: [[String: NSRange]], new: (String, NSRegularExpression?)) -> [[String: NSRange]] in
                    let (key, matcher) = new;
                    var result = old
                    if let matcher = matcher {
                        let r = matcher.matches(in: str, options: [], range: totalRange)
                            .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                                [key: result.range(at: 1),
                                 Key.Element.TextMark.mark: result.range(at: 1),
                                 Key.Element.TextMark.content: result.range(at: 2)]
                        }
                        
                        result.append(contentsOf: r)
                    }
                    
                    return result
            }
        
        if markResuls.count > 0 {
            self.logResult(markResuls)
            self.delegate?.didFoundTextMark(text: str, markRanges: markResuls)
        }
        
        self.delegate?.didCompleteParsing(text: str)
    }
}

// MARK: - Definitions

public protocol OutlineParserDelegate: class {
    func didFoundHeadings(text: String, headingDataRanges: [[String: NSRange]])
    func didFoundCheckbox(text: String, checkboxRanges: [[String: NSRange]])
    func didFoundOrderedList(text: String, orderedListRnages: [[String: NSRange]])
    func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String: NSRange]])
    func didFoundSeperator(text: String, seperatorRanges: [[String: NSRange]])
    func didFoundCodeBlockBegin(text: String, ranges: [[String: NSRange]])
    func didFoundCodeBlockEnd(text: String, ranges: [[String: NSRange]])
    func didFoundQuoteBlockBegin(text: String, ranges: [[String: NSRange]])
    func didFoundQuoteBlockEnd(text: String, ranges: [[String: NSRange]])
    func didFoundAttachment(text: String, attachmentRanges: [[String: NSRange]])
    func didFoundLink(text: String, urlRanges: [[String: NSRange]])
    func didFoundTextMark(text: String, markRanges: [[String: NSRange]])
    func didStartParsing(text: String)
    func didCompleteParsing(text: String)
}

public protocol OutlineParserDatasource: class {
    func customizedPlannings() -> [String]?
}

extension OutlineParserDelegate {
    public func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {}
    public func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {}
    public func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {}
    public func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {}
    public func didFoundSeperator(text: String, seperatorRanges: [[String : NSRange]]) {}
    public func didFoundCodeBlockBegin(text: String, ranges: [[String: NSRange]]) {}
    public func didFoundCodeBlockEnd(text: String, ranges: [[String: NSRange]]) {}
    public func didFoundQuoteBlockBegin(text: String, ranges: [[String: NSRange]]) {}
    public func didFoundQuoteBlockEnd(text: String, ranges: [[String: NSRange]]) {}
    public func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {}
    public func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {}
    public func didFoundTextMark(text: String, markRanges: [[String : NSRange]]) {}
    public func didStartParsing(text: String) {}
    public func didCompleteParsing(text: String) {}
}

extension OutlineParserDatasource {
    func customizedPlannings() -> [String]? { return nil }
}

extension OutlineParser {
    fileprivate func logResult(_ result: [[String: NSRange]]) {
        for dict in result {
            for (key, value) in dict {
                log.verbose(">>> \(key): \(value)")
            }
        }
    }
}

public struct DateAndTimeType {
    
    public enum RepeatMode {
        case day(Int)
        case week(Int)
        case month(Int)
        case year(Int)
    }
    
    public let date: Date
    public let includeTime: Bool // 是否包含时间
    public let repeateMode: RepeatMode? // 如果 repate 不为空，这个字段有值
    public let duration: TimeInterval? // 如果 time 是 range，这个字段有值
    
    public var description: String {
        if includeTime {
            return "\(date.monthStringShort) \(date.day) \(date.format("hh:mm"))"
        } else {
            return "\(date.monthStringShort) \(date.day)"
        }
    }
    
    public init(date: Date, includeTime: Bool, repeateMode: RepeatMode? = nil, duration: TimeInterval? = nil) {
        self.date = date
        self.includeTime = includeTime
        self.repeateMode = repeateMode
        self.duration = duration
    }
}

extension DateAndTimeType {
    public static func createFromSchedule(_ string: String) -> DateAndTimeType? {
        return _createSingleDateFrom(string: string, matcher: OutlineParser.Matcher.Element.Heading.schedule)
    }
    
    public static func createFromDue(_ string: String) -> DateAndTimeType? {
        return _createSingleDateFrom(string: string, matcher: OutlineParser.Matcher.Element.Heading.due)
    }
    
    public static func createFromDateRange(_ string: String) -> DateAndTimeType? {
        return _createDurationFrom(string: string, matcher: OutlineParser.Matcher.Element.Heading.dateRange)
    }
    
    // 这种情况单独处理，比较复杂
    public static func createFromTimeRange(_ string: String) -> DateAndTimeType? {
        if let matcher = OutlineParser.Matcher.Element.Heading.timeRange {
            if let result = matcher.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                let date = string.substring(result.range(at: 1))
                let time1 = string.substring(result.range(at: 3))
                let time2 = string.substring(result.range(at: 4))
                
                let dateString: (String, String) -> String = { date, time in return "\(date) \(time)" }
                
                let formatter = DateFormatter()
            
                let dateFormates: [String] = ["yyyy-MM-dd HH:mm",
                                              "yyyy-MM-dd EEE HH:mm"]
                
                for format in dateFormates {
                    formatter.dateFormat = format
                    if let date1 = formatter.date(from: dateString(date, time1)),
                        let date2 = formatter.date(from: dateString(date, time2)) {
                        
                        return DateAndTimeType(date: date1, includeTime: true, duration: date2.timeIntervalSinceReferenceDate - date1.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func _createDurationFrom(string: String, matcher: NSRegularExpression?) -> DateAndTimeType? {
        if let matcher = matcher {
            if let result = matcher.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                let formatter = DateFormatter()
                let dateString = matcher.replacementString(for: result, in: string, offset: 0, template: "$0")
                let dates = dateString.components(separatedBy: "--")
                let date1 = dates[0].replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
                let date2 = dates[1].replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "")
                
                let dateFormates = [("yyyy-MM-dd", false),
                                    ("yyyy-MM-dd EEE", false),
                                    ("yyyy-MM-dd HH:mm", true),
                                    ("yyyy-MM-dd EEE HH:mm", true)]
                
                for (format, includeTime) in dateFormates {
                    formatter.dateFormat = format
                    
                    if let date1 = formatter.date(from: date1),
                        let date2 = formatter.date(from: date2) {
                        return DateAndTimeType(date: date1, includeTime: includeTime, duration: date2.timeIntervalSinceReferenceDate - date1.timeIntervalSinceReferenceDate)
                    }
                }
            }
        }
        
        return nil
    }
    
    private static func _createSingleDateFrom(string: String, matcher: NSRegularExpression?) -> DateAndTimeType? {
        if let matcher = matcher {
            if let result = matcher.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                let formatter = DateFormatter()
                let dateString = matcher.replacementString(for: result, in: string, offset: 0, template: "$2")
                
                let dateFormates: [(String, Bool)] = [
                    ("yyyy-MM-dd EEE HH:mm", true),
                    ("yyyy-MM-dd HH:mm", true),
                    ("yyyy-MM-dd EEE", false),
                    ("yyyy-MM-dd", false)]
                
                for (format, includeTime) in dateFormates {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return DateAndTimeType(date: date, includeTime: includeTime)
                    }
                }
            }
        }
        
        return nil
    }
    
    public func toScheduleString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = self.includeTime ? "yyyy-MM-dd EEE HH:mm" : "yyyy-MM-dd EEE"
        return "SCHEDULED: <\(formatter.string(from: self.date))>"
    }
    
    public func toDueDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = self.includeTime ? "yyyy-MM-dd EEE HH:mm" : "yyyy-MM-dd EEE"
        return "DEADLINE: <\(formatter.string(from: self.date))>"
    }
}
