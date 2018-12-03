//
//  OutlineTextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol EditorControllerDelegate: class {

}

public class EditorController: NSObject {
    
    private let layoutManager: NSLayoutManager

    internal let textContainer: NSTextContainer
    
    internal let textStorage: OutlineTextStorage
    
    internal var parser: OutlineParser!
    
    public weak var delegate: EditorControllerDelegate?
    
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
        
        self.layoutManager.showsInvisibleCharacters = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorController {
    public func getParagraphs() -> [OutlineTextStorage.Heading] {
        return self.textStorage.savedHeadings // FIXME: may be not the best way, this function should be called on Agenda to load content of heading
    }
    
    public func insertToParagraph(at heading: OutlineTextStorage.Heading, content: String) {
        // TODO: insert content at the bottom of the paragraph
    }
    
    public var string: String {
        set { self.textStorage.string = newValue }
        get { return self.textStorage.string }
    }
}

extension EditorController: OutlineTextViewDelegate {
    public func didTapOnLevel(textView: UITextView,
                              chracterIndex: Int) {
        for heading in self.textStorage.savedHeadings {
            let range = heading.paragraphRange
            
            if range.contains(chracterIndex) {
                let headingRange = self.textStorage.savedHeadings[self.textStorage.headingIndex(at: chracterIndex)].range
                let contentLocation = headingRange.upperBound + 1 // contentLocation + 1 因为有换行符
                
                // 当位于文章末尾之前的章节，长度 + 1，避免折叠后留下一个换行符，导致章节之间有空行
                var postParagraphLength = 1
                if range.upperBound >= textView.text.count - 1 {
                    postParagraphLength = 0
                }
                let contentRange = NSRange(location: contentLocation,
                                           length: range.upperBound - contentLocation + postParagraphLength)
                
                if self.textStorage.attributes(at: contentRange.location, effectiveRange: nil)[OutlineAttribute.Heading.folded] == nil {
                    
                    // 如果当前 cursor 在被折叠的部分，会造成 indent 出错, 因此将 cursor 移到 heading 的末尾
                    if contentRange.contains(textView.selectedRange.location) {
                        textView.selectedRange = NSRange(location: contentRange.location - 1,
                                                         length: 0)
                    }
                    
                    self.textStorage.addAttribute(OutlineAttribute.Heading.folded,
                                                  value: contentRange,
                                                  range: contentRange)
                } else {
                    self.textStorage.removeAttribute(OutlineAttribute.Heading.folded,
                                                     range: contentRange)
                }
                
                return
            }
        }
    }
    
    public func didTapOnCheckbox(textView: UITextView,
                                 characterIndex: Int,
                                 statusRange: NSRange) {
        var replacement: String = ""
        let offsetedRange = statusRange.offset(statusRange.location - characterIndex)
        
        switch (textView.text as NSString).substring(with: offsetedRange) {
        case OutlineParser.Values.Checkbox.unchecked: replacement = OutlineParser.Values.Checkbox.checked
        case OutlineParser.Values.Checkbox.checked: replacement = OutlineParser.Values.Checkbox.unchecked
        case OutlineParser.Values.Checkbox.halfChecked: replacement = OutlineParser.Values.Checkbox.checked
        default: break
        }
        
        if replacement.count > 0 {
            self.textStorage.replaceCharacters(in: offsetedRange, with: replacement)
        }
    }
    
    public func didTapOnLink(textView: UITextView,
                             characterIndex: Int,
                             linkRange: NSRange) {
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

extension EditorController: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage,
                            willProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
        
        log.info("removing attributes in range: \(editedRange)")
        
        // 清空 attributes, 保留折叠的状态
        guard editedRange.upperBound < textStorage.string.count else { return }
        
        for (key, _) in textStorage.attributes(at: editedRange.location, longestEffectiveRange: nil, in: editedRange) {
            if key == OutlineAttribute.Heading.folded { continue }
            textStorage.removeAttribute(key, range: editedRange)
        }
    }
    
    /// 添加文字属性
    public func textStorage(_ textStorage: NSTextStorage,
                            didProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
        
        log.info("editing in range: \(editedRange)")
        
        /// 当前交互的位置
        self.textStorage.currentLocation = editedRange.location
        
        // 扩大需要解析的字符串范围
        self.textStorage.currentParseRange = editedRange.expandFoward(string: textStorage.string)
        self.textStorage.currentParseRange = self.textStorage.currentParseRange?.expandBackward(string: textStorage.string)
        
        // 更新 item 索引缓存
        self.textStorage.updateItemIndexAndRange(delta: delta)
        
        parser.parse(str: textStorage.string,
                     range: self.textStorage.currentParseRange!)

        // 更新当前状态缓存
        self.textStorage.updateCurrentInfo()
    }
}

extension EditorController: NSLayoutManagerDelegate {
    public func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>, properties props: UnsafePointer<NSLayoutManager.GlyphProperty>, characterIndexes charIndexes: UnsafePointer<Int>, font aFont: UIFont, forGlyphRange glyphRange: NSRange) -> Int {
        let controlCharProps: UnsafeMutablePointer<NSLayoutManager.GlyphProperty> = UnsafeMutablePointer(mutating: props)
        for i in 0..<glyphRange.length {
            let attributes = self.textStorage.attributes(at: glyphRange.location + i, effectiveRange: nil)

            // 隐藏这些字符
            if attributes[OutlineAttribute.Heading.folded] != nil { // 标记为折叠
                controlCharProps[i] = .null
            } else if attributes[OutlineAttribute.link] != nil // 标记为 link 中非 title 的部分
                && attributes[OutlineAttribute.Link.title] == nil {
                controlCharProps[i] = .null
            } else if attributes[OutlineAttribute.Checkbox.status] != nil // 标记为 checkbox 中非 box 的部分
                && attributes[OutlineAttribute.Checkbox.box] == nil {
                controlCharProps[i] = .null
            }
        }
        
//        log.verbose((self.textStorage.string as NSString).substring(with: glyphRange))
        
        layoutManager.setGlyphs(glyphs,
                                properties: controlCharProps,
                                characterIndexes: charIndexes,
                                font: aFont,
                                forGlyphRange: glyphRange)
        
        return glyphRange.length
    }
}

extension NSRange {
    /// 将在字符串中的选择区域扩展到前一个换行符之后，后一个换行符之前
    internal func expandFoward(string: String) -> NSRange {
        var extendedRange = self
        // 向上, 到上一个 '\n' 之后
        while extendedRange.location > 0 &&
            extendedRange.upperBound < string.count - 1 &&
            (string as NSString)
                .substring(with: NSRange(location: extendedRange.location - 1, length: 1)) != "\n" {
                    extendedRange = NSRange(location: extendedRange.location - 1, length: extendedRange.length + 1)
        }
        return extendedRange
    }
    
    internal func expandBackward(string: String) -> NSRange {
        // 向下，下一个 '\n' 之后
        var extendedRange = self
        while extendedRange.upperBound < string.count - 1 &&
            (string as NSString)
                .substring(with: NSRange(location: extendedRange.upperBound, length: 1)) != "\n" {
                    extendedRange = NSRange(location: extendedRange.location, length: extendedRange.length + 1)
        }
        
        if extendedRange.upperBound >= string.count - 1 {
            return NSRange(location: extendedRange.location, length: string.count - extendedRange.location - 1)
        }
        
        return NSRange(location: extendedRange.location, length: extendedRange.length + 1)
    }
}
