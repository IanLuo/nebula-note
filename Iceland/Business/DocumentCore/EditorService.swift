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

public class EditorService {
    private let _editorController: EditorController
    fileprivate var _document: Document!
    private lazy var _trimmer: OutlineTextTrimmer = OutlineTextTrimmer(parser: OutlineParser())
    private let _eventObserver: EventObserver
    private var _queue: DispatchQueue!
    
    internal init(url: URL, queue: DispatchQueue, eventObserver: EventObserver) {
        self._eventObserver = eventObserver
        self._editorController = EditorController(parser: OutlineParser(), eventObserver: eventObserver, attachmentManager: AttachmentManager())
        self._document = Document(fileURL: url)
        self._queue = queue
        
        self._editorController.delegate = self
        
        self._document.didUpdateDocumentContentAction = { [weak self] in
            
        }
    }

    public var container: NSTextContainer {
        return _editorController.textContainer
    }
    
    public func markAsContentUpdated() {
        self._document.updateContent(_editorController.string)
    }
    
    public func toggleContentCommandComposer(composer: DocumentContentCommandComposer) -> DocumentContentCommand {
        return self._editorController.toggleCommandComposer(composer: composer)
    }
    

    public func start(complete: @escaping (Bool, EditorService) -> Void) {
        _queue.async { [unowned self] in
            if self._document.documentState == UIDocument.State.normal {
                complete(true, self)
            } else {
                self._document.open {
                    if $0 {
                        self._editorController.string = self._document.string
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
        return self._document.documentState
    }
    
    public var cover: UIImage? {
        set {
            self._document.updateCover(newValue)
        }
        get { return self._document.cover }
    }
    
    public func trim(string: String, range: NSRange) -> String {
        return self._trimmer.trim(string: string, range: range)
    }
    
    public var headings: [HeadingToken] {
        return self._editorController.getParagraphs()
    }
    
    public var string: String {
        get { return _editorController.string }
        set { self.replace(text: newValue, range: NSRange(location: 0, length: _editorController.string.count)) }
    }
    
    public func replace(text: String, range: NSRange) {
        self._editorController.replace(text: text, in: range)
        self.save()
    }
    
    public var fileURL: URL {
        return _document.fileURL
    }
    
    public func tokens(at location: Int) -> [Token] {
        return self._editorController.textStorage.token(at: location)
    }
    
    public var currentCursorTokens: [Token] {
        return self._editorController.textStorage.currentTokens
    }
    
    public func updateCurrentCursor(_ cursorLocation: Int) {
        self._editorController.textStorage.cursorLocation = cursorLocation
    }
    
    public func open(completion:((String?) -> Void)? = nil) {
        self._queue.async { [weak self] in
            // 如果文档已经打开，则直接返回
            if self?._document.documentState == .normal {
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    completion?(strongSelf._document.string)
                }
            } else {
                // 打开文档，触发解析，然后返回
                self?._document.open { (isOpenSuccessfully: Bool) in
                    guard let strongSelf = self else { return }
                    
                    if isOpenSuccessfully {
                        DispatchQueue.main.async {
                            strongSelf._editorController.string = strongSelf._document.string // 触发解析
                            completion?(strongSelf._document.string)
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
        
        self._document.updateContent(_editorController.string)
    }
    
    public func close(completion:((Bool) -> Void)? = nil) {
        _document.close {
            completion?($0)
        }
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        let newURL = self._document.fileURL.deletingLastPathComponent().appendingPathComponent(newTitle).appendingPathExtension(Document.fileExtension)
        _document.fileURL.rename(url: newURL, completion: completion)
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        _queue.async {
            self._document.updateContent(self._editorController.string)
            self._document.save(to: self._document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { success in
                
                DispatchQueue.main.async {
                    completion?(success)
                }
            }
        }
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        self._document.fileURL.delete {
            completion?($0)
        }
    }
    
    public func find(target: String, found: @escaping ([NSRange]) -> Void) throws {
        let matcher = try NSRegularExpression(pattern: "\(target)", options: .caseInsensitive)
        let string = self._document.string
        var matchedRanges: [NSRange] = []
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            matcher.enumerateMatches(in: string,
                                     options: [],
                                     range: NSRange(location: 0, length: string.count)) { (result, flag, stop) in
                                        guard let range = result?.range else { return }
                                        matchedRanges.append(range)
            }
            
            DispatchQueue.main.async {
                found(matchedRanges)
            }
        }
    }
    
    // 返回 location 所在的 heading
    internal func heading(at location: Int) -> HeadingToken? {
        for heading in self._editorController.getParagraphs() {
            if heading.paragraphRange.contains(location) {
                return heading
            }
        }
        return nil
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
