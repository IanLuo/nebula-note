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
    
    public init(delegate: OutlineParserDelegate? = nil) {
        self.delegate = delegate
    }
    
    
    /// 1. find heading
    /// 2. add attribute for element
    public func parse(str: String, range: NSRange? = nil) {
        let totalRange = range ?? NSRange(location: 0, length: str.count)
        
        self.delegate?.didStartParsing(text: str)
        // MARK: heading， 并且找出 level, planning, schedule, deadline 的 range
        if let heading = Matcher.Node.heading {
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
                     (Key.Element.Heading.deadline, Matcher.Element.Heading.deadline),
                     (Key.Element.Heading.tags, Matcher.Element.Heading.tags)]
                        .forEach {
                            if let planning = $0.1 {
                                if let range = planning
                                    .firstMatch(in: headingText, options: [], range: NSRange(location: 0, length: headingText.count))?
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
        if let checkbox = Matcher.Node.checkbox {
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
        if let codeBlock = Matcher.Node.codeBlock {
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
        if let orderedList = Matcher.Node.ordedList {
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
        if let unorderedList = Matcher.Node.unorderedList {
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
        if let seperator = Matcher.Node.seperator {
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
        if let attachment = Matcher.Node.attachment {
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
        if let url = Matcher.Element.url {
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
                self.delegate?.didFoundURL(text: str, urlRanges: result)
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
    func didFoundURL(text: String, urlRanges: [[String: NSRange]])
    func didFoundTextMark(text: String, markRanges: [[String: NSRange]])
    func didStartParsing(text: String)
    func didCompleteParsing(text: String)
}

extension OutlineParser {
    private struct Matcher {
        public struct Node {
            public static var heading = try? NSRegularExpression(pattern: RegexPattern.Node.heading, options: [.anchorsMatchLines])
            public static var checkbox = try? NSRegularExpression(pattern: RegexPattern.Node.checkBox, options: [.anchorsMatchLines])
            public static var ordedList = try? NSRegularExpression(pattern: RegexPattern.Node.orderedList, options: [.anchorsMatchLines])
            public static var unorderedList = try? NSRegularExpression(pattern: RegexPattern.Node.unorderedList, options: [.anchorsMatchLines])
            public static var codeBlock = try? NSRegularExpression(pattern: RegexPattern.Node.codeBlock, options: [.anchorsMatchLines])
            public static var seperator = try? NSRegularExpression(pattern: RegexPattern.Node.seperator, options: [.anchorsMatchLines])
            public static var attachment = try? NSRegularExpression(pattern: RegexPattern.Node.attachment, options: [])
        }
        
        public struct Element {
            public struct Heading {
                public static var planning = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.planning, options: [])
                public static var schedule = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.schedule, options: [])
                public static var deadline = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.deadline, options: [])
                public static var tags = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.tags, options: [])
            }
            
            public struct TextMark {
                public static var bold = try? NSRegularExpression(pattern: RegexPattern.Element.TextMark.bold, options: [])
                public static var itatic = try? NSRegularExpression(pattern: RegexPattern.Element.TextMark.italic, options: [])
                public static var underscore = try? NSRegularExpression(pattern: RegexPattern.Element.TextMark.underscore, options: [])
                public static var strikthrough = try? NSRegularExpression(pattern: RegexPattern.Element.TextMark.strikeThough, options: [])
                public static var verbatim = try? NSRegularExpression(pattern: RegexPattern.Element.TextMark.verbatim, options: [])
                public static var code = try? NSRegularExpression(pattern: RegexPattern.Element.TextMark.code, options: [])
            }
            
            public static var url = try? NSRegularExpression(pattern: RegexPattern.Element.link, options: [])
        }
    }
    
    public struct Key {
        public struct Node {
            public static let heading = "heading"
            public static let checkbox = "checkbox"
            public static let ordedList = "ordedList"
            public static let unordedList = "unordedList"
            public static let codeBlock = "codeBlock"
            public static let seperator = "seperator"
            public static let attachment = "attachment"
        }
        
        public struct Element {
            public struct Heading {
                public static let level = "level"
                public static let planning = "planning"
                public static let schedule = "schedule"
                public static let deadline = "deadline"
                public static let tags = "tags"
            }
            
            public struct Checkbox {
                public static let status = "status"
            }
            
            public struct CodeBlock {
                public static let language = "language"
                public static let content = "content"
            }
            
            public struct OrderedList {
                public static let index = "index"
            }
            
            public struct Attachment {
                public static let type = "type"
                public static let value = "value"
            }
            
            public struct Link {
                public static let title = "title"
                public static let url = "url"
                public static let scheme = "scheme"
            }
            
            public struct TextMark {
                public static let bold = "bold"
                public static let italic = "italic"
                public static let underscore = "underscore"
                public static let strikeThough = "strikeThough"
                public static let verbatim = "verbatim"
                public static let code = "code"
            }
            
            public static let paragraph = "paragraph"
            public static let image = "image"
            public static let audio = "audio"
            public static let video = "video"
            public static let sketch = "sketch"
            public static let location = "location"
            public static let link = "link"
        }
    }
    
    public struct RegexPattern {
        public struct Node {
            public static let heading = "^(\\*+) (.+)"
            // FIXME: 如果 BEGIN 和 END 内部没有至少一个空行，则无法匹配成功
            public static let codeBlock =       "^[\\t ]*\\#\\+BEGIN\\_SRC( [0-9a-zA-Z\\.]*)?\\n([^\\#\\+END\\_SRC]*)\\n\\s*\\#\\+END\\_SRC[\\t ]*\\n"
            public static let checkBox =        "^[\\t ]*(\\- \\[[x| |\\-]\\]) .+"
            public static let unorderedList =   "^[\\t ]*[\\-\\+] .+"
            public static let orderedList =     "^[\\t ]*([0-9a-zA-Z\\.])+[\\.\\)\\>] .*"
            public static let seperator =       "^[\\t ]*(\\-{5,}[\\t ]*)"
            public static let attachment =      "\\/\\/Attachment\\:(image|video|audio|sketch|location)\\=([^\\=\\n]+)" // like: //Attachment:image=xdafeljlfjeksjdf
        }
        
        public struct Element {
            public struct Heading {
                public static let schedule =    " (SCHEDULE\\:\\[[0-9]{4}\\-[0-9]{2}\\-[0-9]{2}\\])"
                public static let deadline =    " (DEADLINE\\:\\[[0-9]{4}\\-[0-9]{2}\\-[0-9]{2}\\])"
                public static let planning =    "(TODO|NEXT|DONE|CANCELD) ?"
                public static let tags =        " (\\:([a-zA-Z0-9]+\\:)+)"
            }
            
            public struct TextMark {
                private static let pre =            "[ \\(\\{\\'\\\"]?"
                private static let post =           "[ \\-\\.\\,\\:\\!\\?\\'\\)\\}\\\"]?"
                public static let bold =            "\(pre)(\\*[^\\n\\,\\'\\\"\\*]+\\*)\(post)"
                public static let italic =          "\(pre)(\\/[^\\n\\,\\'\\\"\\/]+\\/)\(post)"
                public static let underscore =      "\(pre)(\\_[^\\n\\,\\'\\\"\\_]+\\_)\(post)"
                public static let strikeThough =    "\(pre)(\\+[^\\n\\,\\'\\\"\\+]+\\+)\(post)"
                public static let verbatim =        "\(pre)(\\=[^\\n\\,\\'\\\"\\=]+\\=)\(post)"
                public static let code =            "\(pre)(\\~[^\\n\\,\\'\\\"\\~]+\\~)\(post)"
            }
            
            public static let link = "\\[\\[((http|https)\\:\\/\\/.*)\\]\\[(.*)\\]\\]"
        }
        
    }
    
}


extension OutlineParser {
    fileprivate func logResult(_ result: [[String: NSRange]]) {
        for dict in result {
            for (key, value) in dict {
                print(">>> \(key): \(value)")
            }
        }
    }
}
