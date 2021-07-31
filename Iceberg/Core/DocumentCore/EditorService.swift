//
//  EditorServer.swift
//  Iceland
//
//  Created by ian luo on 2018/12/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIDocument
import RxSwift

// MARK: - Service -

public enum EditorServiceError: Error {
    case fileIsNotReady
}

public class DocumentLog: Codable {
    public class Heading: Codable {
        internal init(isFold: Bool, id: String) {
            self.isFold = isFold
            self.id = id
        }
        
        public var isFold: Bool
        public let id: String
    }
    
    public var headings: [String: Heading]
    public var id: String?
    public var tags: String?
    
    enum keys: CodingKey {
        case headings
        case id
        case tags
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: keys.self)
        self.headings = try container.decodeIfPresent([String: Heading].self, forKey: .headings) ?? [:]
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.tags = try container.decodeIfPresent(String.self, forKey: .tags)
    }
}

public class EditorService {
    private let editorController: EditorController
    fileprivate var document: Document
    private lazy var trimmer: OutlineTextTrimmer = OutlineTextTrimmer(parser: OutlineParser())
    private let eventObserver: EventObserver
    private var queue: DispatchQueue!
    private let url: URL
    private let settingsAccessor: SettingsAccessor
    public let onTitleChanged: PublishSubject<String> = PublishSubject()
    
    // means the document it opens, is not stored on users document folder
    public let isTemp: Bool
    
    // MARK: -
    internal init(url: URL, queue: DispatchQueue, eventObserver: EventObserver, parser: OutlineParser, isTemp: Bool = false, settingsAccessor: SettingsAccessor) {
        log.info("creating editor service with url: \(url)")
        self.url = url
        self.isTemp = isTemp
        self.eventObserver = eventObserver
        self.editorController = EditorController(parser: parser, attachmentManager: AttachmentManager())
        self.queue = queue
        self.document = Document(fileURL: url)
        self.settingsAccessor = settingsAccessor
        self.editorController.delegate = self
        
        queue.async { [weak self] in
            self?.isReadyToUse = true
        }
    }
    
    deinit {
        log.info("deiniting editor service with url: \(self.url)")
        self.document.close(completionHandler: nil)
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
    
    public var isOpen: Bool {
        return self.document.documentState == .normal && self.logs != nil
    }
    
    private let lock = NSLock()
    
    public func open(completion:((String?) -> Void)? = nil) {
        log.info("open file: \(self.url)")
        
        lock.lock()
        
        self.queue.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if strongSelf.isOpen {
                // 如果文档已经打开，则直接返回
                log.info("file already open, do nothing")
                self?.loadLogs()
                DispatchQueue.runOnMainQueueSafely {
                    completion?(strongSelf.document.string)
                }
                
                self?.lock.unlock()
            } else {
                // 打开文档，触发解析，然后返回
                strongSelf.document.open { (isOpenSuccessfully: Bool) in
                    
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.unlock()
                                        
                    if isOpenSuccessfully {
                        
                        log.info("open document success(\(strongSelf.url))")
                        
                        strongSelf.loadLogs()
                        
                        DispatchQueue.runOnMainQueueSafely {
                            strongSelf.editorController.string = strongSelf.document.string // 触发解析
                            completion?(strongSelf.document.string)
                        }
                        
                        // fill in logs for this document
                    } else {
                        DispatchQueue.runOnMainQueueSafely {
                            log.error("fail to open document with url: \(strongSelf.url)")
                            completion?(nil)
                        }
                    }
                }
            }
        }
    }
        
    private var isClosing: Bool = false
    func close(completion:((Bool) -> Void)? = nil) {
        guard self.isOpen else { return }
        guard self.isClosing == false else { return }
        
        self.isClosing = true
        
        self.queue.async { [weak self] in
            self?.document.close {
                completion?($0)
                
                self?.isClosing = false
            }
        }
    }
    
