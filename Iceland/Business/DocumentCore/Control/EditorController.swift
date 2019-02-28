//
//  OutlineTextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol EditorControllerDelegate: class {
    func currentHeadingDidChange(heading: Heading?)
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
        
        self.textStorage.delegate = self.textStorage
        self.textStorage.outlineDelegate = self
        self.textStorage.addLayoutManager(self.layoutManager)
        self.layoutManager.delegate = self.textStorage
        self.layoutManager.allowsNonContiguousLayout = true
        self.layoutManager.addTextContainer(self.textContainer)
        self.layoutManager.showsInvisibleCharacters = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// API
extension EditorController {
    public func getParagraphs() -> [Heading] {
        return self.textStorage.savedHeadings // FIXME: may be not the best way, this function should be called on Agenda to load content of heading
    }
    
    public func insertToParagraph(at heading: Heading, content: String) {
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
    public func didSetCurrentHeading(newHeading: Heading?, oldHeading: Heading?) {
        if oldHeading?.range.location != newHeading?.range.location {
            self.delegate?.currentHeadingDidChange(heading: newHeading)
        }
    }
}

extension EditorController {
    public func changeFoldingStatus(at location: Int) {
        if let heading = self.textStorage.heading(at: location) {
            log.info("fold range: \(heading.contentRange)")
            
            guard heading.contentRange.length > 0 else { return }
            
            if self.textStorage.attribute(OutlineAttribute.hidden, at: heading.contentRange.location, effectiveRange: nil) == nil {
                // 标记内容为隐藏
                self.textStorage.addAttributes([OutlineAttribute.hidden: 2,
                                                OutlineAttribute.showAttachment: OutlineAttribute.Heading.folded],
                                              range: heading.contentRange)
            } else {
                // 移除内容隐藏标记
                self.textStorage.removeAttribute(OutlineAttribute.hidden,
                                                 range: heading.contentRange)
                self.textStorage.removeAttribute(OutlineAttribute.showAttachment,
                                                 range: heading.contentRange)
            }
        }
    }
    
    public func changeCheckBoxStatus(range: NSRange) {
        let status = self.string.substring(range)
        
        var nextStatus: String = status
        switch status {
        case OutlineParser.Values.Checkbox.checked: fallthrough
        case OutlineParser.Values.Checkbox.halfChecked:
            nextStatus = OutlineParser.Values.Checkbox.unchecked
        default:
            nextStatus = OutlineParser.Values.Checkbox.checked
        }
        
        self.textStorage.replaceCharacters(in: range, with: nextStatus)
    }
}
