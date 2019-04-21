//
//  OutlineTextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

/// 文档内容的更新，用户与文档的交互，通过这个代理，由上层(EditorService)来处理，因为文档内部对文档的外部属性，比如 url 等并不知道
public protocol EditorControllerDelegate: class {
    func currentHeadingDidChange(heading: HeadingToken?)
    func headingChanged(newHeadings: [HeadingToken], oldHeadings:[HeadingToken])
    func didTapLink(url: String, title: String, point: CGPoint)
}

public class EditorController: NSObject {
    
    private let _layoutManager: NSLayoutManager
    
    private let _eventObserver: EventObserver

    internal let textContainer: NSTextContainer
    
    internal let textStorage: OutlineTextStorage
    
    public weak var delegate: EditorControllerDelegate?
    
    public init(parser: OutlineParser, eventObserver: EventObserver, attachmentManager: AttachmentManager) {
        self.textStorage = OutlineTextStorage(eventObserver: eventObserver, attachmentManager: attachmentManager)
        self.textContainer = NSTextContainer(size: CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat(Int.max)))
        self.textContainer.widthTracksTextView = true
        self._layoutManager = OutlineLayoutManager()
        self._eventObserver = eventObserver
        
        super.init()
        
        self.textStorage.parser = parser
        parser.delegate = self.textStorage
        self.textStorage.attributeChangeDelegate = self.textStorage
        
        self.textStorage.delegate = self.textStorage
        self.textStorage.outlineDelegate = self
        self.textStorage.addLayoutManager(self._layoutManager)
        self._layoutManager.delegate = self.textStorage
        self._layoutManager.allowsNonContiguousLayout = true
        self._layoutManager.addTextContainer(self.textContainer)
        self._layoutManager.showsInvisibleCharacters = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// API
extension EditorController {
    public func getParagraphs() -> [HeadingToken] {
        return self.textStorage.headingTokens
    }
    
    public func insertToParagraph(at heading: HeadingToken, content: String) {
        let location = heading.paragraphRange.upperBound - 1
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
    public func didUpdateCurrentTokens(_ tokens: [Token]) {
        
    }
    
    public func didUpdateHeadings(newHeadings: [HeadingToken], oldHeadings: [HeadingToken]) {
        self.delegate?.headingChanged(newHeadings: newHeadings, oldHeadings: oldHeadings)
    }
    
    public func didSetCurrentHeading(newHeading: HeadingToken?, oldHeading: HeadingToken?) {
        if oldHeading?.range.location != newHeading?.range.location {
            self.delegate?.currentHeadingDidChange(heading: newHeading)
        }
    }
}

extension EditorController {
    public func toggleCommandComposer(composer: DocumentContentCommandComposer) -> DocumentContentCommand {
        return composer.compose(textStorage: self.textStorage)
    }
}
