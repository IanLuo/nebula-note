//
//  MarkdownExporter.swift
//  Core
//
//  Created by ian luo on 2020/2/9.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation

public struct MarkdownExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "md"
    
    private let _editorContext: EditorContext
    
    public init(editorContext: EditorContext, url: URL) {
        self._editorContext = editorContext
        self.url = url
    }
    
    public func export(isMember: Bool, completion: @escaping (ExportResult) -> Void) {
        let service = self._editorContext.request(url: self.url)

        service.onReadyToUse = { service in
            service.open { string in
                
                var result = string ?? ""
                for token in service.allTokens.reversed() { // 从尾部开始替换，否则会导致 range 错误
                    let tokenString = token.render(string: string ?? "")
                    
                    result = result.nsstring.replacingCharacters(in: token.range, with: tokenString)
                }
                
                completion(.string(result))
            }
        }
    }
}

extension Token {
    fileprivate func render(string: String) -> String {
        if let heading = self as? HeadingToken {
            var headingMark = ""
            for _ in 0..<heading.level {
                headingMark.append("#")
            }
            return "\(headingMark) \(string.nsstring.substring(with: heading.headingTextRange))\n"
        } else if let orderedList = self as? OrderedListToken {
            return "- \(string.nsstring.substring(with: orderedList.range).nsstring.replacingCharacters(in: orderedList.prefix.offset(-orderedList.range.location), with: ""))\n"
        } else if let unorderedList = self as? UnorderdListToken {
            return "- \(string.nsstring.substring(with: unorderedList.range).nsstring.replacingCharacters(in: unorderedList.prefix.offset(-unorderedList.range.location), with: ""))\n"
        } else if let quoteBlock = self as? BlockBeginToken, quoteBlock.blockType == .quote {
            return string.nsstring.substring(with: quoteBlock.contentRange!).components(separatedBy: "\n").map {
                "> \($0)\n"
            }.joined(separator: "")
        } else if let checkbox = self as? CheckboxToken {
            let checkStatusString = string.nsstring.substring(with: checkbox.range(for: "status")!) == OutlineParser.Values.Checkbox.checked ? "[x]" : "[ ]"
            let statusString = checkStatusString
            return "\n" + string.nsstring.substring(with: checkbox.range(for: "checkbox")!).nsstring.replacingCharacters(in: checkbox.range(for: "status")!.offset(-checkbox.range.location), with: statusString)
        }  else if let quoteBlock = self as? BlockBeginToken, quoteBlock.blockType == .sourceCode {
            return "\n```\n\(string.nsstring.substring(with: quoteBlock.contentRange!))\n```\n"
        } else if let link = self as? LinkToken {
            if let titleRange = link.range(for: OutlineParser.Key.Element.Link.title),
                let urlRange = link.range(for: OutlineParser.Key.Element.Link.url) {
                let title = string.nsstring.substring(with: titleRange)
                let url = string.nsstring.substring(with: urlRange)
                return "[\(title)](\(url))"
            }
            return string.nsstring.substring(with: self.range)
        } else if let textMark = self as? TextMarkToken, let contentRange = textMark.range(for: OutlineParser.Key.Element.TextMark.content) {
            let content = string.nsstring.substring(with: contentRange)
            switch textMark.name {
            case OutlineParser.Key.Element.TextMark.bold:
                return "**\(content)**"
            case OutlineParser.Key.Element.TextMark.italic:
                return "*\(content)*"
            case OutlineParser.Key.Element.TextMark.strikeThough:
                return "~~\(content)~~"
            case OutlineParser.Key.Element.TextMark.underscore:
                return "\\_\(content)\\_"
            case OutlineParser.Key.Element.TextMark.highlight:
                return "`\(content)`"
            default: return string.nsstring.substring(with: self.range)
            }
        } else if self is SeparatorToken {
            return "---"
        } else if let attachmentToken = self as? AttachmentToken {
            guard let typeRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.type) else { return ""}
            guard let valueRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.value) else { return ""}
            
            let type = string.nsstring.substring(with: typeRange)
            let value = string.nsstring.substring(with: valueRange)
            
            if type == Attachment.Kind.image.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                return "![](\(url.lastPathComponent))"
            } else if type == Attachment.Kind.sketch.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                return "![](\(url.lastPathComponent))"
            } else {
                return "\(type):\(value)"
            }
        } else {
            return string.nsstring.substring(with: self.range)
        }
    }
}
