//
//  PageViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/1.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol DocumentEditViewModelDelegate: class {
    func updateHeadingInfo(heading: HeadingToken?)
    func documentStatesChange(state: UIDocument.State)
    func didReadyToEdit()
    func didEnterTokens(_ tokens: [Token])
}

public enum EditAction {
    case toggleCheckboxStatus(Int, String)
    case addAttachment(Int, String, String)
    case updateDateAndTime(Int, DateAndTimeType?)
    case addTag(String, Int)
    case removeTag(String, Int)
    case changePlanning(String, Int)
    case changePriority(String?, Int)
    case removePlanning(Int)
    case insertText(String, Int)
    case archive(Int)
    case unarchive(Int)
    case insertSeparator(Int)
    case textMark(OutlineParser.MarkType, NSRange)
    case increaseIndent(Int)
    case decreaseIndent(Int)
    case quoteBlock(Int)
    case codeBlock(Int)
    case unorderedListSwitch(Int)
    case orderedListSwitch(Int)
    case checkboxSwitch(Int)
    case moveLineUp(Int)
    case moveLineDown(Int)
    case updateHeadingLevel(Int, Int)
    case updateLink(Int, String)
    case convertToHeading(Int)
    case convertHeadingToParagraph(Int)
    case addNewLineBelow(location: Int)
    case replaceText(NSRange, String)
    case removeParagraph(Int)
    
    public var commandComposer: DocumentContentCommandComposer {
        switch self {
        case .toggleCheckboxStatus(let location, let checkbox):
            return CheckboxStatusCommandComposer(location: location, checkboxString: checkbox)
        case let .addAttachment(location, attachmentId, kind):
            return AddAttachmentCommandComposer(attachmentId: attachmentId, location: location, kind: kind)
        case let .addTag(tag, location):
            return TagCommandComposer(location: location, kind: .add(tag))
        case let .removeTag(tag, location):
            return TagCommandComposer(location: location, kind: .remove(tag))
        case let .changePlanning(planning, location):
            return PlanningCommandComposer(location: location, kind: .addOrUpdate(planning))
        case let .changePriority(priority, location):
            return PriorityCommandComposer(location: location, priority: priority)
        case let .removePlanning(location):
            return PlanningCommandComposer(location: location, kind: .remove)
        case let .insertText(text, location):
            return InsertTextToHeadingCommandComposer(location: location, textToInsert: text)
        case let .archive(location):
            return ArchiveCommandComposer(location: location)
        case let .unarchive(location):
            return UnarchiveCommandComposer(location: location)
        case .insertSeparator(let location):
            return AddSeparatorCommandComposer(location: location)
        case .textMark(let markType, let range):
            return TextMarkCommandComposer(markType: markType, range: range)
        case .increaseIndent(let location):
            return IncreaseIndentCommandComposer(location: location)
        case .decreaseIndent(let location):
            return DecreaseIndentCommandComposer(location: location)
        case .quoteBlock(let location):
            return QuoteBlockCommandComposer(location: location)
        case .codeBlock(let location):
            return CodeBlockCommandComposer(location: location)
        case let .updateDateAndTime(location, dateAndTime):
            return UpdateDateAndTimeCommandComposer(location: location, dateAndTime: dateAndTime)
        case let .unorderedListSwitch(location):
            return UnorderdListSwitchCommandComposer(location: location)
        case let .orderedListSwitch(location):
            return OrderedListSwitchCommandComposer(location: location)
        case let .checkboxSwitch(location):
            return CheckboxSwitchCommandComposer(location: location)
        case .moveLineUp(let location):
            return MoveLineUpCommandComposer(location: location)
        case .moveLineDown(let location):
            return MoveLineDownCommandComposer(location: location)
        case .updateHeadingLevel(let location, let newLevel):
            return HeadingLevelChangeCommandComposer(location: location, newLevel: newLevel)
        case .updateLink(let location, let link):
            return UpdateLinkCommandCompser(location: location, link: link)
        case .convertToHeading(let location):
            return ConvertLineToHeadingCommandComposer(location: location)
        case .convertHeadingToParagraph(let location):
            return ConvertHeadingLineToParagragh(location: location)
        case .addNewLineBelow(let location):
            return AddNewLineBelowCommandComposer(location: location)
        case .replaceText(let range, let textToReplace):
            return ReplaceContentCommandComposer(range: range, textToReplace: textToReplace)
        case .removeParagraph(let location):
            return RemoveParagraphCommandComposer(location: location)
        }
    }
}

