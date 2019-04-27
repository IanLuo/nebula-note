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
            return IncreaseIndentCommandComposer(location: location)
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
    
    public weak var coordinator: EditorCoordinator?
    
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
        self.addStatesObservers()
        
        editorService.onReadyToUse = { [weak editorService] in
            editorService?.open {
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
    
    public func cursorLocationChanged(_ newLocation: Int) {
        self._editorService.updateCurrentCursor(newLocation)
        self.delegate?.didEnterTokens(self._editorService.currentCursorTokens)
    }
    
    public func save(completion: @escaping () -> Void) {
        _editorService.save { _  in
            completion()
        }
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
    
    public func foldOrUnfold(location: Int) {
        _ = self._editorService.toggleContentCommandComposer(composer: FoldCommandComposer(location: location)).perform()
    }
    
    public func foldAll() {
        _ = self._editorService.toggleContentCommandComposer(composer: FoldAllCommandComposer()).perform()
    }
    
    public func unfoldAll() {
        _ = self._editorService.toggleContentCommandComposer(composer: UnfoldAllCommandComposer()).perform()
    }
    
    public func performAction(_ action: EditAction, textView: UITextView, completion: ((DocumentContentCommandResult) -> Void)?) {
        let command = self._editorService.toggleContentCommandComposer(composer: action.commandComposer)
        
        self.performContentCommand(command, textView: textView, completion: completion)
    }
    
    private func performContentCommand(_ command: DocumentContentCommand, textView: UITextView, completion: ((DocumentContentCommandResult) -> Void)?) {
        guard let replaceCommand = command as? ReplaceTextCommand else { return }
        replaceCommand.manullayReplace = { range, string in
            let start = textView.position(from: textView.beginningOfDocument, offset: range.location)!
            let end = textView.position(from: textView.beginningOfDocument, offset: range.upperBound)!
            textView.replace(textView.textRange(from: start, to: end)!, withText: string)
        }
        let result = replaceCommand.perform()
        
        if result.isModifiedContent {
            self._editorService.save()
        } else {
            self._editorService.markAsContentUpdated()
        }
        
        completion?(result)
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
    fileprivate func addStatesObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStatesChanges),
                                               name: UIDocument.stateChangedNotification,
                                               object: nil)
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
