//
//  PageViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/1.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Core
import RxSwift

public protocol DocumentEditViewModelDelegate: class {
    func updateHeadingInfo(heading: HeadingToken?)
    func didReadyToEdit()
    func didEnterTokens(_ tokens: [Token])
}

public class DocumentEditViewModel: ViewModelProtocol {
    public required init() {}
    
    public var context: ViewModelContext<EditorCoordinator>!
    
    public typealias CoordinatorType = EditorCoordinator
    
    public weak var delegate: DocumentEditViewModelDelegate? {
        didSet {
            if self.isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public var onLoadingLocation: Int = 0 // 打开文档的时候默认的位置
    
    private var _editorService: EditorService!
    
    public var currentTokens: [Token] = []
    
    public var isReadyToEdit: Bool = false {
        didSet {
            if isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public convenience init(editorService: EditorService, coordinator: EditorCoordinator) {
        self.init(coordinator: coordinator)
        
        self._editorService = editorService
        
        editorService.onReadyToUse = { [weak self] service in
            service.open {
                self?.isReadyToEdit = $0 != nil
            }
        }
        
        self.addObservers()
    }
    
    deinit {
        self._editorService.close()
        self.removeObservers()
    }
    
    private let disposeBag = DisposeBag()
    
    public var url: URL {
        return self._editorService.fileURL
    }
    
    public var string: String {
        return self._editorService.string
    }
    
    public func revertContent() {
        self._editorService.revertContent()
    }
    
    public var wordCount: Int {
        let chararacterSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let components = self.string.components(separatedBy: chararacterSet)
        return components.filter { !$0.isEmpty }.count
    }
    
    public var characterCount: Int {
        return self.string.count
    }
    
    public var paragraphCount: Int {
        return self.headings.count
    }
    
    public var editeDate: String {
        let attriutes = try? FileManager.default.attributesOfItem(atPath: self._editorService.fileURL.path)
        let date = (attriutes?[FileAttributeKey.modificationDate] as? Date) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    public var createDate: String {
        let attriutes = try? FileManager.default.attributesOfItem(atPath: self._editorService.fileURL.path)
        let date = (attriutes?[FileAttributeKey.creationDate] as? Date) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    public var container: NSTextContainer {
        return self._editorService.container
    }
    
    public var cover: UIImage? {
        get { return self._editorService.cover }
        set { self._editorService.cover = newValue }
    }
    
    public var headings: [HeadingToken] {
        return self._editorService.headings
    }
    
    public func isParagraphFolded(at location: Int) -> Bool {
        return self._editorService.isHeadingFolded(at: location)
    }
    
    public var isReadingModel: Bool {
        get { return self._editorService.isReadingMode }
        set {
            self._editorService.isReadingMode = newValue
            self.revertContent()
        }
    }
    
    public func hiddenRange(at location: Int) -> NSRange? {
        return self._editorService.hiddenRange(location: location)
    }
    
    public func cursorLocationChanged(_ newLocation: Int) {
        self._editorService.updateCurrentCursor(newLocation)
        self.delegate?.didEnterTokens(self._editorService.currentCursorTokens)
    }
    
    public func paragraphWithSubRange(at location: Int) -> NSRange? {
        return self._editorService.heading(at: location)?.paragraphWithSubRange
    }
    
    public func foldedRange(at location: Int) -> NSRange? {
        return self._editorService.foldedRange(at: location)
    }
    
    public func save(completion: @escaping () -> Void) {
        _editorService.save { _  in
            completion()
        }
    }
    
    public func close(completion: @escaping (Bool) -> Void) {
        self._editorService.close(completion: completion)
//        self.coordinator?.dependency.editorContext.end(with: self._editorService.fileURL)
    }
    
    public func headingString(index: Int) -> String {
        let headingTextRange = self.headings[index].headingTextRange
        return self._editorService.string.nsstring.substring(with: headingTextRange)
    }
    
    /// get the heading at the index of the heading array
    public func documentHeading(at index: Int) -> DocumentHeading {
        return DocumentHeading(documentString: self._editorService.string, headingToken: self.headings[index], url: self._editorService.fileURL)
    }
    
    public func tags(at location: Int) -> [String] {
        return self._editorService.heading(at: location)?.tagsArray(string: self._editorService.string) ?? []
    }
    
    public func heading(at location: Int) -> HeadingToken? {
        return self._editorService.heading(at: location)
    }
    
    public func priority(at location: Int) -> String? {
        if let priorityRange = self._editorService.heading(at: location)?.priority {
            return self._editorService.string.nsstring.substring(with: priorityRange)
        } else {
            return nil
        }
    }
    
    public func planning(at location: Int) -> String? {
        if let planningRange = self._editorService.heading(at: location)?.planning {
            return self._editorService.string.nsstring.substring(with: planningRange)
        } else {
            return nil
        }
    }
    
    public func moveParagraphToOtherDocument(url: URL, outline otherOutline: OutlineLocation, location: Int, textView: UITextView, completion: @escaping (DocumentContentCommandResult) -> Void) {
        self.dependency.editorContext.request(url: url).onReadyToUse = { [weak self] service in
            service.open(completion: { string in
                guard let strongSelf = self else { return }
                
                guard let heading = strongSelf._editorService.heading(at: location) else { return }
                
                var text = heading.paragraphWithSubRange.location == 0
                    ? strongSelf._editorService.string.nsstring.substring(with: heading.paragraphWithSubRange) + "\n"
                    : strongSelf._editorService.string.nsstring.substring(with: heading.paragraphWithSubRange)
                
                DispatchQueue.runOnMainQueueSafely {
                    // 1. 删除当前的段落
                    let result = strongSelf.performCommandComposer(EditAction.removeParagraph(location).commandComposer, textView: textView)
                    
                    switch otherOutline {
                    case .heading(let heading):
                        let location = heading.paragraphRange.location
                        _ = service.toggleContentCommandComposer(composer: AppendAsChildHeadingCommandComposer(text: text, to: location)).perform() // 移到另一个文件，不需要支持 undo
                    case .position(let location):
                        if location == 0 {
                            if !text.hasSuffix("\n") {
                                text = text + "\n"
                            }
                        } else if location == service.string.count {
                            if !strongSelf._editorService.string.hasSuffix("\n") {
                                text = "\n" + text
                            }
                        }
                        _ = service.toggleContentCommandComposer(composer: InsertTextCommandComposer(location: location, textToInsert: text)).perform()
                    }
                    
                    service.save(completion: { service, _ in
                        service.close(completion: { _ in
                            DispatchQueue.runOnMainQueueSafely {
                                completion(result)
                            }
                            
                            // add to file to recent changed file
                            self?.dependency.editorContext.recentFilesManager.addRecentFile(url: url, lastLocation: 0, completion: {
                                self?.dependency.eventObserver.emit(OpenDocumentEvent(url: url))
                            })
                        })
                    })
                    
                }
            })
        }
    }
    
    public func moveParagraph(contains location: Int, to outlineLocation: OutlineLocation, textView: UITextView) -> DocumentContentCommandResult {
        guard let currentHeading = self._editorService.heading(at: location) else { return DocumentContentCommandResult.noChange }
        
        var text = currentHeading.paragraphWithSubRange.upperBound == self._editorService.string.nsstring.length // 当前行为最后一行，插入前在会后一行加上换行符
            ? self._editorService.string.nsstring.substring(with: currentHeading.paragraphWithSubRange) + "\n"
            : self._editorService.string.nsstring.substring(with: currentHeading.paragraphWithSubRange)
        
        // 1. 删除旧的段落
        _ = self.performAction(EditAction.removeParagraph(location), textView: textView)
        
        // 2. 插入到新的位置
        switch outlineLocation {
        case .heading(let toHeading):
            return self.performCommandComposer(MoveToParagraphAsChildHeadingCommandComposer(text: text,
                                                                                            to: toHeading.location,
                                                                                            isToLocationBehindFromLocation: location <= toHeading.paragraphRange.upperBound),
                                                     textView: textView)
        case .position(let toLocation):
            // if the move to location is after move from location, should minus the removed text length then move
            var toLocation = toLocation
            if location < toLocation {
                toLocation = toLocation - text.count
            }
            
            if toLocation == 0 {
                if !text.hasSuffix("\n") {
                    text = text + "\n"
                }
            } else if toLocation == self._editorService.string.count {
                if !self._editorService.string.hasSuffix("\n") {
                    text = "\n" + text
                }
            }
            
            return self.performCommandComposer(InsertTextCommandComposer(location: toLocation, textToInsert: text), textView: textView)
        }
    }
    
    public func foldOrUnfold(location: Int) {
        _ = self._editorService.toggleContentCommandComposer(composer: FoldAndUnfoldCommandComposer(location: location)).perform()
    }
    
    public func unfoldExceptTo(location: Int) {
        self.foldAll()
        
        _ = self._editorService.toggleContentCommandComposer(composer: UnfoldToLocationCommandCompose(location: location)).perform()
    }
    
    public func foldAll() {
        _ = self._editorService.toggleContentCommandComposer(composer: FoldAllCommandComposer()).perform()
    }
    
    public func unfoldAll() {
        _ = self._editorService.toggleContentCommandComposer(composer: UnfoldAllCommandComposer()).perform()
    }
    
    public func performAction(_ action: EditAction, textView: UITextView) -> DocumentContentCommandResult {
        return performCommandComposer(action.commandComposer, textView: textView)
    }
    
    public func performCommandComposer(_ commandComposer: DocumentContentCommandComposer, textView: UITextView) -> DocumentContentCommandResult {
        let command = self._editorService.toggleContentCommandComposer(composer: commandComposer)
        
        if let replaceCommand = command as? ReplaceTextCommand {
            
            replaceCommand.manullayReplace = { range, string in
                let start = textView.position(from: textView.beginningOfDocument, offset: range.location)!
                let end = textView.position(from: textView.beginningOfDocument, offset: range.upperBound)!
                textView.replace(textView.textRange(from: start, to: end)!, withText: string)
            }
        }
        
        let result = command.perform()
        
        if result.isModifiedContent {
            self._editorService.markAsContentUpdated()
        }
        
        return result
    }
    
    public func level(index: Int) -> Int {
        return self.headings[index].level
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        self._editorService.rename(newTitle: newTitle, completion: completion)
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        self._editorService.delete(completion: completion)
    }
    
    public func handleConflict(url: URL) throws {
        
        guard let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: url) else { return }
        
        let sortedConflictVersions = conflictVersions.sorted { (version1, version2) -> Bool in
            guard let date1 = version1.modificationDate,
                let date2 = version2.modificationDate else { return true }
            return date1.timeIntervalSince1970 > date2.timeIntervalSince1970
        }
        
        if let newestVersion = sortedConflictVersions.first {
            try newestVersion.replaceItem(at: url, options: [])
            try NSFileVersion.removeOtherVersionsOfItem(at: url)
        }
        
        for version in sortedConflictVersions {
            version.isResolved = true
        }
    }

    
    public func find(target: String, found: @escaping ([NSRange]) -> Void) {
        do {
            try self._editorService.find(target: target, found: found)
        }
        catch {
            log.error("\(error)")
        }
    }
    
    public func didUpdate() {
        self._editorService.markAsContentUpdated()
    }
}

extension DocumentEditViewModel {
    fileprivate func addObservers() {
        self.dependency.eventObserver.registerForEvent(on: self,
                                                               eventType: NewDocumentPackageDownloadedEvent.self,
                                                               queue: .main,
                                                               action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
            if event.url.documentRelativePath == self?.url.documentRelativePath {
                
            }
        })
        
        self.dependency.appContext.isReadingMode.subscribe(onNext: {[weak self] isReadingMode in
            self?.isReadingModel = isReadingMode
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
}
