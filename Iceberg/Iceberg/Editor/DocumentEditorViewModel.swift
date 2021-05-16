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
    
    private var editorService: EditorService!
    
    public var currentTokens: [Token] = []
    
    public let backlinks: BehaviorRelay<[URL]> = BehaviorRelay(value: [])
    
    public func tokens(at location: Int) -> [Token] {
        return self.editorService.tokens(at: location)
    }
    
    public var attachments: [Attachment] {
        return self.editorService
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
                switch self.context.coordinator?.usage {
                case .editor:
                    self.editorService.syncFoldingStatus()
                default: break
                }
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public var isResolvingConflict: Bool = false
    
    public convenience init(editorService: EditorService, coordinator: EditorCoordinator) {
        self.init(coordinator: coordinator)
        
        self.editorService = editorService
        
        self.addObservers()
    }
    
    private var isOpenning: Bool = false
    public func start() {
        guard !self.editorService.isOpen else {
            
            // if the service is cached, new view model may not get the ready tag set
            if !self.isReadyToEdit {
                self.isReadyToEdit = true
            }
            return
        }
        
        guard !isOpenning else { return }
        
        self.isOpenning = true
        
        self.editorService.onReadyToUse = { [weak self] service in
            service.open {
                self?.isReadyToEdit = $0 != nil
                self?.isOpenning = false
                self?.isFavorite.accept((self?.dependency
                                            .settingAccessor
                                            .getSetting(item: SettingsAccessor.Item.favoriteDocuments,
                                                        type: [String].self) ?? []).contains(where: {
                                                            $0 == self?.editorService.id
                                                        }))
            }
        }
    }
    
    deinit {
        self.close()
    }
    
    public func close() {
        self.removeObservers()
        self.context.dependency.editorContext.closeIfOpen(url: self.url, complete: {})
    }
    
    private let disposeBag = DisposeBag()
    
    public var url: URL {
        return self.editorService.fileURL
    }
    
    public var string: String {
        return self.editorService.string
    }
    
    public func revertContent(shouldSaveBeforeRevert: Bool = true) {
        if shouldSaveBeforeRevert {
            self.editorService.save { [weak self] isTrue in
                if isTrue && self?.isReadyToEdit == true {                    
                    self?.editorService.revertContent() { _ in
                        self?.editorService.syncFoldingStatus()
                    }
                }
            }
        } else {
            self.editorService.revertContent() { [weak self] _ in
                self?.editorService.syncFoldingStatus()
            }
        }
    }
    
    var isTemp: Bool {
        return self.editorService.isTemp
    }
    
    public func createHeadingIdIfNotExisted(textView: UITextView?) {
        // add id for headings which don't have an id yet
        for heading in self.editorService.headings.reversed() {
            if heading.id == nil {
                let newId = "{id:\(UUID().uuidString)}"
                let resut = self.editorService.toggleContentCommandComposer(composer: ReplaceContentCommandComposer(range: heading.levelRange.tail(0), textToReplace: newId)).perform()
                self.editorService.markAsContentUpdated()
                
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
        let attriutes = try? FileManager.default.attributesOfItem(atPath: self.editorService.fileURL.path)
        let date = (attriutes?[FileAttributeKey.modificationDate] as? Date) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    public var createDate: String {
        let attriutes = try? FileManager.default.attributesOfItem(atPath: self.editorService.fileURL.path)
        let date = (attriutes?[FileAttributeKey.creationDate] as? Date) ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    public var container: NSTextContainer {
        return self.editorService.container
    }
    
    public var cover: UIImage? {
        get { return self.editorService.cover }
        set { self.editorService.cover = newValue }
    }
    
    public var headings: [HeadingToken] {
        return self.editorService.headings
    }
    
    public var documentInfo: DocumentInfo {
        return self.editorService.documentInfo
    }
    
    public var isReadingModel: Bool {
        get { return self.editorService.isReadingMode }
        set {
            self.editorService.isReadingMode = newValue
            self.revertContent()
        }
    }
    
    public let isFavorite: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    
    public func setIsFavorite(_ isFavorite: Bool) {
        var favoriteDocuments = self.dependency
            .settingAccessor
            .getSetting(item: SettingsAccessor.Item.favoriteDocuments,
                        type: [String].self) ?? []
            
        let id = self.editorService.id
        if isFavorite == true {
            if !favoriteDocuments.contains(id) {
                favoriteDocuments.append(id)
                self.dependency.settingAccessor.setSetting(item: SettingsAccessor.Item.favoriteDocuments, value: favoriteDocuments) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.isFavorite.accept(true)
                    strongSelf.dependency.eventObserver.emit(DocumentFavoriteChangedEvent(url: strongSelf.url, isFavorite: isFavorite))
                }
            } else {
                self.isFavorite.accept(true)
                self.dependency.eventObserver.emit(DocumentFavoriteChangedEvent(url: self.url, isFavorite: isFavorite))
            }
        } else {
            for case let (index, documentId) in favoriteDocuments.enumerated() where documentId == id {
                favoriteDocuments.remove(at: index)
                self.dependency.settingAccessor.setSetting(item: SettingsAccessor.Item.favoriteDocuments, value: favoriteDocuments) { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.dependency.eventObserver.emit(DocumentFavoriteChangedEvent(url: strongSelf.url, isFavorite: isFavorite))
                    strongSelf.isFavorite.accept(false)
                }
                return
            }
            
            self.isFavorite.accept(false)
            self.dependency.eventObserver.emit(DocumentFavoriteChangedEvent(url: self.url, isFavorite: isFavorite))
        }
    }
    
    public func hiddenRange(at location: Int) -> NSRange? {
        return self.editorService.hiddenRange(location: location)
    }

    public func cursorLocationChanged(_ newLocation: Int) {
        self.editorService.updateCurrentCursor(newLocation)
        self.delegate?.didEnterTokens(self.editorService.currentCursorTokens)
    }
    
    public func paragraphWithSubRange(at location: Int) -> NSRange? {
        return self.editorService.heading(at: location)?.paragraphWithSubRange
    }
    
    public func foldedRange(at location: Int) -> NSRange? {
        return self.editorService.foldedRange(at: location)
    }
    
    public func isSectionFolded(at location: Int) -> Bool {
        return self.editorService.isHeadingFolded(at: location)
    }
    
    public func save(completion: @escaping () -> Void) {
        guard self.isReadyToEdit else { return }
        
        editorService.save { _  in
            completion()
        }
    }
        
    public func getProperties(heading at: Int) -> [String: String] {
        if let content = self.editorService.getProperties(heading: at) {
            return content
        } else {
            _ = self.editorService
                .toggleContentCommandComposer(composer: EditAction.setProperty(at, [:]).commandComposer)
                .perform()
            return getProperties(heading: at)
        }
    }
    
    public func loadBacklinks() {
        self.dependency.documentSearchManager.searchBacklink(documentId: self.editorService.id, headingIds: self.editorService.logs?.headings.map { $0.key } ?? [], url: self.url).subscribe(onNext: { [weak self] in
            self?.backlinks.accept($0)
        }).disposed(by: self.disposeBag)
    }
    
    public func headingString(index: Int) -> String {
        let headingTextRange = self.headings[index].headingTextRange
        return self.editorService.string.nsstring.substring(with: headingTextRange)
    }
    
    /// get the heading at the index of the heading array
    public func documentHeading(at index: Int) -> DocumentHeading {
        return DocumentHeading(documentString: self.editorService.string, headingToken: self.headings[index], url: self.editorService.fileURL)
    }
    
    public func tags(at location: Int) -> [String] {
        return self.editorService.heading(at: location)?.tagsArray(string: self.editorService.string) ?? []
    }
    
    public func heading(at location: Int) -> HeadingToken? {
        return self.editorService.heading(at: location)
    }
    
    public func parentHeading(at location: Int) -> HeadingToken? {
        return self.editorService.parentHeading(at: location)
    }
    
    public func priority(at location: Int) -> String? {
        if let priorityRange = self.editorService.heading(at: location)?.priority {
            return self.editorService.string.nsstring.substring(with: priorityRange)
        } else {
            return nil
        }
    }
    
    public func planning(at location: Int) -> String? {
        if let planningRange = self.editorService.heading(at: location)?.planning {
            return self.editorService.string.nsstring.substring(with: planningRange)
        } else {
            return nil
        }
    }
    
    public func moveParagraphToOtherDocument(url: URL, outline otherOutline: OutlineLocation, location: Int, textView: UITextView, completion: @escaping (DocumentContentCommandResult) -> Void) {
        self.dependency.editorContext.request(url: url).onReadyToUse = { [weak self] service in
            service.open(completion: { string in
                guard let strongSelf = self else { return }
                
                guard let heading = strongSelf.editorService.heading(at: location) else { return }
                
                var text = heading.paragraphWithSubRange.location == 0
                    ? strongSelf.editorService.string.nsstring.substring(with: heading.paragraphWithSubRange) + "\n"
                    : strongSelf.editorService.string.nsstring.substring(with: heading.paragraphWithSubRange)
                
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
                            if !strongSelf.editorService.string.hasSuffix("\n") {
                                text = "\n" + text
                            }
                        }
                        _ = service.toggleContentCommandComposer(composer: InsertTextCommandComposer(location: location, textToInsert: text)).perform()
                    }
                    
                    service.save { _ in
                        self?.dependency.editorContext.closeIfOpen(url: url) {
                            DispatchQueue.runOnMainQueueSafely {
                                completion(result)
                            }
                        }
                    }
                }
            })
        }
    }

    public func moveParagraph(contains location: Int, to outlineLocation: OutlineLocation, textView: UITextView) -> DocumentContentCommandResult {
        guard let currentHeading = self.editorService.heading(at: location) else { return DocumentContentCommandResult.noChange }
        
        var text = currentHeading.paragraphWithSubRange.upperBound == self.editorService.string.nsstring.length // 当前行为最后一行，插入前在会后一行加上换行符
            ? self.editorService.string.nsstring.substring(with: currentHeading.paragraphWithSubRange) + "\n"
            : self.editorService.string.nsstring.substring(with: currentHeading.paragraphWithSubRange)
        
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
            } else if toLocation == self.editorService.string.count {
                if !self.editorService.string.hasSuffix("\n") {
                    text = "\n" + text
                }
            }
            
            return self.performCommandComposer(InsertTextCommandComposer(location: toLocation, textToInsert: text), textView: textView)
        }
    }
    
    public func foldOrUnfold(location: Int) {
        let shouldFold = !self.isSectionFolded(at: location)
        
        if shouldFold {
            self.fold(location: location)
        } else {
            self.unfold(location: location)
        }
        
        self.editorService.syncFoldingStatus()
    }
        
    public func foldAll() {
        for heading in self.headings {
            self.editorService.markFoldingState(heading: heading, isFolded: true)
        }

        self.editorService.syncFoldingStatus()
    }
    
    public func unfoldAll() {
        for heading in self.headings {
            self.editorService.markFoldingState(heading: heading, isFolded: false)
        }
        
        self.revertContent()
    }
    
    public func unfold(location: Int) {
        for heading in self.headings {
            if heading.paragraphWithSubRange.contains(location) || heading.range.location == location {
                self.editorService.markFoldingState(heading: heading, isFolded: false)
            }
        }
        
        self.editorService.syncFoldingStatus()
    }
    
    public func foldOtherHeadings(except location: Int) {
        for heading in self.headings {
            let range = heading.paragraphWithSubRange
            let shouldOpen = range.contains(location) || range.location == location
            self.editorService.markFoldingState(heading: heading, isFolded: !shouldOpen)
        }
        
        self.editorService.syncFoldingStatus()
    }
    
    public func fold(location: Int) {
        if let heading = self.heading(at: location) {
            self.editorService.markFoldingState(heading: heading, isFolded: true)
            
            for subHeading in self.editorService.subHeading(for: heading) {
                self.editorService.markFoldingState(heading: subHeading, isFolded: true)
            }
        }
        
        self.editorService.syncFoldingStatus()
    }
    
    private func isRepeatingTextMark(markType: OutlineParser.MarkType, textView: UITextView, range: NSRange) -> Bool {
        guard range.location > 0 && range.upperBound < textView.text.count else { return false }
        
        if (textView.text as NSString).substring(with: range.moveLeftBound(by: -1).head(1)) == markType.mark
            && (textView.text as NSString).substring(with: range.moveRightBound(by: 1).tail(1)) == markType.mark {
                return true
        } else {
            return false
        }
    }
    
    public func performAction(_ action: EditAction, textView: UITextView) -> DocumentContentCommandResult {

        // if the action is text mark, and the text mark is repeat, remove the mark
        switch action {
        case let .textMark(markType, range):
            if isRepeatingTextMark(markType: markType, textView: textView, range: range) {
                let range = range.moveLeftBound(by: -1).moveRightBound(by: 1)
                return performCommandComposer(RemoveTextMarkCommandComposer(markType: markType, range: range), textView: textView)
            }
            
        case .addHeadingAtBottom:
            self.unfold(location: self.string.count - 1)
        default: break
        }
        
        let result = performCommandComposer(action.commandComposer, textView: textView)
        
        switch action {
        case .moveLineUp:
            self.editorService.syncFoldingStatus()
        case .moveLineDown:
            self.editorService.syncFoldingStatus()
        default: break
        }
        
        return result
    }
    
    public func performCommandComposer(_ commandComposer: DocumentContentCommandComposer, textView: UITextView) -> DocumentContentCommandResult {
        let command = self.editorService.toggleContentCommandComposer(composer: commandComposer)
        
        if let replaceCommand = command as? ReplaceTextCommand {
            
            replaceCommand.manullayReplace = { range, string in
                let start = textView.position(from: textView.beginningOfDocument, offset: range.location)!
                let end = textView.position(from: textView.beginningOfDocument, offset: range.upperBound)!
                textView.replace(textView.textRange(from: start, to: end)!, withText: string)
            }
        }
        
        let result = command.perform()
        
        if result.isModifiedContent {
            self.editorService.markAsContentUpdated()
        }
        
        return result
    }
    
    public func level(index: Int) -> Int {
        return self.headings[index].level
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        self.editorService.rename(newTitle: newTitle, completion: completion)
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        self.editorService.delete(completion: completion)
        
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
            self.editorService.revertContent { status in
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
            try self.editorService.find(target: target, found: found)
        }
        catch {
            log.error("\(error)")
        }
    }
    
    public func didUpdate() {
        self.editorService.markAsContentUpdated()
    }
    
    public func rename(to: String, completion: @escaping (Error?) -> Void) {
        self.editorService.rename(newTitle: to, completion: completion)
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
