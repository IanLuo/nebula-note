//
//  HTMLExporter.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface

public struct HTMLExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "html"
    
    private let _editorContext: EditorContext
    
    public init(editorContext: EditorContext, url: URL) {
        self._editorContext = editorContext
        self.url = url
    }
    
    public func export(completion: @escaping (ExportResult) -> Void) {
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
                    var tokenString = token.render(string: string ?? "")
                    
                    if let _ = token as? HeadingToken, SettingsAccessor.Item.exportShowIndex.get(Bool.self) ?? true {
                        if let indexs = headingIndexs.last {
                            let index = indexs.map { "\($0)" }.joined(separator: ".") + " "
                            tokenString.insert(contentsOf: index, at: tokenString.index(tokenString.startIndex, offsetBy: 4))
                            headingIndexs.remove(at: headingIndexs.count - 1)
                        }
                    }
                    
                    result = result.nsstring.replacingCharacters(in: token.range, with: tokenString)
                }
                
                result.insert(contentsOf: "<!DOCTYPE html><html><meta charset=\"utf-8\"/><head>\(self.style)</head>", at: result.startIndex)
                result.append("</html>")
                
                completion(.string(result))
            }
        }
    }
    
    var style: String {
        return """
        <style>
        body { background-color: \(InterfaceTheme.Color.background1.hex); color: \(InterfaceTheme.Color.descriptive.hex); padding-left: 30px; padding-right: 30px; padding-top: 120px; padding-bottom: 120px;}
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
    fileprivate func render(string: String) -> String {
        if let heading = self as? HeadingToken {
            return "<h\(heading.level)>\(string.nsstring.substring(with: heading.headingTextRange))</h\(heading.level)>"
        } else if let orderedList = self as? OrderedListToken {
            return "<li>\(string.nsstring.substring(with: orderedList.range).nsstring.replacingCharacters(in: orderedList.prefix.offset(-orderedList.range.location), with: ""))</li>"
        } else if let unorderedList = self as? UnorderdListToken {
            return "<li>\(string.nsstring.substring(with: unorderedList.range).nsstring.replacingCharacters(in: unorderedList.prefix.offset(-unorderedList.range.location), with: ""))</li>"
        } else if let checkbox = self as? CheckboxToken {
            let checkStatusString = string.nsstring.substring(with: checkbox.range(for: "checkbox")!) == OutlineParser.Values.Checkbox.checked ? "checked" : ""
            return "<br><input type=\"checkbox\" \(checkStatusString)>"
        } else if let quoteBlock = self as? BlockBeginToken, quoteBlock.blockType == .quote {
            return "<q>\(string.nsstring.substring(with: quoteBlock.contentRange!))</q>"
        } else if let attachmentToken = self as? AttachmentToken {
            guard let typeRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.type) else { return ""}
            guard let valueRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.value) else { return ""}
            
            let type = string.nsstring.substring(with: typeRange)
            let value = string.nsstring.substring(with: valueRange)
            
            if type == Attachment.Kind.image.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                return "<br><img src=\"\(url.absoluteString)\" style=\"max-width:600px;width:100%\"/>"
            } else if type == Attachment.Kind.sketch.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                return "<br><img src=\"\(url.absoluteString)\" style=\"max-width:600px;width:100%\"/>"
            } else {
                return "#\(type):\(value)#"
            }
        } else if let textMark = self as? TextMarkToken, let contentRange = textMark.range(for: OutlineParser.Key.Element.TextMark.content) {
            let content = string.nsstring.substring(with: contentRange)
            switch textMark.name {
            case OutlineParser.Key.Element.TextMark.bold:
                return "<b>\(content)</b>"
            case OutlineParser.Key.Element.TextMark.italic:
                return "<i>\(content)</i>"
            case OutlineParser.Key.Element.TextMark.strikeThough:
                return "<span style=\"text-decoration: line-through;\">\(content)</span>"
            case OutlineParser.Key.Element.TextMark.underscore:
                return "<span style=\"text-decoration: underline;\">\(content)</span>"
            case OutlineParser.Key.Element.TextMark.highlight:
                return "<mark>\(content)</mark>"
            default: return string.nsstring.substring(with: self.range)
            }
        } else {
            return string.nsstring.substring(with: self.range)
        }
    }
}