    // MARK: -
    
    public var container: NSTextContainer {
        return editorController.creatTextContainer()
    }
    
    public var isReadingMode: Bool {
        get { return editorController.textStorage.isReadingMode }
        set { editorController.textStorage.isReadingMode = newValue }
    }
    
    public func markAsContentUpdated() {
        self.document.updateContent(editorController.string)
    }
    
    public func toggleContentCommandComposer(composer: DocumentContentCommandComposer) -> DocumentContentCommand {
        return self.editorController.toggleCommandComposer(composer: composer)
    }
    
    public var allTokens: [Token] {
        return self.editorController.textStorage.allTokens
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
    
    public var logs: DocumentLog?
    
    public var documentInfo: DocumentInfo {
        return DocumentInfo(name: self.fileURL.packageName, cover: self.cover, url: self.fileURL, coverURL: self.fileURL.coverURL, id: self.id)
    }
    
    private func loadLogs() {
        let data = self.document.logs.data(using: .utf8)!
        let decoder = JSONDecoder()
        do {
            self.logs = try decoder.decode(DocumentLog.self, from: data)
            
            // if documentId is empty, set it
            if self.logs?.id == nil {
                self.logs?.id = "\(Document.documentIdPrefix){\(UUID().uuidString)}"
                self.updateLogs(self.logs!)
            }
        } catch {
            print("Failed to load logs \(error)")
        }
    }
    
    public var id: String {
        guard self.logs != nil else {
            fatalError("the document is not open")
        }
        
        return self.logs!.id! // the id must assign if the log is assigned
    }
    
    public func syncFoldingStatus() {
        if let headingLogs = self.logs?.headings {
            for heading in self.editorController.textStorage.headingTokens {
                let foldingStatus = headingLogs[heading.identifier]?.isFold ?? false
                if foldingStatus {
                    _ = self.toggleContentCommandComposer(composer: FoldToLocationCommandCompose(location: heading.range.location)).perform()
                } else {
                    _ = self.toggleContentCommandComposer(composer: UnfoldToLocationCommandCompose(location: heading.range.location)).perform()
                }

            }
        }
        
        self.editorController.textStorage.flushTokens()
    }
    
    public func updateLogs(_ logs: DocumentLog) {
        self.logs = logs
        
        let json = JSONEncoder()
        do {
            if let string = String(data: try json.encode(logs), encoding: .utf8) {
                self.document.updateLogs(string)
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    public func trim(string: String, range: NSRange) -> String {
        return self.trimmer.trim(string: string, range: range)
    }
    
    public var headings: [HeadingToken] {
        return self.editorController.getParagraphs()
    }
    
    public var topLevelHeadings: [HeadingToken] {
        return self.editorController.textStorage.topLevelHeadings
    }
    
    public func subHeading(for heading: HeadingToken) -> [HeadingToken] {
        return self.editorController.textStorage.subheadings(of: heading)
    }
    
    public func foldedRange(at location: Int) -> NSRange? {
        return self.editorController.textStorage.foldedRange(at: location)
    }
    
    public var string: String {
        get { return editorController.string }
        set { self.replace(text: newValue, range: NSRange(location: 0, length: editorController.string.nsstring.length)) }
    }
    
    private var isReverting: Bool = false
    public func revertContent(complete: ((Bool) -> Void)? = nil) {
        guard !isReverting else { return }
        
        let url = self.document.fileURL
        
        isReverting = true
        self.document.revert(toContentsOf: url, completionHandler: { [weak self] status in
            if let string = self?.document.string {
                self?.editorController.string = string
            }
            complete?(status)
            
            self?.isReverting = false
        })
    }
    
    public func replace(text: String, range: NSRange) {
        self.editorController.replace(text: text, in: range)
        self.save()
    }
    
    public func isHeadingFolded(at location: Int) -> Bool {
        guard let headingToken = self.editorController.textStorage.heading(contains: location) else { return false }
        
        return self.editorController.textStorage.isHeadingFolded(heading: headingToken)
    }
    
    public var fileURL: URL {
        return document.fileURL
    }
    
    public var deepestEntryLevel: Int {
        self.editorController.textStorage.headingTokens.max { heading1, heading2 in
            return heading1.level > heading2.level
        }?.level ?? 0
    }
    
    public func tokens(at location: Int) -> [Token] {
        return self.editorController.textStorage.token(at: location)
    }
    
    public func heading(at location: Int) -> HeadingToken? {
        return self.editorController.textStorage.heading(contains: location)
    }
    
    public func parentHeading(at location: Int) -> HeadingToken? {
        return self.editorController.textStorage.parentHeading(contains: location)
    }
    
    public var currentCursorTokens: [Token] {
        return self.editorController.textStorage.currentTokens
    }
    
    public func updateCurrentCursor(_ cursorLocation: Int) {
        self.editorController.textStorage.cursorLocation = cursorLocation
    }
    
    public func getProperties(heading at: Int) -> [String: String]? {
        return self.editorController.textStorage.propertyContentForHeading(at: at)
    }
    
    public func hiddenRange(location: Int) -> NSRange? {
        guard location < self.string.count else { return nil }
        
        var range: NSRange = NSRange(location: 0, length: 0)
        if let value = self.editorController.textStorage.attribute(OutlineAttribute.hidden, at: location, effectiveRange: &range) as? NSNumber, value.intValue != 2 {
            return range
        } else if let value = self.editorController.textStorage.attribute(OutlineAttribute.tempHidden, at: location, effectiveRange: &range) as? NSNumber, value.intValue != 0 && value.intValue != 2 {
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
        
        editorController.insertToParagraph(at: heading, content: content)
        
        self.document.updateContent(editorController.string)
    }

    public func rename(newTitle: String, completion: (() -> Void)? = nil) {
        let newURL = document.fileURL.deletingLastPathComponent().appendingPathComponent(newTitle).appendingPathExtension(Document.fileExtension)
        self.document = Document(fileURL: newURL)
        self.open(completion: { [weak self] _ in
            completion?()
            self?.onTitleChanged.onNext(newTitle)
        })
    }
    
    public func save(completion: ((Bool) -> Void)? = nil) {
        guard self.isOpen else { return }
        
        queue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.document.updateContent(strongSelf.editorController.string)
            strongSelf.document.save(to: strongSelf.document.fileURL, for: UIDocument.SaveOperation.forOverwriting) { success in
                
                DispatchQueue.runOnMainQueueSafely {
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
        self.document.fileURL.delete(queue: self.queue) {
            completion?($0)
        }
    }
    
    public func find(target: String, found: @escaping ([NSRange]) -> Void) throws {
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
            
            DispatchQueue.runOnMainQueueSafely {
                found(matchedRanges)
            }
        }
    }
        
    internal func headingList() -> [HeadingToken] {
        return self.editorController.getParagraphs()
    }
}

extension EditorService: EditorControllerDelegate {
    public func markFoldingState(heading: HeadingToken, isFolded: Bool) {
        self.logs?.headings[heading.identifier] = DocumentLog.Heading(isFold: isFolded, id: heading.identifier)
        
        if let logs = self.logs {
            self.updateLogs(logs)
        }
    }
    
    public func currentHeadingDidChange(heading: HeadingToken?) {
        
    }
    
    public func headingChanged(newHeadings: [HeadingToken], oldHeadings: [HeadingToken]) {
        log.info("heading changed from file: \(self.fileURL)")
        self.eventObserver.emit(DocumentHeadingChangeEvent(url: self.fileURL,
                                                           oldHeadings: oldHeadings,
                                                           newHeadings: newHeadings))
    }
    
    public func getLogs() -> DocumentLog? {
        return self.logs
    }
}
