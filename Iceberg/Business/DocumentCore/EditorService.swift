//
//  EditorServer.swift
//  Iceland
//
//  Created by ian luo on 2018/12/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIDocument

// MARK: - Service -

public enum EditorServiceError: Error {
    case fileIsNotReady
}

public class EditorService {
    private let _editorController: EditorController
    fileprivate var _document: Document?
    private lazy var _trimmer: OutlineTextTrimmer = OutlineTextTrimmer(parser: OutlineParser())
    private let _eventObserver: EventObserver
    private var _queue: DispatchQueue!
    private let _url: URL
    
    // MARK: -
    internal init(url: URL, queue: DispatchQueue, eventObserver: EventObserver, parser: OutlineParser) {
        log.info("creating editor service with url: \(url)")
        self._url = url
        self._eventObserver = eventObserver
        self._editorController = EditorController(parser: parser, attachmentManager: AttachmentManager())
        self._queue = queue
        
        self._editorController.delegate = self
        
        queue.async { [weak self] in
            let document = Document(fileURL: url)
            DispatchQueue.main.async {
                self?._document = document
                self?.isReadyToUse = true
            }
        }
    }
    
    deinit {
        log.info("deiniting editor service with url: \(self._url)")
        self._document?.close(completionHandler: nil)
    }

    // MARK: - life cycle -
    
    public var isReadyToUse: Bool = false {
        didSet {
            if isReadyToUse && isReadyToUse != oldValue {
                onReadyToUse?(self)
            }
        }
    }
    
    public var onReadyToUse: ((EditorService) -> Void)? {
        didSet {
            if isReadyToUse {
                onReadyToUse?(self)
            }
        }
    }
    
    public func open(completion:((String?) -> Void)? = nil) {
        log.info("open file: \(self._url)")
        guard let document = self._document else {
            log.error("can't initialize document with url: \(self._url)")
            completion?(nil)
            return
        }
        
        self._queue.async { [weak self] in
            if document.documentState == .normal {
                // 如果文档已经打开，则直接返回
                log.info("file already open, do nothing")
                DispatchQueue.main.async {
                    completion?(document.string)
                }
            } else {
                // 打开文档，触发解析，然后返回
                document.open { [unowned document] (isOpenSuccessfully: Bool) in
                    guard let strongSelf = self else { return }
                    
                    if isOpenSuccessfully {
                        DispatchQueue.main.async {
                            log.info("open document success(\(strongSelf._url))")
                             strongSelf._editorController.string = document.string // 触发解析
                            completion?(document.string)
                        }
                    } else {
                        DispatchQueue.main.async {
                            log.error("fail to open document with url: \(strongSelf._url)")
                            completion?(nil)
                        }
                    }
                }
            }
        }
    }
        
    private var isClosing: Bool = false
    public func close(completion:((Bool) -> Void)? = nil) {
        guard let document = self._document else {
            completion?(false)
            return
        }
        
        guard self.isClosing == false else { return }
        
        self.isClosing = true
        
        self._queue.async {
            document.close {
                completion?($0)
                self.isClosing = false
            }
        }
    }
    
    // MARK: -
    
    public var container: NSTextContainer {
        return _editorController.textContainer
    }
    
    public func markAsContentUpdated() {
        self._document?.updateContent(_editorController.string)
    }
    
    public func toggleContentCommandComposer(composer: DocumentContentCommandComposer) -> DocumentContentCommand {
        return self._editorController.toggleCommandComposer(composer: composer)
    }
    
    public var allTokens: [Token] {
        return self._editorController.textStorage.allTokens
    }

    public var documentState: UIDocument.State {
        return self._document?.documentState ?? .closed
    }
    
    public var cover: UIImage? {
        set {
            self._document?.updateCover(newValue)
        }
        get { return self._document?.cover }
    }
    
    public func trim(string: String, range: NSRange) -> String {
        return self._trimmer.trim(string: string, range: range)
    }
    
    public var headings: [HeadingToken] {
        return self._editorController.getParagraphs()
    }
    
    public func foldedRange(at location: Int) -> NSRange? {
        return self._editorController.textStorage.foldedRange(at: location)
    }
    
    public var string: String {
        get { return _editorController.string }
        set { self.replace(text: newValue, range: NSRange(location: 0, length: _editorController.string.nsstring.length)) }
    }
    
    public func revertContent() {
        if let string = self._document?.string {
            self._editorController.string = string
        }
    }
    
    public func replace(text: String, range: NSRange) {
        self._editorController.replace(text: text, in: range)
        self.save()
    }
    
