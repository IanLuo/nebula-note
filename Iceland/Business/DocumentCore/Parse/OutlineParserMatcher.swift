//
//  OutlineParserMatcher.swift
//  Iceland
//
//  Created by ian luo on 2018/11/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

extension OutlineParser {
    
    public enum MarkType {
        case bold
        case italic
        case underscore
        case strikethrough
        case code
        case verbatim
        
        public var mark: String {
            switch self {
            case .bold: return OutlineParser.Values.TextMark.bold
            case .italic: return OutlineParser.Values.TextMark.italic
            case .underscore: return OutlineParser.Values.TextMark.underscore
            case .strikethrough: return OutlineParser.Values.TextMark.strikthought
            case .code: return OutlineParser.Values.TextMark.code
            case .verbatim: return OutlineParser.Values.TextMark.verbatim
            }
        }
    }
    
    public struct ParseeTypes: OptionSet {
        public init(rawValue: Int64) { self.rawValue = rawValue }
        public let rawValue: Int64
        
        public static let heading: ParseeTypes = ParseeTypes(rawValue: 1 << 0)
        public static let checkbox: ParseeTypes = ParseeTypes(rawValue: 1 << 1)
        public static let orderedList: ParseeTypes = ParseeTypes(rawValue: 1 << 2)
        public static let unorderedList: ParseeTypes = ParseeTypes(rawValue: 1 << 3)
        public static let seperator: ParseeTypes = ParseeTypes(rawValue: 1 << 4)
        public static let attachment: ParseeTypes = ParseeTypes(rawValue: 1 << 5)
        public static let link: ParseeTypes = ParseeTypes(rawValue: 1 << 6)
        public static let footnote: ParseeTypes = ParseeTypes(rawValue: 1 << 7)
        public static let codeBlockBegin: ParseeTypes = ParseeTypes(rawValue: 1 << 8)
        public static let codeBlockEnd: ParseeTypes = ParseeTypes(rawValue: 1 << 9)
        public static let quoteBlockBegin: ParseeTypes = ParseeTypes(rawValue: 1 << 10)
        public static let quoteBlockEnd: ParseeTypes = ParseeTypes(rawValue: 1 << 11)
        
        public static let all: ParseeTypes = [.heading, .checkbox, orderedList, unorderedList, seperator, attachment, link, .footnote, .codeBlockBegin, .codeBlockEnd, .quoteBlockBegin, .quoteBlockEnd]
        public static let onlyHeading: ParseeTypes = [.checkbox, orderedList, unorderedList, seperator, attachment, link, .footnote]
    }
    
    public struct Matcher {
        public struct Node {
            public static var heading = try? NSRegularExpression(pattern: RegexPattern.Node.heading, options: [.anchorsMatchLines])
            public static var checkbox = try? NSRegularExpression(pattern: RegexPattern.Node.checkBox, options: [])
            public static var ordedList = try? NSRegularExpression(pattern: RegexPattern.Node.orderedList, options: [.anchorsMatchLines])
            public static var unorderedList = try? NSRegularExpression(pattern: RegexPattern.Node.unorderedList, options: [.anchorsMatchLines])
            public static var seperator = try? NSRegularExpression(pattern: RegexPattern.Node.seperator, options: [.anchorsMatchLines])
            public static var attachment = try? NSRegularExpression(pattern: RegexPattern.Node.attachment, options: [])
            public static var footnote = try? NSRegularExpression(pattern: RegexPattern.Node.footnote, options: [.anchorsMatchLines])
            public static var codeBlockBegin = try? NSRegularExpression(pattern: RegexPattern.Element.CodeBlock.begin, options: [.anchorsMatchLines])
            public static var codeBlockEnd = try? NSRegularExpression(pattern: RegexPattern.Element.CodeBlock.end, options: [.anchorsMatchLines])
            public static var quoteBlockBegin = try? NSRegularExpression(pattern: RegexPattern.Element.QuoteBlock.begin, options: [.anchorsMatchLines])
            public static var quoteBlockEnd = try? NSRegularExpression(pattern: RegexPattern.Element.QuoteBlock.end, options: [.anchorsMatchLines])
        }
        