public class DocumentEditViewModel {
    public weak var delegate: DocumentEditViewModelDelegate? {
        didSet {
            if self.isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public var onLoadingLocation: Int = 0 // 打开文档的时候默认的位置
    
    public weak var coordinator: EditorCoordinator? {
        didSet {
            self.addObservers()
        }
    }
    
    private let _editorService: EditorService
    
    public var currentTokens: [Token] = []
    
    public var isReadyToEdit: Bool = false {
        didSet {
            if isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public init(editorService: EditorService) {
        self._editorService = editorService
        
        editorService.onReadyToUse = { service in
            service.open {
                self.isReadyToEdit = $0 != nil
            }
        }
    }
    
    deinit {
        self.removeObservers()
    }
    
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
    
    public func cursorLocationChanged(_ newLocation: Int) {
        self._editorService.updateCurrentCursor(newLocation)
        self.delegate?.didEnterTokens(self._editorService.currentCursorTokens)
    }
    
    public func save(completion: @escaping () -> Void) {
        _editorService.save { _  in
            completion()
        }
    }
    
    public func close(completion: @escaping (Bool) -> Void) {
        self._editorService.close(completion: completion)
    }
    
    public func headingString(index: Int) -> String {
        let headingTextRange = self.headings[index].headingTextRange
        return self._editorService.string.substring(headingTextRange)
    }
    
    public func documentHeading(at: Int) -> DocumentHeading {
        return DocumentHeading(documentString: self._editorService.string, headingToken: self.headings[at], url: self._editorService.fileURL)
    }
    
    public func tags(at location: Int) -> [String] {
        return self._editorService.heading(at: location)?.tagsArray(string: self._editorService.string) ?? []
    }
    
    public func priority(at location: Int) -> String? {
        if let priorityRange = self._editorService.heading(at: location)?.priority {
            return self._editorService.string.substring(priorityRange)
        } else {
            return nil
        }
    }
    
    public func planning(at location: Int) -> String? {
        if let planningRange = self._editorService.heading(at: location)?.planning {
            return self._editorService.string.substring(planningRange)
        } else {
            return nil
        }
    }
    
    public func refileOtherDocument(url: URL, heading: DocumentHeading, location: Int, completion: @escaping (DocumentContentCommandResult) -> Void) {
        self.coordinator?.dependency.editorContext.request(url: url).onReadyToUse = { [weak self] service in
            service.start(complete: { isReady, service in
                guard let strongSelf = self else { return }
                
                guard let heading = strongSelf._editorService.heading(at: location) else { return }
                
                let text = heading.range.location == 0
                    ? strongSelf._editorService.string.substring(heading.paragraphRange)
                    : strongSelf._editorService.string.substring(heading.paragraphRange.moveLeftBound(by: -1)) // 移动的时候，把上一段末尾的换行符也带走
                
                // 1. 删除当前的段落
                let result = strongSelf._editorService.toggleContentCommandComposer(composer: EditAction.removeParagraph(location).commandComposer).perform()
                
                // 2. 插入到新的位置
                service.replace(text: text, range: NSRange(location: heading.paragraphRange.upperBound - 1, length: 0))
                
                completion(result)
            })
        }
    }
    
    public func moveParagraph(contains location: Int, to toHeading: DocumentHeading, textView: UITextView) -> DocumentContentCommandResult {
        guard let currentHeading = self._editorService.heading(at: location) else { return DocumentContentCommandResult.noChange }
        
        let text = currentHeading.range.upperBound == self._editorService.string.count
            ? self._editorService.string.substring(currentHeading.paragraphRange) + "\n"
            : self._editorService.string.substring(currentHeading.paragraphRange)
        
        // 1. 删除旧的段落
        let removedResult = self.performAction(EditAction.removeParagraph(location),
                                               textView: textView)
        
        // 2. 插入到新的位置
        var newLocation = NSRange(location: toHeading.paragraphRange.upperBound, length: 0) // 如果删除的文本在插入位置之前，则插入位置要先减少删除文本的长度
        if location <= newLocation.location {
            newLocation = newLocation.offset(-removedResult.content!.count)
        }
        let result = self.performAction(EditAction.replaceText(newLocation, text),
                                                  textView: textView)
        return result
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
        let command = self._editorService.toggleContentCommandComposer(composer: action.commandComposer)
        
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStatesChanges),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
        
        coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                               eventType: NewDocumentPackageDownloadedEvent.self,
                                                               queue: .main,
                                                               action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
            if event.url.documentRelativePath == self?.url.documentRelativePath {
                
            }
        })
    }
    
    fileprivate func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleStatesChanges(notification: Notification) {
        if let state = notification.object as? UIDocument.State {
            self.delegate?.documentStatesChange(state: state)
        }
    }
}
