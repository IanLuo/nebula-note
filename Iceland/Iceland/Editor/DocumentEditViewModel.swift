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
    func showLink(url: URL)
    func updateHeadingInfo(heading: HeadingToken?)
    func documentStatesChange(state: UIDocument.State)
    func didReadyToEdit()
    func didEnterTokens(_ tokens: [Token])
    func documentContentCommandDidPerformed(result: DocumentContentCommandResult)
}

public enum EditAction {
    case toggleCheckboxStatus(Int, String)
    case addAttachment(Int, String, String)
    case updateDateAndTime(NSRange, DateAndTimeType)
    case addTag(String, Int)
    case removeTag(String, Int)
    case changePlanning(String, Int)
    case removePlanning(Int)
    case insertText(String, Int)
    case replaceHeading(Int, Int)
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
        case let .removePlanning(location):
            return PlanningCommandComposer(location: location, kind: .remove)
        case let .insertText(text, location):
            return InsertTextToHeadingCommandComposer(location: location, textToInsert: text)
        case let .replaceHeading(fromLocation, toLocation):
            return ReplaceHeadingCommandComposer(fromLocation: fromLocation, toLocation: toLocation)
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
        case let .updateDateAndTime(range, dateAndTime):
            return UpdateDateAndTimeCommandComposer(range: range, dateAndTime: dateAndTime)
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
    private let editorService: EditorService
    public var isReadyToEdit: Bool = false {
        didSet {
            if isReadyToEdit {
                self.delegate?.didReadyToEdit()
            }
        }
    }
    
    public init(editorService: EditorService) {
        self.editorService = editorService
        self.addStatesObservers()
        editorService.open {
            self.isReadyToEdit = $0 != nil
        }
    }
    
    deinit {
        self.removeObservers()
    }
    
    public var url: URL {
        return self.editorService.fileURL
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
    
    public func cursorLocationChanged(_ newLocation: Int) {
        self.delegate?.didEnterTokens(self.editorService.tokens(at: newLocation))
    }
    
    public func save(completion: @escaping () -> Void) {
        editorService.save { _  in
            completion()
        }
    }
    
    public func headingString(index: Int) -> String {
        let heading = self.headings[index]
        let length = [heading.tags, heading.priority]
            .map { $0?.location ?? Int.max }
            .reduce(heading.range.upperBound, min) - heading.range.location - heading.level + 1
        
        let location = [heading.range.location + heading.level, heading.planning?.upperBound]
            .map { $0 ?? -Int.max }
            .reduce(heading.range.location, max)
        
        return self.editorService.trim(string: self.editorService.string, range: NSRange(location: location, length: length))
    }
    
    public func foldOrUnfold(location: Int) {
        _ = self.editorService.toggleContentCommandComposer(composer: FoldCommandComposer(location: location)).perform()
    }
    
    public func performAction(_ action: EditAction, undoManager: UndoManager, completion: ((DocumentContentCommandResult) -> Void)?) {
        let command = self.editorService.toggleContentCommandComposer(composer: action.commandComposer)
        
        self.performContentCommand(command, undoManager: undoManager, completion: completion)
    }
    
    private func performContentCommand(_ command: DocumentContentCommand, undoManager: UndoManager, completion: ((DocumentContentCommandResult) -> Void)?) {
        let result = command.perform()
        
        undoManager.registerUndo(withTarget: self, handler: { target in
            let command = target.editorService.toggleContentCommandComposer(composer: ReplaceContentCommandComposer(range: result.range!, textToReplace: result.content!))
            target.performContentCommand(command, undoManager: undoManager, completion: completion)
        })
        
        if result.isModifiedContent {
            self.editorService.save()
        } else {
            self.editorService.markAsContentUpdated()
        }
        
        completion?(result)
    }
    
    public func level(index: Int) -> Int {
        return self.headings[index].level
    }
    
    public func rename(newTitle: String, completion: ((Error?) -> Void)? = nil) {
        self.editorService.rename(newTitle: newTitle, completion: completion)
    }
    
    public func delete(completion: ((Error?) -> Void)? = nil) {
        self.editorService.delete(completion: completion)
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
