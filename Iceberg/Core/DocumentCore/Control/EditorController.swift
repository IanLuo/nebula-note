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
    func getLogs() -> DocumentLog?
    func markFoldingState(heading: HeadingToken, isFolded: Bool)
}

public class EditorController: NSObject {
    
    private let layoutManager: NSLayoutManager
    
    internal let textContainer: NSTextContainer
    
    internal let textStorage: OutlineTextStorage
    
    public weak var delegate: EditorControllerDelegate?
    
    public init(parser: OutlineParser, attachmentManager: AttachmentManager) {
        self.textStorage = OutlineTextStorage(attachmentManager: attachmentManager)
        self.textContainer = NSTextContainer(size: CGSize(width: UIScreen.main.bounds.size.width, height: CGFloat(Int.max)))
        self.textContainer.widthTracksTextView = true
        self.layoutManager = OutlineLayoutManager()
        
        super.init()
        
        self.textStorage.parser = parser
        parser.delegate = self.textStorage
        self.textStorage.attributeChangeDelegate = self.textStorage
        
        self.textStorage.delegate = self.textStorage
        self.textStorage.outlineDelegate = self
//        self.textStorage.addLayoutManager(self.layoutManager)
//        self.layoutManager.delegate = self.textStorage
//        self.layoutManager.allowsNonContiguousLayout = true
//        self.layoutManager.addTextContainer(self.textContainer)
//        self.layoutManager.showsInvisibleCharacters = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func creatTextContainer() -> NSTextContainer {
        let layoutManager = OutlineLayoutManager()
        let container = NSTextContainer()
        layoutManager.addTextContainer(container)
        layoutManager.delegate = self.textStorage
        layoutManager.allowsNonContiguousLayout = true
        layoutManager.showsInvisibleCharacters = false
        self.textStorage.addLayoutManager(layoutManager)
        return container
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
    
    public func logs() -> DocumentLog? {
        return self.delegate?.getLogs()
    }
    
    public func markFoldingState(heading: HeadingToken, isFolded: Bool) {
        self.delegate?.markFoldingState(heading: heading, isFolded: isFolded)
    }
}

extension EditorController {
    public func toggleCommandComposer(composer: DocumentContentCommandComposer) -> DocumentContentCommand {
        return composer.compose(textStorage: self.textStorage)
    }
}