        public struct Element {
            public struct Heading {
                public static var planning = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.planning, options: [])
                public static var schedule = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.schedule, options: [])
                public static var due = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.due, options: [])
                public static var timeRange = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.timeRangePattern, options: [])
                public static var dateRange = try? NSRegularExpression(pattern: RegexPattern.Element.Heading.dateAndTimeRange, options: [])
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
            
            public static var link = try? NSRegularExpression(pattern: RegexPattern.Element.link, options: [])
        }
    }
    
    public struct Key {
        public struct Node {
            public static let heading = "heading"
            public static let checkbox = "checkbox"
            public static let ordedList = "ordedList"
            public static let unordedList = "unordedList"
            public static let seperator = "seperator"
            public static let attachment = "attachment"
            public static let footnode = "footnode"
            public static let codeBlockBegin = "codeBlockBegin"
            public static let codeBlockEnd = "codeBlockEnd"
            public static let quoteBlockBegin = "quoteBlockBegin"
            public static let quoteBlockEnd = "codeBlockEnd"
        }
        
        public struct Element {
            public struct Heading {
                public static let level = "level"
                public static let planning = "planning"
                public static let schedule = "schedule"
                public static let scheduleDateAndTime = "scheduleDateAndTime"
                public static let timeRange = "timeRange"
                public static let dateRange = "dateRange"
                public static let closed = "closed" // 暂时没有使用
                public static let due = "due"
                public static let dueDateAndTime = "dueDateAndTime"
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
            
            public struct UnorderedList {
                public static let prefix = "prefix"
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
                public static let content = "content"
                public static let mark = "mark"
                public static let bold = "bold"
                public static let italic = "italic"
                public static let underscore = "underscore"
                public static let strikeThough = "strikeThough"
                public static let verbatim = "verbatim"
                public static let code = "code"
            }
            
            public struct Quote {
                public static let begin = "begin"
                public static let end = "end"
                public static let content = "content"
            }
            
            public struct Footnote {
                public static let content = "content"
            }
            
            public static let paragraph = "paragraph" // 普通文字
            public static let image = "image"
            public static let audio = "audio"
            public static let video = "video"
            public static let sketch = "sketch"
            public static let location = "location"
            public static let link = "link"
        }
    }
    
    public struct RegexPattern {
        private static let character = "\\p{L}"
        
        public struct Node {
            public static let heading =         "^(\\*+) (.)+(([\\t ])+\(Element.Heading.schedule)|([\\t ])+\(Element.Heading.due)){0,2}"
            public static let codeBlock =       "^[\\t ]*\\#\\+BEGIN\\_SRC( [\(character)\\.]*)?\\n([^\\#\\+END\\_SRC]*)\\n\\s*\\#\\+END\\_SRC[\\t ]*\\n"
            public static let checkBox =        "[\\t ]* \\[(X| |\\-)\\]"
            public static let unorderedList =   "^[\\t ]*([\\-\\+]) .*"
            public static let orderedList =     "^[\\t ]*([a-zA-Z0-9]+[\\.\\)\\>]) .*"
            public static let seperator =       "^[\\t ]*(\\-{5,}[\\t ]*)"
            public static let attachment =      "\\#\\+ATTACHMENT\\:(image|video|audio|sketch|location)=([A-Z0-9\\-]+)" // like: #+ATTACHMENT:LKS-JDLF-JSDL-JFLSDF)
            public static let quote =           "^[\\t ]*\\#\\+BEGIN\\_QUOTE\\n([^\\#\\+END\\_QUOTE]*)\\n\\s*\\#\\+END\\_QUOTE[\\t ]*\\n"
            public static let footnote =        "" // TODO: footnote regex pattern imp
        }
        
        public struct Element {
            public struct CodeBlock {
                public static let begin =           "^[\\t ]*\\#\\+BEGIN\\_SRC( [\(character)\\.]*)?[\\t ]*"
                public static let end =             "^[\\t ]*\\#\\+END\\_SRC[\\t ]*"
            }
            
            public struct QuoteBlock {
                public static let begin =           "^[\\t ]*\\#\\+BEGIN\\_QUOTE[\\t ]*"
                public static let end =             "^[\\t ]*\\#\\+END\\_QUOTE[\\t ]*"
            }
            
            public struct Heading {
                private static let timePattern =            "[0-9]{1,2}\\:[0-9]{1,2}"
                private static let dateRepeatPattern =      "\\+[0-9]+(d|w|m|y){1}"
                private static let weekdayPattern =         "[A-Z]{1}[a-z]{2}"
                public static let dateAndTimePattern =     "\\<\\d{4}\\-\\d{1,2}\\-\\d{1,2}( \(weekdayPattern))?( (\(timePattern)))?( \(dateRepeatPattern))?\\>"
                public static let dateAndTimeRange =        "(\(dateAndTimePattern))\\-\\-(\(dateAndTimePattern))"
                public static let timeRangePattern =       "\\<(\\d{4}\\-\\d{1,2}\\-\\d{1,2}( \(weekdayPattern))?) (\(timePattern))\\-(\(timePattern))"
                public static let schedule =                "(SCHEDULED\\: (\(dateAndTimePattern)))"
                public static let due =                     "(DEADLINE\\: (\(dateAndTimePattern)))"
                public static let planning =                " (\(Values.Heading.Planning.pattern))? "
                public static let tags =                    "(\\:([a-zA-Z0-9]+\\:)+)"
            }
            
            public struct TextMark {
                private static let ignoredCharacters: String = "\\n\\,\\'\\\""
                private static let pre =            "[ \\(\\{\\'\\\"]?"
                private static let post =           "[ \\-\\.\\,\\:\\!\\?\\'\\)\\}\\\"]?"
                public static let bold =            "\(pre)(\\*([^\(ignoredCharacters)\\*]+)\\*)\(post)"
                public static let italic =          "\(pre)(\\/([^\(ignoredCharacters)\\/]+)\\/)\(post)"
                public static let underscore =      "\(pre)(\\_([^\(ignoredCharacters)\\_]+)\\_)\(post)"
                public static let strikeThough =    "\(pre)(\\+([^\(ignoredCharacters)\\+]+)\\+)\(post)"
                public static let verbatim =        "\(pre)(\\=([^\(ignoredCharacters)\\=]+)\\=)\(post)"
                public static let code =            "\(pre)(\\~([^\(ignoredCharacters)\\~]+)\\~)\(post)"
            }
            
            public static let link = "\\[\\[((http|https|file)\\:.*)\\]\\[(.*)\\]\\]"
        }
    }
    
    public struct Values {
        public struct TextMark {
            public static let bold = "*"
            public static let italic = "/"
            public static let underscore = "_"
            public static let strikthought = "+"
            public static let code = "~"
            public static let verbatim = "="
        }
        
        public static let separator: String = "\n-----\n"
        
        public struct Character {
            public static let linebreak = "\n"
            public static let tab = "\t"
        }
        
        public struct Attachment {
            public static func serialize(attachment: Business.Attachment) -> String {
                switch attachment.kind {
                case .text:
                    do { return try String(contentsOf: attachment.url) }
                    catch { return "\(error)" }
                case .link:
                    do {
                        if let json = try JSONSerialization.jsonObject(with: Data(contentsOf: attachment.url), options: []) as? NSDictionary {
                            let title = json["title"] ?? ""
                            let url = json["link"] ?? ""
                            return "[[\(url)][\(title)]]"
                        } else {
                            return "#<wrong form of link>"
                        }
                    } catch {
                        return "\(error)"
                    }
                default:
                    return "#+ATTACHMENT:\(attachment.kind.rawValue)=\(attachment.key)"
                }
            }
            
            public static func serialize(kind: String , value: String) -> String {
                return "#+ATTACHMENT:\(kind)=\(value)"
            }
        }
        
        public struct Checkbox {
            public static let unchecked: String = "[ ]"
            public static let checked: String = "[X]"
            public static let halfChecked: String = "[-]"
        }
        
        public struct Heading {
            public static let level: String = "*"
            public struct Planning {
                public static let todo: String = "TODO"
                public static let done: String = "DONE"
                public static let canceled: String = "CANCELED"
                public static var all: [String] = {
                    var plannings = [todo, done, canceled]
                    if let customized = SettingsAccessor.shared.customizedPlannings {
                        plannings.append(contentsOf: customized)
                    }
                    return plannings
                }()
                
                public static var pattern: String = {
                    var plannings = "\(todo)|\(done)|\(canceled)"
                    if let customized = SettingsAccessor.shared.customizedPlannings {
                        plannings.append("|")
                        plannings.append(customized.joined(separator: "|"))
                    }
                    return plannings
                }()
            }
            
            public struct Tag {
                public static let archive: String = "ARCHIVE"
            }
        }
    }
}

