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
        
        super.init()
        
        self.textStorage.delegate = self
        self.textStorage.addLayoutManager(layoutManager)
        self.layoutManager.delegate = self
        layoutManager.allowsNonContiguousLayout = true
        layoutManager.addTextContainer(textContainer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PageController: OutlineTextViewDelegate {
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int) {
        for range in self.textStorage.currentParagraphs {
            if range.contains(chracterIndex) {
                let headingRange = self.textStorage.savedHeadings[self.textStorage.headingIndex(at: chracterIndex)].actualRange
                let contentLocation = headingRange.upperBound + 1 // contentLocation + 1 因为有换行符
                let contentRange = NSRange(location: contentLocation, length: range.upperBound - contentLocation)
                
                if self.textStorage.attributes(at: contentRange.location, effectiveRange: nil)[OutlineAttribute.Heading.folded] == nil {
                    self.textStorage.addAttribute(OutlineAttribute.Heading.folded, value: contentRange, range: contentRange)
                } else {
                    self.textStorage.removeAttribute(OutlineAttribute.Heading.folded, range: contentRange)
                }
                
                return
            }
        }
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, statusRange: NSRange) {
        var replacement: String = ""
        switch (textView.text as NSString).substring(with: statusRange) {
        case OutlineParser.Values.Checkbox.unchecked: replacement = OutlineParser.Values.Checkbox.checked
        case OutlineParser.Values.Checkbox.checked: replacement = OutlineParser.Values.Checkbox.unchecked
        case OutlineParser.Values.Checkbox.halfChecked: replacement = OutlineParser.Values.Checkbox.checked
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
                log.info((textView.text as NSString).substring(with: result[OutlineParser.Key.Element.Link.url]!))
                log.info((textView.text as NSString).substring(with: result[OutlineParser.Key.Element.Link.title]!))
                log.info((textView.text as NSString).substring(with: result[OutlineParser.Key.Element.Link.scheme]!))
            }
        }
    }
}

extension PageController: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
        log.info("removing attributes in range: \(editedRange)")
        
        // 清空 attributes, 保留折叠的状态
        for (key, _) in textStorage.attributes(at: editedRange.location, longestEffectiveRange: nil, in: editedRange) {
            if key == OutlineAttribute.Heading.folded { continue }
            textStorage.removeAttribute(key, range: editedRange)
        }
    }
    
    /// 添加文字属性
    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
        log.info("editing in range: \(editedRange)")
        
        /// 当前交互的位置
        self.textStorage.currentLocation = editedRange.location
        
        // 扩大需要解析的字符串范围
        self.textStorage.currentParseRange = editedRange//.expand(string: textStorage.string)
        
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

extension PageController: NSLayoutManagerDelegate {
    public func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>, properties props: UnsafePointer<NSLayoutManager.GlyphProperty>, characterIndexes charIndexes: UnsafePointer<Int>, font aFont: UIFont, forGlyphRange glyphRange: NSRange) -> Int {
        let controlCharProps: UnsafeMutablePointer<NSLayoutManager.GlyphProperty> = UnsafeMutablePointer(mutating: props)
        for i in 0..<glyphRange.length {
            let attributes = self.textStorage.attributes(at: glyphRange.location + i, effectiveRange: nil)
            
            if attributes[OutlineAttribute.Heading.folded] != nil {
                controlCharProps[i] = .null
            } else if attributes[OutlineAttribute.link] != nil
                && attributes[OutlineAttribute.Link.title] == nil {
                controlCharProps[i] = .null
            } else if attributes[OutlineAttribute.Checkbox.status] != nil
                && attributes[OutlineAttribute.Checkbox.box] == nil {
                controlCharProps[i] = .null
            }
        }
        
        log.verbose((self.textStorage.string as NSString).substring(with: glyphRange))
        
        layoutManager.setGlyphs(glyphs,
                                properties: controlCharProps,
                                characterIndexes: charIndexes,
                                font: aFont,
                                forGlyphRange: glyphRange)
        
        return glyphRange.length
    }
    
    public func layoutManager(_ layoutManager: NSLayoutManager, didCompleteLayoutFor textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {

    }
}
