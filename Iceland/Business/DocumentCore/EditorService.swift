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
    
    internal init(url: URL, queue: DispatchQueue, eventObserver: EventObserver, parser: OutlineParser) {
        self._url = url
        self._eventObserver = eventObserver
        self._editorController = EditorController(parser: parser, eventObserver: eventObserver, attachmentManager: AttachmentManager())
        self._queue = queue
        
        self._editorController.delegate = self
        
        queue.async { [weak self] in
            let document = Document(fileURL: url)
            DispatchQueue.main.async {
                self?._document = document
                self?.isReadyToUse = true
            }
        }
        
//        self._document?.didUpdateDocumentContentAction = { [weak self] in
//            
//        }
    }

    public var container: NSTextContainer {
        return _editorController.textContainer
    }
    
    public func markAsContentUpdated() {
        self._document?.updateContent(_editorController.string)
    }
    
    public func toggleContentCommandComposer(composer: DocumentContentCommandComposer) -> DocumentContentCommand {
        return self._editorController.toggleCommandComposer(composer: composer)
    }
    

    public func start(complete: @escaping (Bool, EditorService) -> Void) {
        guard let document = self._document else {
            complete(false, self)
            return
        }
        
        _queue.async { [unowned self] in
            if self._document?.documentState == UIDocument.State.normal {
                complete(true, self)
            } else {
                self._document?.open {
                    if $0 {
                        self._editorController.string = document.string
                        DispatchQueue.main.async {
                            complete(true, self)
                        }
                    } else {
                        DispatchQueue.main.async {
                            complete(false, self)
                        }
                    }
                    
                }
            }
        }
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
    
    public func open(completion:((String?) -> Void)? = nil) {
        guard let document = self._document else {
            completion?(nil)
            return
        }
        
        self._queue.async { [weak self] in
            // 如果文档已经打开，则直接返回
            if document.documentState == .normal {
                DispatchQueue.main.async {
                    completion?(document.string)
                }
            } else {
                // 打开文档，触发解析，然后返回
                document.open { [unowned document] (isOpenSuccessfully: Bool) in
                    guard let strongSelf = self else { return }
                    
                    if isOpenSuccessfully {
                        DispatchQueue.main.async {
                             strongSelf._editorController.string = document.string // 触发解析
                            completion?(document.string)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion?(nil)
                        }
                    }
                }
            }
        }
    }
    
    public func insert(content: String, headingLocation: Int) {
        guard let heading = self.heading(at: headingLocation) else { return }
        
        _editorController.insertToParagraph(at: heading, content: content)
        
        self._document?.updateContent(_editorController.string)
    }
    
    public func close(completion:((Bool) -> Void)? = nil) {
        guard let document = self._document else {
            completion?(false)
            return
        }
        
        self._queue.async {
            document.close {
                completion?($0)
            }
        }
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
        self._eventObserver.emit(DocumentHeadingChangeEvent(url: self.fileURL,
                                                           oldHeadings: oldHeadings,
                                                           newHeadings: newHeadings))
    }
    
    public func didTapLink(url: String, title: String, point: CGPoint) {
        
    }
}
