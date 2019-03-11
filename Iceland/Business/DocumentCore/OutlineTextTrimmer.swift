//
//  OutlineTextTrimmer.swift
//  Business
//
//  Created by ian luo on 2019/3/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

/// 用来将 Outline 中的标记去掉，只留下纯文本内容
public class OutlineTextTrimmer: OutlineParserDelegate {
    private let _parser: OutlineParser
    
    public func didFoundTextMark(text: String, markRanges: [[String : NSRange]]) {
        markRanges.forEach {
            _result = _result.replacingOccurrences(of: text.substring($0[OutlineParser.Key.Element.TextMark.mark]!),
                                                 with: text.substring($0[OutlineParser.Key.Element.TextMark.content]!))
        }
    }
    
    public func didFoundLink(text: String, urlRanges: [[String : NSRange]]) {
        urlRanges.forEach {
            _result = _result.replacingOccurrences(of: text.substring($0[OutlineParser.Key.Element.link]!),
                                                 with: text.substring($0[OutlineParser.Key.Element.Link.title]!))
        }
    }
    
    public init(parser: OutlineParser) {
        self._parser = parser
        parser.delegate = self
    }
    
    public func didCompleteParsing(text: String) {
        
    }
    
    private var _result: String = ""
    
    public func trim(string: String, range: NSRange? = nil) -> String {
        let range = range ?? NSRange(location: 0, length: string.count)
        self._result = string.substring(range)
        self._parser.parse(str: string, range: range)
        return _result
    }
}
