//
//  OutlineParser.swift
//  Iceland
//
//  Created by ian luo on 2018/11/14.
//  Copyright © 2018 wod. All rights reserved.
//
// https://en.wikipedia.org/wiki/Regular_expression

import Foundation

extension NSRange {
    func offset(_ offset: Int) -> NSRange {
        return NSRange(location: self.location + offset, length: self.length)
    }
}

public class OutlineParser {
    public weak var delegate: OutlineParserDelegate?
    
    private func safeSubstring(with str: String, range: NSRange) -> String {
        if range.location != Int.max {
            return (str as NSString).substring(with: range)
        }
        
        return ""
    }
    
    public var includeParsee: ParseeTypes = ParseeTypes.all
    
    public init(delegate: OutlineParserDelegate? = nil) {
        self.delegate = delegate
    }
    
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
                    let headingText = safeSubstring(with: str, range: headingRange)
                    var comp: [String: NSRange] =
                        [Key.Node.heading: headingRange,
                         Key.Element.Heading.level: result.range(at: 1)]
                    
                    [(Key.Element.Heading.planning, Matcher.Element.Heading.planning),
                     (Key.Element.Heading.schedule, Matcher.Element.Heading.schedule),
                     (Key.Element.Heading.due, Matcher.Element.Heading.due),
                     (Key.Element.Heading.tags, Matcher.Element.Heading.tags)]
                        .forEach {
                            if let matcher = $0.1 {
                                if let range = matcher.firstMatch(in: headingText, options: [], range: NSRange(location: 0, length: headingText.count))?
                                    .range(at: 1), range.location != Int.max {
                                    comp[$0.0] = NSRange(location: headingRange.location + range.location, length: range.length)
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
        
        // MARK: checkbox
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
        
        // MARK: code block
        if let codeBlock = Matcher.Node.codeBlock, includeParsee.contains(.codeBlock) {
            let result: [[String: NSRange]] = codeBlock
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.codeBlock] = result.range(at: 0)
                    comp[Key.Element.CodeBlock.language] = result.range(at: 1)
                    comp[Key.Element.CodeBlock.content] = result.range(at: 2)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundCodeBlock(text: str, codeBlockRanges: result)
            }
        }
        
        // MARK: ordered list
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
        
        // MARK: unordered list
        if let unorderedList = Matcher.Node.unorderedList, includeParsee.contains(.unorderedList) {
            let result: [[String: NSRange]] = unorderedList
                .matches(in: str, options: [], range: totalRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[Key.Node.unordedList] = result.range(at: 0)
                    return comp
            }
            
            if result.count > 0 {
                self.logResult(result)
                self.delegate?.didFoundUnOrderedList(text: str, unOrderedListRnages: result)
            }
        }
        
        // MARK: seperator
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
        
        // MARK: attachment
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
        
        // MARK: url
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
        
        // MARK: 最后，带 mark 的文字
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

public protocol OutlineParserDelegate: class {
    func didFoundHeadings(text: String, headingDataRanges: [[String: NSRange]])
    func didFoundCheckbox(text: String, checkboxRanges: [[String: NSRange]])
    func didFoundOrderedList(text: String, orderedListRnages: [[String: NSRange]])
    func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String: NSRange]])
    func didFoundSeperator(text: String, seperatorRanges: [[String: NSRange]])
    func didFoundCodeBlock(text: String, codeBlockRanges: [[String: NSRange]])
    func didFoundAttachment(text: String, attachmentRanges: [[String: NSRange]])
    func didFoundLink(text: String, urlRanges: [[String: NSRange]])
    func didFoundTextMark(text: String, markRanges: [[String: NSRange]])
    func didStartParsing(text: String)
    func didCompleteParsing(text: String)
}

extension OutlineParserDelegate {
    func didFoundHeadings(text: String, headingDataRanges: [[String : NSRange]]) {}
    func didFoundCheckbox(text: String, checkboxRanges: [[String : NSRange]]) {}
    func didFoundOrderedList(text: String, orderedListRnages: [[String : NSRange]]) {}
    func didFoundUnOrderedList(text: String, unOrderedListRnages: [[String : NSRange]]) {}
    func didFoundSeperator(text: String, seperatorRanges: [[String : NSRange]]) {}
    func didFoundCodeBlock(text: String, codeBlockRanges: [[String : NSRange]]) {}
    func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {}
    func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {}
    func didFoundTextMark(text: String, markRanges: [[String : NSRange]]) {}
    func didStartParsing(text: String) {}
    func didCompleteParsing(text: String) {}
}

extension OutlineParser {
    fileprivate func logResult(_ result: [[String: NSRange]]) {
        for dict in result {
            for (key, value) in dict {
//                log.verbose(">>> \(key): \(value)")
            }
        }
    }
}

extension Date {
    public static func createFromSchedule(_ string: String) -> Date? {
        return createFrom(string: string, matcher: OutlineParser.Matcher.Element.Heading.schedule)
    }
    
    public static func createFromDue(_ string: String) -> Date? {
        return createFrom(string: string, matcher: OutlineParser.Matcher.Element.Heading.due)
    }
    
    private static func createFrom(string: String, matcher: NSRegularExpression?) -> Date? {
        if let matcher = matcher {
            if let result = matcher.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                let formatter = DateFormatter()
                let dateString = matcher.replacementString(for: result, in: string, offset: 0, template: "$2")
                formatter.dateFormat = "yyyy-MM-dd EEE HH:mm"
                if let date = formatter.date(from: dateString) {
                    return date
                } else {
                    formatter.dateFormat = "yyyy-MM-dd EEE"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
}
