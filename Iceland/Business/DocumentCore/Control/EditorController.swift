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
    
    public weak var delegate: EditorControllerDelegate?
    
    public convenience init(parser: OutlineParser) {
        self.init()
        self.textStorage.parser = parser
        parser.delegate = self.textStorage
        self.textStorage.attributeChangeDelegate = self.textStorage
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
            log.info("fold range: \(heading.contentRange)")
            
            if self.textStorage.attributes(at: heading.contentRange.location, effectiveRange: nil)[OutlineAttribute.Heading.folded] == nil {
                // 标记内容为隐藏
                self.textStorage.addAttribute(OutlineAttribute.Heading.folded,
                                              value: 1,
                                              range: heading.contentRange)
            } else {
                // 移除内容隐藏标记
                self.textStorage.removeAttribute(OutlineAttribute.Heading.folded,
                                                 range: heading.contentRange)
            }
        }
    }
    
    public func changeCheckBoxStatus(range: NSRange) {
        let attachment = NSTextAttachment()
        attachment.bounds = CGRect(origin: .zero, size: CGSize(width: 24, height: 24))
        let status = self.string.substring(range)
        let color = status == OutlineParser.Values.Checkbox.unchecked // FIXME: check box 渲染相关
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

// MARK: - Text Storage Delegate -
// 每次编辑触发时，首先删除所在范围的属性(folding 除外),然后视情况看是否需要进行解析
extension EditorController: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage,
                            willProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
    }
    
    /// 添加文字属性
    public func textStorage(_ textStorage: NSTextStorage,
                            didProcessEditing editedMask: NSTextStorage.EditActions,
                            range editedRange: NSRange,
                            changeInLength delta: Int) {
    }
}
