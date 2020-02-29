//
//  TxtExporter.swift
//  Business
//
//  Created by ian luo on 2019/6/27.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct TxtExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "txt"
    
    private let _editorContext: EditorContext
    
    public init(editorContext: EditorContext, url: URL) {
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
                    var tokenString = token.render(string: string ?? "")
                    
                    if let _ = token as? HeadingToken, SettingsAccessor.Item.exportShowIndex.get(Bool.self) ?? true {
                        if let indexs = headingIndexs.last {
                            let index = indexs.map { "\($0)" }.joined(separator: ".")
                            tokenString = index + " " + tokenString
                            headingIndexs.remove(at: headingIndexs.count - 1)
                        }
                    }
                    
                    result = result.nsstring.replacingCharacters(in: token.range, with: tokenString)
                }
                
                completion(.string(result))
            }
        }

    }
}

extension Token {
    fileprivate func render(string: String) -> String {
        if self is HeadingToken {
            return string.nsstring.substring(with: (self as! HeadingToken).headingTextRange)
        } else if let attachmentToken = self as? AttachmentToken {
            guard let typeRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.type) else { return ""}
            guard let valueRange = attachmentToken.range(for: OutlineParser.Key.Element.Attachment.value) else { return ""}
            
            let type = string.nsstring.substring(with: typeRange)
            let value = string.nsstring.substring(with: valueRange)
            
            if type == Attachment.Kind.image.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                return "image:\(url.lastPathComponent)"
            } else if type == Attachment.Kind.sketch.rawValue, let url = AttachmentManager.attachmentFileURL(key: value) {
                return "sketch:\(url.lastPathComponent)"
            } else {
                return "\(type):\(value)"
            }
        } else {
            return string.nsstring.substring(with: self.range)
        }
    }
}
