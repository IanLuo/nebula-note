//
//  OutlineTextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol PageControllerDelegate: class {
    
}

public class PageController: NSObject {
    
    let layoutManager: NSLayoutManager
    
    let textContainer: NSTextContainer
    
    let textStorage: OutlineTextStorage
    
    var parser: OutlineParser!
    
    public convenience init(parser: OutlineParser) {
        self.init()
        self.parser = parser
        self.parser.delegate = self.textStorage
    }
    
    public override init() {
        self.textStorage = OutlineTextStorage()
        self.textContainer = NSTextContainer(size: UIScreen.main.bounds.size)
        self.layoutManager = OutlineLayoutManager()
        layoutManager.allowsNonContiguousLayout = true
        layoutManager.addTextContainer(textContainer)
        super.init()
        self.textStorage.delegate = self
        self.textStorage.addLayoutManager(layoutManager)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PageController: OutlineTextViewDelegate {
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int) {
        for range in self.textStorage.currentParagraphs {
            if range.contains(chracterIndex) {
                let heading = self.textStorage.savedDataHeadings[self.textStorage.headingIndex(at: chracterIndex)]
                
                guard let headingRange = heading[OutlineParser.Key.Node.heading] else { return }
                
                let contentLocation = headingRange.upperBound
                let contentRange = NSRange(location: contentLocation, length: range.upperBound - contentLocation)
                
                if self.textStorage.attributes(at: contentLocation, effectiveRange: nil)[OutlineTextStorage.OutlineAttribute.Heading.folded] == nil {
                    self.textStorage.addAttribute(OutlineTextStorage.OutlineAttribute.Heading.folded, value: 1, range: contentRange)
                } else {
                    self.textStorage.removeAttribute(OutlineTextStorage.OutlineAttribute.Heading.folded, range: contentRange)
                }
                
                return
            }
        }
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, statusRange: NSRange) {
        var replacement: String = ""
        switch (textView.text as NSString).substring(with: statusRange) {
        case "- [ ]": replacement = "- [x]"
        case "- [x]": replacement = "- [ ]"
        case "- [-]": replacement = "- [ ]"
        default: break
        }
        
        if replacement.count > 0 {
            self.textStorage.replaceCharacters(in: statusRange, with: replacement)
        }
    }
    
    public func didTapOnLink(textView: UITextView, characterIndex: Int, linkRange: NSRange) {
        if let url = OutlineParser.Matcher.Element.url {
            let result: [[String: NSRange]] = url
                .matches(in: textView.text, options: [], range: linkRange)
                .map { (result: NSTextCheckingResult) -> [String: NSRange] in
                    var comp: [String: NSRange] = [:]
                    comp[OutlineParser.Key.Element.link] = result.range(at: 0)
                    comp[OutlineParser.Key.Element.Link.url] = result.range(at: 1)
                    comp[OutlineParser.Key.Element.Link.scheme] = result.range(at: 2)
                    comp[OutlineParser.Key.Element.Link.title] = result.range(at: 3)
                    return comp.filter { _, value in value.location != Int.max }
            }
            
            if let result = result.first {
                print((textView.text as NSString).substring(with: result[OutlineParser.Key.Element.Link.url]!))
                print((textView.text as NSString).substring(with: result[OutlineParser.Key.Element.Link.title]!))
                print((textView.text as NSString).substring(with: result[OutlineParser.Key.Element.Link.scheme]!))
            }
        }
    }
}

extension PageController: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
        // 清空 attributes, 但是保留折叠的状态
        for (key, _) in textStorage.attributes(at: editedRange.location, longestEffectiveRange: nil, in: editedRange) {
            if key == OutlineTextStorage.OutlineAttribute.Heading.folded { continue }
            textStorage.removeAttribute(key, range: editedRange)
        }
    }
    
    /// 添加文字属性
    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        /// 当前交互的位置
        self.textStorage.currentLocation = editedRange.location
        
        // 扩大需要解析的字符串范围
        self.textStorage.currentParseRange = editedRange.expand(string: textStorage.string)
        
        // 更新 item 索引缓存
        self.textStorage.updateItemIndexAndRange(delta: delta)

        parser.parse(str: textStorage.string,
                     range: self.textStorage.currentParseRange!)
        
        // 更新当前状态缓存
        self.textStorage.updateCurrentInfo()
    }
}

extension NSRange {
    /// 将在字符串中的选择区域扩展到前一个换行符之后，后一个换行符之前
    internal func expand(string: String) -> NSRange {
        var extendedRange = self
        // 向上, 到上一个 '\n' 之后
        while extendedRange.location > 0 &&
            extendedRange.upperBound < string.count - 1 &&
            (string as NSString)
                .substring(with: NSRange(location: extendedRange.location - 1, length: 1)) != "\n" {
                    extendedRange = NSRange(location: extendedRange.location - 1, length: extendedRange.length + 1)
        }
        
//        // 向下，下一个 '\n' 之前
//        while extendedRange.upperBound < string.count - 1 &&
//            (string as NSString)
//                .substring(with: NSRange(location: extendedRange.upperBound, length: 1)) != "\n" {
//                    extendedRange = NSRange(location: extendedRange.location, length: extendedRange.length + 1)
//        }
        
        return extendedRange
    }
}
