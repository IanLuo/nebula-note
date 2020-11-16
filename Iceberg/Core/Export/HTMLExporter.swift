//
//  HTMLExporter.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface

private let tokenIgnore = "IGNORE"

public struct HTMLExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "html"
    
    private let _editorContext: EditorContext
    
    private let useDefaultStyle: Bool
    
    public init(editorContext: EditorContext, url: URL, useDefaultStyle: Bool = true) {
        self.useDefaultStyle = useDefaultStyle
        self._editorContext = editorContext
        self.url = url
    }
    
    public func export(isMember: Bool, completion: @escaping (ExportResult) -> Void) {
        let service = self._editorContext.request(url: self.url)
        
        var headingIndexs: [[Int]] = []
        
        service.onReadyToUse = { service in
            service.open { string in
                
                for token in service.headings {
                    if let last = headingIndexs.last {
                        let indexLevel = token.level
                        if last.count == indexLevel {
                            var newArray = last
                            let last = newArray.remove(at: newArray.count - 1) + 1
                            newArray.append(last)
                            headingIndexs.append(newArray)
                        } else if last.count > indexLevel {
                            let index = last[indexLevel - 1]
                            var newArray: [Int] = last.dropLast(last.count - indexLevel + 1)
                            newArray.append(index + 1)
                            headingIndexs.append(newArray)
                        } else { //  last.count < indexLevel
                            var newArray = last
                            newArray.append(1)
                            headingIndexs.append(newArray)
                        }
                    } else {
                        headingIndexs.append([1])
                    }
                }
                
                var result = string ?? ""
                for token in service.allTokens.reversed() { // 从尾部开始替换，否则会导致 range 错误
                    var tokenString = token.render(string: string ?? "", useDefaultStyle: self.useDefaultStyle)
                    
                    guard tokenString != tokenIgnore else { continue }
                    
                    guard !token.isEmbeded else { continue }
                    
                    // 是否导出段落序号
                    if let _ = token as? HeadingToken, SettingsAccessor.Item.exportShowIndex.get(Bool.self) ?? true {
                        if let indexs = headingIndexs.last {
                            let index = indexs.map { "\($0)" }.joined(separator: ".") + " "
                            tokenString.insert(contentsOf: index, at: tokenString.index(tokenString.startIndex, offsetBy: 4))
                            headingIndexs.remove(at: headingIndexs.count - 1)
                        }
                    }
                    
                    if result.nsstring.substring(with: token.range) != tokenString {
                        result = result.nsstring.replacingCharacters(in: token.range, with: tokenString)
                    }
                }
                
                result = result.replacingOccurrences(of: "\n", with: "<br>").replacingOccurrences(of: "\t", with: "&ensp;&ensp;&ensp;&ensp;")
                
                result.insert(contentsOf: "<!DOCTYPE html><html><meta charset=\"utf-8\"/><head>\(self.style)</head><body><article>", at: result.startIndex)
                result.append("</article>")
                if !isMember {
                    result.append(self.footer)
                }
                result.append("</body></html>")
                
                completion(.string(result))
            }
        }
    }
    
    var footer: String {
        """
        <div class=\"footer\">
        <span style=\"vertical-align: middle;\">Create with x3 note</span> <img style=\"width:50px;height:50px\" src='https://forum.x3note.site/uploads/default/original/1X/45488f32835fad7e6401d391b89392d3a4498610.png'")></img>
        </div>
        """
    }
    
    var style: String {
        guard self.useDefaultStyle else { return "" }
        
        return """
        <style>
        body { background-color: \(InterfaceTheme.Color.background1.hex); color: \(InterfaceTheme.Color.descriptive.hex); padding-left: 30px; padding-right: 30px; padding-top: 120px; padding-bottom: 120px;height:100%; min-height:100%;}
        h1   {color: \(InterfaceTheme.Color.interactive.hex);}
        h2   {color: \(InterfaceTheme.Color.interactive.hex);}
        h3   {color: \(InterfaceTheme.Color.interactive.hex);}
        h4   {color: \(InterfaceTheme.Color.interactive.hex);}
        h5   {color: \(InterfaceTheme.Color.interactive.hex);}
        h6   {color: \(InterfaceTheme.Color.interactive.hex);}

        mark {
          background-color: \(InterfaceTheme.Color.spotlight.hex);
          color: \(InterfaceTheme.Color.spotlitTitle.hex);
        }
        .quote {
          position: relative;
          left: 7px;
          background: \(InterfaceTheme.Color.background2.hex);
          box-shadow: -2px 0 0 \(InterfaceTheme.Color.spotlight.hex),
                      -4px 0 0 \(InterfaceTheme.Color.spotlight.hex),
                      -7px 0 0 \(InterfaceTheme.Color.spotlight.hex);
        }
        blockquote {
          background: white;
          padding: 20px 30px 20px 30px;
          margin: 50px auto;
          width: 90%;
        }
        .wrapper {
          margin: 0 auto;
          width: 90%;
          padding-bottom: 50px;
        }
        .footer {
            text-align: right;
            clear: both;
            position: relative;
            height: 50px;
            margin-top: 0px;
        }
        .footer > * {
          vertical-align: middle;
        }
        </style>
"""
    }
    
}

extension UIColor {
    var hex: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#ffffff"
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
}
 
extension HTMLExporter {
    fileprivate func styleString(for style: InterfaceTheme) -> String {
        let style = ""
        return style
    }
}

