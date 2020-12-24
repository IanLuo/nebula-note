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
import Interface
import RxCocoa

public protocol DocumentEditViewModelDelegate: class {
    func updateHeadingInfo(heading: HeadingToken?)
    func didReadyToEdit()
    func didEnterTokens(_ tokens: [Token])
}

public class DocumentEditorViewModel: ViewModelProtocol {
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
    
    public let backlinks: BehaviorRelay<[URL]> = BehaviorRelay(value: [])
    
    public func tokens(at location: Int) -> [Token] {
        return self._editorService.tokens(at: location)
    }
    
    public var attachments: [Attachment] {
        return self._editorService
            .allTokens
            .compactMap { attachmentToken in
                if let keyRange = (attachmentToken as? AttachmentToken)?.keyRange {
                    return self.dependency.attachmentManager.attachment(with: (self.string as NSString).substring(with: keyRange))
                } else {
                    return nil
                }
            }
    }

    public var isReadyToEdit: Bool = false {
        didSet {
            if isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public var isResolvingConflict: Bool = false
    
    public convenience init(editorService: EditorService, coordinator: EditorCoordinator) {
        self.init(coordinator: coordinator)
        
        self._editorService = editorService
        
        self.addObservers()
    }
    
    private var isOpenning: Bool = false
    public func start() {
        guard !self._editorService.isOpen else {
            
            // if the service is cached, new view model may not get the ready tag set
            if !self.isReadyToEdit {
                self.isReadyToEdit = true
            }
            return
        }
        
        guard !isOpenning else { return }
        
        self.isOpenning = true
        
        self._editorService.onReadyToUse = { [weak self] service in
            service.open {
                self?.isReadyToEdit = $0 != nil
                self?.isOpenning = false
            }
        }
    }
    
    deinit {
        guard let usage = self.context.coordinator?.usage else { return }
        switch usage {
        case .editor:
            self._editorService.close()
            self.removeObservers()
        default: break
        }
    }
    
    private let disposeBag = DisposeBag()
    
    public var url: URL {
        return self._editorService.fileURL
    }
    
    public var string: String {
        return self._editorService.string
    }
    
    public func revertContent(shouldSaveBeforeRevert: Bool = true) {
        if shouldSaveBeforeRevert {
            self._editorService.save { [weak self] isTrue in
                if isTrue && self?.isReadyToEdit == true {                    
                    self?._editorService.revertContent()
                }
            }
        } else {
            self._editorService.revertContent()
        }
    }
    
    var isTemp: Bool {
        return self._editorService.isTemp
    }
    
    public func createHeadingIdIfNotExisted(textView: UITextView?) {
        // add id for headings don't have a id
        for heading in self._editorService.headings.reversed() {
            if heading.id == nil {
                let newId = "{id:\(UUID().uuidString)}"
                let resut = self._editorService.toggleContentCommandComposer(composer: ReplaceContentCommandComposer(range: heading.levelRange.tail(0), textToReplace: newId)).perform()
                
                if let textView = textView {
                    let oldSelection = textView.selectedRange
                    textView.selectedRange = oldSelection.offset(resut.delta)
                }
            }
        }
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
    
    public func isSectionFolded(at location: Int) -> Bool {
        return self._editorService.isHeadingFolded(at: location)
    }
    
    public func save(completion: @escaping () -> Void) {
        guard self.isReadyToEdit else { return }
        
        _editorService.save { _  in
            completion()
        }
    }
    
    public func getProperties(heading at: Int) -> [String: String] {
        if let content = self._editorService.getProperties(heading: at) {
            return content
        } else {
            _ = self._editorService
                .toggleContentCommandComposer(composer: EditAction.setProperty(at, [:]).commandComposer)
                .perform()
            return getProperties(heading: at)
        }
    }
    
    public func loadBacklinks() {
        self.dependency.documentSearchManager.searchBacklink(url: self.url).subscribe(onNext: { [weak self] in
            self?.backlinks.accept($0)
        }).disposed(by: self.disposeBag)
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
    
    public func parentHeading(at location: Int) -> HeadingToken? {
        return self._editorService.parentHeading(at: location)
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
    
    public func unfold(location: Int) {
        _ = self._editorService.toggleContentCommandComposer(composer: UnfoldToLocationCommandCompose(location: location)).perform()
    }
    
    public func fold(location: Int) {
        _ =  self._editorService.toggleContentCommandComposer(composer: FoldToLocationCommandCompose(location: location)).perform()
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
        
        // remove file from openning list
        self.dependency.settingAccessor.logCloseDocument(url: self.url)
    }
    
    public func handleConflict(url choosen: URL, completion: @escaping () -> Void) throws {
        
        guard let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: self.url) else { return }
        var isResolved = false
        
        let completeResolving = {
            if !isResolved {
                // keep the current version
                do {
                    try NSFileVersion.removeOtherVersionsOfItem(at: self.url)
                } catch {
                    log.error(error)
                }
            }
            
            for version in conflictVersions {
                version.isResolved = true
            }
            
            completion()
        }
        
        for case let version in conflictVersions where version.url == choosen {
            try version.replaceItem(at: self.url, options: [.init(rawValue: 0)])
            try NSFileVersion.removeOtherVersionsOfItem(at: self.url)
            self._editorService.revertContent { status in
                isResolved = true
                completeResolving()
                return
            }
        }
        
        completeResolving()
        self.isResolvingConflict = false
        
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

extension DocumentEditorViewModel {
    fileprivate func addObservers() {
        guard let usage = self.context.coordinator?.usage else { return }
        
        switch usage {
        case .outline:
            return
        default: break
        }
        
        self.dependency.eventObserver.registerForEvent(on: self,
                                                               eventType: NewDocumentPackageDownloadedEvent.self,
                                                               queue: .main,
                                                               action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
            if event.url.documentRelativePath == self?.url.documentRelativePath {
                
            }
        })
        
//        self.dependency.appContext.isReadingMode.subscribe(onNext: {[weak self] isReadingMode in
//            self?.isReadingModel = isReadingMode
//        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
}