    public func isHeadingFolded(at location: Int) -> Bool {
        guard let headingToken = self._editorController.textStorage.heading(contains: location) else { return false }
        
        return self._editorController.textStorage.isHeadingFolded(heading: headingToken)
    }
    
    public var fileURL: URL {
        return _document?.fileURL ?? self._url
    }
    
    public var deepestEntryLevel: Int {
        self._editorController.textStorage.headingTokens.max { heading1, heading2 in
            return heading1.level > heading2.level
        }?.level ?? 0
    }
    
    public func tokens(at location: Int) -> [Token] {
        return self._editorController.textStorage.token(at: location)
    }
    
    public func heading(at location: Int) -> HeadingToken? {
        return self._editorController.textStorage.heading(contains: location)
    }
    
    public var currentCursorTokens: [Token] {
        return self._editorController.textStorage.currentTokens
    }
    
    public func updateCurrentCursor(_ cursorLocation: Int) {
        self._editorController.textStorage.cursorLocation = cursorLocation
    }
    
    public func hiddenRange(location: Int) -> NSRange? {
        var range: NSRange = NSRange(location: 0, length: 0)
        if let value = self._editorController.textStorage.attribute(OutlineAttribute.hidden, at: location, effectiveRange: &range) as? NSNumber, value.intValue != 0 && value.intValue != 2 {
            return range
        } else if let value = self._editorController.textStorage.attribute(OutlineAttribute.tempHidden, at: location, effectiveRange: &range) as? NSNumber, value.intValue != 0 && value.intValue != 2 {
            return range
        }
        
        return nil
    }
    
    public func allContinueHiddenRange(at location: Int) -> NSRange? {
        if var range = hiddenRange(location: location) {
            if range.location > 0 {
                if let leftExt = hiddenRange(location: range.location - 1) {
                    range = range.union(leftExt)
                }
            }
            
            if range.upperBound + 1 < self.string.nsstring.length {
                if let rightExt = hiddenRange(location: range.upperBound + 1) {
                    range = range.union(rightExt)
                }
            }
            
            return range
        } else {
            return nil
        }
    }
    
    public func insert(content: String, headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        _editorController.insertToParagraph(at: heading, content: content)
        
        self._document?.updateContent(_editorController.string)
    }

    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        guard let document = self._document else {
            completion?(EditorServiceError.fileIsNotReady)
            return
        }
        
        let newURL = document.fileURL.deletingLastPathComponent().appendingPathComponent(newTitle).appendingPathExtension(Document.fileExtension)
        document.fileURL.rename(queue: self._queue, url: newURL, completion: completion)
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        guard let document = self._document else { return }
        
        _queue.async {
            document.updateContent(self._editorController.string)
            document.save(to: document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { success in
                
                DispatchQueue.main.async {
                    completion?(success)
                }
            }
        }
    }
    
    // for some case need to continue call function on service, use this one
    public func save(completion: @escaping (EditorService, Bool) -> Void) {
        self.save { result in
            completion(self, result)
        }
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        guard let document = self._document else {
            completion?(EditorServiceError.fileIsNotReady)
            return
        }
        
        document.fileURL.delete(queue: self._queue) {
            completion?($0)
        }
    }
    
    public func find(target: String, found: @escaping ([NSRange]) -> Void) throws {
        guard let document = self._document else {
            return
        }
        
        let matcher = try NSRegularExpression(pattern: "\(target)", options: .caseInsensitive)
        let string = document.string
        var matchedRanges: [NSRange] = []
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            matcher.enumerateMatches(in: string,
                                     options: [],
                                     range: NSRange(location: 0, length: string.nsstring.length)) { (result, flag, stop) in
                                        guard let range = result?.range else { return }
                                        matchedRanges.append(range)
            }
            
            DispatchQueue.main.async {
                found(matchedRanges)
            }
        }
    }
        
    internal func headingList() -> [HeadingToken] {
        return self._editorController.getParagraphs()
    }
}

extension EditorService: EditorControllerDelegate {
    public func currentHeadingDidChange(heading: HeadingToken?) {
        
    }
    
    public func headingChanged(newHeadings: [HeadingToken], oldHeadings: [HeadingToken]) {
        log.info("heading changed from file: \(self.fileURL)")
        self._eventObserver.emit(DocumentHeadingChangeEvent(url: self.fileURL,
                                                           oldHeadings: oldHeadings,
                                                           newHeadings: newHeadings))
    }
}
