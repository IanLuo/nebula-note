//
//  OutlineTextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol EditorControllerDelegate: class {
    func currentHeadingDidChange(heading: Document.Heading?)
    func didTapLink(url: String, title: String, point: CGPoint)
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
        self.textContainer = NSTextContainer(size: CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat(Int.max)))
        self.textContainer.widthTracksTextView = true
        self.layoutManager = OutlineLayoutManager()
        
        super.init()
        
        self.textStorage.delegate = self
        self.textStorage.outlineDelegate = self
        self.textStorage.addLayoutManager(self.layoutManager)
        self.layoutManager.delegate = self.textStorage
        self.layoutManager.allowsNonContiguousLayout = true
        self.layoutManager.addTextContainer(self.textContainer)
        self.layoutManager.showsInvisibleCharacters = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// API
extension EditorController {
    public func getParagraphs() -> [Document.Heading] {
        return self.textStorage.savedHeadings // FIXME: may be not the best way, this function should be called on Agenda to load content of heading
    }
    
    public func insertToParagraph(at heading: Document.Heading, content: String) {
        let location = heading.range.location + heading.contentLength
        let content = "\n" + content
        self.textStorage.replaceCharacters(in: NSRange(location: location, length: 0), with: content)
    }
    
    public func replace(text: String, in range: NSRange) {
        self.textStorage.replaceCharacters(in: range, with: text)
    }
    
    public func insert(string: String, at location: Int) {
        self.textStorage.replaceCharacters(in: NSRange(location: location, length: 0), with: string)
    }
    
    public var string: String {
        set { self.textStorage.string = newValue }
        get { return self.textStorage.string }
    }
}

extension EditorController: OutlineTextStorageDelegate {
    public func didSetHeading(newHeading: Document.Heading?, oldHeading: Document.Heading?) {
        if oldHeading?.range.location != newHeading?.range.location {
            self.delegate?.currentHeadingDidChange(heading: newHeading)
        }
    }
}

extension EditorController {
    public func changeFoldingStatus(at location: Int) {
        if let heading = self.textStorage.heading(at: location) {
            let range = heading.paragraphRange
            
            let contentLocation = heading.range.upperBound + 1 // contentLocation + 1 因为有换行符
            
            // 当位于文章末尾之前的章节，长度 + 1，避免折叠后留下一个换行符，导致章节之间有空行
            var postParagraphLength = 1
            if range.upperBound >= textStorage.string.count - 1 {
                postParagraphLength = 0
            }
            let contentRange = NSRange(location: contentLocation,
                                       length: range.upperBound - contentLocation + postParagraphLength)
            
            log.info("fold range: \(contentRange)")
            
            if self.textStorage.attributes(at: contentRange.location, effectiveRange: nil)[OutlineAttribute.Heading.folded] == nil {
                
                self.textStorage.addAttribute(OutlineAttribute.Heading.folded,
                                              value: 1,
                                              range: contentRange)
            } else {
                self.textStorage.removeAttribute(OutlineAttribute.Heading.folded,
                                                 range: contentRange)
            }
        }
    }
    
    public func changeCheckBoxStatus(range: NSRange) {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
        let status = self.string.substring(range)
        let color = status == OutlineParser.Values.Checkbox.unchecked // TODO:
            ? UIColor.green
            : status == OutlineParser.Values.Checkbox.checked ? UIColor.red : UIColor.purple
        
        attachment.image = UIImage.create(with: color, size: attachment.bounds.size)
        self.textStorage.addAttribute(NSAttributedString.Key.attachment, value: attachment, range: NSRange(location: range.location, length: 1))
    }
    
    public func didTapOnCheckbox(textView: UITextView,
                                 characterIndex: Int,
                                 statusRange: NSRange,
                                 point: CGPoint) {
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
        
        log.info("editing in range: \(editedRange), is non continouse: \(textStorage.layoutManagers[0].hasNonContiguousLayout)")

        guard delta != 0 else { return } // 如果是设置 attribute 引起的调用，则忽略

        /// 当前交互的位置
        self.textStorage.currentLocation = editedRange.location

        // 调整需要解析的字符串范围
        self.adjustParseRange(editedRange)

        // 更新 item 索引缓存
        self.textStorage.updateItemIndexAndRange(delta: delta)

        parser.parse(str: textStorage.string,
                     range: self.textStorage.currentParseRange!)

        // 更新当前状态缓存
        self.textStorage.updateCurrentInfo()
    }
    
    internal func adjustParseRange(_ range: NSRange) {
        self.textStorage.currentParseRange = range.expandFoward(string: textStorage.string)
        self.textStorage.currentParseRange = self.textStorage.currentParseRange?.expandBackward(string: textStorage.string)
        
        // 如果范围在某个 item 内，并且小于这个 item 原来的范围，则扩大至这个 item 原来的范围
        if let currrentParseRange = self.textStorage.currentParseRange {
            for item in self.textStorage.itemRanges {
                if item.location <= currrentParseRange.location &&
                    item.upperBound >= currrentParseRange.upperBound {
                    self.textStorage.currentParseRange = item
                    return
                }
            }
        }
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
            return NSRange(location: extendedRange.location, length: max(0, string.count - extendedRange.location - 1))
        }
        
        return NSRange(location: extendedRange.location, length: extendedRange.length + 1)
    }
}
