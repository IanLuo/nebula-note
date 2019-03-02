//
//  EditorServer.swift
//  Iceland
//
//  Created by ian luo on 2018/12/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIDocument
import Storage

// MARK: - Service - 

public class EditorService {
    private let editorController: EditorController
    fileprivate var document: Document!
    private lazy var trimmer: OutlineTextTrimmer = OutlineTextTrimmer(parser: OutlineParser())
    
    private let eventObserver: EventObserver
    
    private var queue: DispatchQueue!
    
    internal init(url: URL, queue: DispatchQueue, eventObserver: EventObserver) {
        self.eventObserver = eventObserver
        self.editorController = EditorController(parser: OutlineParser(), eventObserver: eventObserver)
        self.document = Document(fileURL: url)
        self.queue = queue
        
        self.editorController.delegate = self
    }

    public var container: NSTextContainer {
        return editorController.textContainer
    }
    
    public func markAsContentUpdated() {
        self.document.updateContent(editorController.string)
    }
    
    public func toggleContentAction(command: DocumentContentCommand) {
        if self.editorController.toggleAction(command: command) {
            self.document.updateContent(editorController.string)
        }
    }
    
    public func start(complete: @escaping (Bool, EditorService) -> Void) {
        queue.async { [unowned self] in
            if self.document.documentState == UIDocument.State.normal {
                complete(true, self)
            } else {
                self.document.open {
                    if $0 {
                        self.editorController.string = self.document.string
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
        return self.document.documentState
    }
    
    public var cover: UIImage? {
        set {
            self.document.updateCover(newValue)
        }
        get { return self.document.cover }
    }
    
    public func trim(string: String, range: NSRange) -> String {
        return self.trimmer.trim(string: string, range: range)
    }
    
    public var headings: [HeadingToken] {
        return self.editorController.getParagraphs()
    }
    
    public var string: String {
        get { return editorController.string }
        set { self.replace(text: newValue, range: NSRange(location: 0, length: editorController.string.count)) }
    }
    
    public func replace(text: String, range: NSRange) {
        self.editorController.replace(text: text, in: range)
        self.save()
    }
    
    public var fileURL: URL {
        return document.fileURL
    }
    
    public func open(completion:((String?) -> Void)? = nil) {
        self.queue.async { [weak self] in
            // 如果文档已经打开，则直接返回
            if self?.document.documentState == .normal {
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    completion?(strongSelf.document.string)
                }
            } else {
                // 打开文档，触发解析，然后返回
                self?.document.open { (isOpenSuccessfully: Bool) in
                    guard let strongSelf = self else { return }
                    
                    if isOpenSuccessfully {
                        DispatchQueue.main.async {
                            strongSelf.editorController.string = strongSelf.document.string // 触发解析
                            completion?(strongSelf.document.string)
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
        
        editorController.insertToParagraph(at: heading, content: content)
        
        self.document.updateContent(editorController.string)
    }
    
    public func close(completion:((Bool) -> Void)? = nil) {
        document.close {
            completion?($0)
        }
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        let newURL = self.document.fileURL.deletingLastPathComponent().appendingPathComponent(newTitle).appendingPathExtension(Document.fileExtension)
        document.fileURL.rename(url: newURL, completion: completion)
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        queue.async {
            self.document.string = self.editorController.string
            self.document.save(to: self.document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { success in
                
                DispatchQueue.main.async {
                    completion?(success)
                }
            }
        }
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        self.document.fileURL.delete {
            completion?($0)
        }
    }
    
    public func find(target: String, found: @escaping ([NSRange]) -> Void) throws {
        let matcher = try NSRegularExpression(pattern: "\(target)", options: .caseInsensitive)
        let string = self.document.string
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
        for heading in self.editorController.getParagraphs() {
            if heading.paragraphRange.contains(location) {
                return heading
            }
        }
        return nil
    }
    
    internal func headingList() -> [HeadingToken] {
        return self.editorController.getParagraphs()
    }
}

extension EditorService: EditorControllerDelegate {
    public func currentHeadingDidChange(heading: HeadingToken?) {
        
    }
    
    public func headingChanged(newHeadings: [HeadingToken], oldHeadings: [HeadingToken]) {
        self.eventObserver.emit(DocumentHeadingChangeEvent(url: self.fileURL,
                                                           oldHeadings: oldHeadings,
                                                           newHeadings: newHeadings))
    }
    
    public func didTapLink(url: String, title: String, point: CGPoint) {
        
    }
}
