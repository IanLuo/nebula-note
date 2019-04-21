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
        // MARK: heading， 并且找出 level, planning, priority 的 range
        if includeParsee.contains(.heading) {
            let result: [[String: NSRange]] = Matcher.Node.heading
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
                        (Matcher.Element.Heading.priority, { result in
                            guard result.range.location != NSNotFound else { return }
                            comp[Key.Element.Heading.priority] = result.range
                        })]
                    
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
        
        // MARK: 解析 date and time
        if includeParsee.contains(.dateAndTime) {
            let result: [[String: NSRange]] = Matcher.Element.DateAndTime.anyDateAndTime
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    return [OutlineParser.Key.Element.dateAndTIme: result.range]
                }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundDateAndTime(text: str, rangesData: result)
            }
        }
        
        // MARK: 解析 code block begin
        if includeParsee.contains(.codeBlockBegin) {
            let result: [[String: NSRange]] = Matcher.Node.codeBlockBegin
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
        if includeParsee.contains(.codeBlockEnd) {
            let result: [[String: NSRange]] = Matcher.Node.codeBlockEnd
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
        if includeParsee.contains(.quoteBlockBegin) {
            let result: [[String: NSRange]] = Matcher.Node.quoteBlockBegin
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
        if includeParsee.contains(.quoteBlockEnd) {
            let result: [[String: NSRange]] = Matcher.Node.quoteBlockEnd
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
        if includeParsee.contains(.orderedList) {
            let result: [[String: NSRange]] = Matcher.Node.ordedList
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.ordedList] = result.range
                    comp[Key.Element.OrderedList.prefix] = result.range(at: 1)
                    comp[Key.Element.OrderedList.index] = result.range(at: 2)
                    return comp
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundOrderedList(text: str, orderedListRnages: result)
            }
        }
        
        // MARK: 解析 unordered list
        if includeParsee.contains(.unorderedList) {
            let result: [[String: NSRange]] = Matcher.Node.unorderedList
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
        
        // MARK: 解析 checkbox
        if includeParsee.contains(.checkbox) {
            let result: [[String: NSRange]] = Matcher.Node.checkbox
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.checkbox] = result.range(at: 1)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundCheckbox(text: str, checkboxRanges: result)
            }
        }
        
        // MARK: 解析 seperator
        if includeParsee.contains(.seperator) {
            let result: [[String: NSRange]] = Matcher.Node.seperator
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
        if includeParsee.contains(.attachment) {
            let result: [[String: NSRange]] = Matcher.Node.attachment
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
        
        // MARK: 解析 link
        if includeParsee.contains(.link) {
            let result: [[String: NSRange]] = Matcher.Element.link
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
                                [key: result.range(at: 1)]
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

public protocol OutlineHeadingActions {
    func heading(contains location: Int, headings: [HeadingToken]) -> HeadingToken?
}

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
    func didFoundDateAndTime(text: String, rangesData: [[String: NSRange]])
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
    public func didFoundDateAndTime(text: String, rangesData: [[String: NSRange]]) {}
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
