//
//  OutlineParserMatcher.swift
//  Iceland
//
//  Created by ian luo on 2018/11/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

extension OutlineParser {
    public struct Matcher {
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
            public static let checkBox =        "^[\\t ]*(\\- \\[[x| |\\-]\\]) .*"
            public static let unorderedList =   "^[\\t ]*[\\-\\+] .*"
            public static let orderedList =     "^[\\t ]*([0-9a-zA-Z\\.])+[\\.\\)\\>] .*"
            public static let seperator =       "^[\\t ]*(\\-{5,}[\\t ]*)"
            public static let attachment =      "\\/\\/Attachment\\:(image|video|audio|sketch|location)\\=([^\\=\\n]+)" // like: //Attachment:image=xdafeljlfjeksjdf
        }
        
        public struct Element {
            public struct Heading {
                public static let schedule =    " (SCHEDULE\\:\\[[0-9]{4}\\-[0-9]{1,2}\\-[0-9]{1,2}\\])"
                public static let deadline =    " (DEADLINE\\:\\[[0-9]{4}\\-[0-9]{1,2}\\-[0-9]{1,2}\\])"
                public static let planning =    " (TODO|NEXT|DONE|CANCELD)? "
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
    
    public struct Values {
        public struct Checkbox {
            public static let unchecked: String = "- [ ]"
            public static let checked: String = "- [x]"
            public static let halfChecked: String = "- [-]"
        }
    }
}