extension Token {
    fileprivate func render(string: String, useDefaultStyle: Bool) -> String {
        func style(_ style: String) -> String {
            if useDefaultStyle {
                return style
            } else {
                return ""
            }
        }
        
        if self is BlockBeginToken {
            return tokenIgnore
        }
        
        if let heading = self as? HeadingToken {
            return "<h\(heading.level)>\(string.nsstring.substring(with: heading.headingTextRange))</h\(heading.level)>"
        } else if let quoteBlock = self as? BlockEndToken, quoteBlock.blockType == .quote {
            return "<br><div \(style("class=\"wrapper\""))><blockquote \(style("class=\"quote\""))><p>\(string.nsstring.substring(with: quoteBlock.contentRange!))</p></blockquote></div>"
        } else if let quoteBlock = self as? BlockEndToken, quoteBlock.blockType == .sourceCode {
            return "<br><div \(style("class=\"wrapper\""))><blockquote \(style("class=\"quote\""))><p>\(string.nsstring.substring(with: quoteBlock.contentRange!))</p></blockquote></div>"
        } else if let link = self as? LinkToken {
            if let titleRange = link.range(for: OutlineParser.Key.Element.Link.title),
                let urlRange = link.range(for: OutlineParser.Key.Element.Link.url) {
                let title = string.nsstring.substring(with: titleRange)
                let url = string.nsstring.substring(with: urlRange)
                
                if link.isDocumentLink(string: string) {
                    return "<a href='#'>\(title)</a>"
                } else {
                    return "<a href='\(url)'>\(title)</a>"
                }
            } else {
                return string.nsstring.substring(with: self.range)
            }
        } else if let attachmentToken = self as? AttachmentToken {
            guard let typeRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.type) else { return ""}
            guard let valueRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.value) else { return ""}
            
            let type = string.nsstring.substring(with: typeRange)
            let value = string.nsstring.substring(with: valueRange)
            
            if type == Attachment.Kind.image.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                let tempURL = URL.directory(location: URLLocation.temporary).appendingPathComponent(url.lastPathComponent)
                try? Data(contentsOf: url).write(to: tempURL)
                return "<br><img src=\"\(tempURL.lastPathComponent)\" style=\"max-width:600px;width:100%\"/>"
            } else if type == Attachment.Kind.sketch.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                let tempURL = URL.directory(location: URLLocation.temporary).appendingPathComponent(url.lastPathComponent)
                try? Data(contentsOf: url).write(to: tempURL)
                return "<br><img src=\"\(tempURL.lastPathComponent)\" style=\"max-width:600px;width:100%\"/>"
            } else if type == Attachment.Kind.audio.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                let tempURL = URL.directory(location: URLLocation.temporary).appendingPathComponent(url.lastPathComponent)
                try? Data(contentsOf: url).write(to: tempURL)
                return "<br><audio controls style=\"max-width:600px;width:100%\" src=\"\(tempURL.lastPathComponent)\"></audio>"
            } else if type == Attachment.Kind.video.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                let tempURL = URL.directory(location: URLLocation.temporary).appendingPathComponent(url.lastPathComponent)
                try? Data(contentsOf: url).write(to: tempURL)
                return "<br><video controls src=\"\(tempURL.lastPathComponent)\" style=\"max-width:600px;width:100%\"></video>"
            } else {
                return "<!--\(type):\(value)--!>"
            }
        } else if let textMark = self as? TextMarkToken, let contentRange = textMark.range(for: OutlineParser.Key.Element.TextMark.content) {
            let content = string.nsstring.substring(with: contentRange)
            switch textMark.name {
            case OutlineParser.Key.Element.TextMark.bold:
                return "<b>\(content)</b>"
            case OutlineParser.Key.Element.TextMark.italic:
                return "<i>\(content)</i>"
            case OutlineParser.Key.Element.TextMark.strikeThough:
                return "<span \(style("style=\"text-decoration: line-through;\""))>\(content)</span>"
            case OutlineParser.Key.Element.TextMark.underscore:
                return "<span \(style("style=\"text-decoration: underline;\""))>\(content)</span>"
            case OutlineParser.Key.Element.TextMark.highlight:
                return "<mark>\(content)</mark>"
            default: return string.nsstring.substring(with: self.range)
            }
        } else if self is SeparatorToken {
            return "<hr>"
        } else if let orderedList = self as? OrderedListToken {
            return "<li>\(string.nsstring.substring(with: orderedList.range).nsstring.replacingCharacters(in: orderedList.prefix.offset(-orderedList.range.location), with: ""))</li>"
        } else if let unorderedList = self as? UnorderdListToken {
            return "<li>\(string.nsstring.substring(with: unorderedList.range).nsstring.replacingCharacters(in: unorderedList.prefix.offset(-unorderedList.range.location), with: ""))</li>"
        } else if let checkbox = self as? CheckboxToken {
            let checkStatusString = string.nsstring.substring(with: checkbox.range(for: "status")!) == OutlineParser.Values.Checkbox.checked ? "checked" : ""
            let statusString = "<br><input type=\"checkbox\" \(checkStatusString) disabled/> "
            return string.nsstring.substring(with: checkbox.range(for: "checkbox")!).nsstring.replacingCharacters(in: checkbox.range(for: "status")!.offset(-checkbox.range.location), with: statusString)
        }  else {
            return string.nsstring.substring(with: self.range)
        }
    }
}
