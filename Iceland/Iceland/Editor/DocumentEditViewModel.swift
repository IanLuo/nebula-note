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
}

public enum EditAction {
    case toggleFoldStatus(Int)
    case toggleCheckboxStatus(NSRange)
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
    case addMark(OutlineParser.MarkType, NSRange)
    case increaseIndent(Int)
    case decreaseIndent(Int)
    case quoteBlock(Int)
    case codeBlock(Int)
    case foldAll
    case unfoldAll
    case unorderedListSwitch(Int)
    case orderedListSwitch(Int)
    case checkboxSwitch(Int)
    
    public var command: DocumentContentCommand {
        switch self {
        case .toggleFoldStatus(let location):
            return FoldingAndUnfoldingCommand(location: location)
        case .toggleCheckboxStatus(let range):
            return CheckboxStatusCommand(range: range)
        case let .addAttachment(location, attachmentId, kind):
            return AddAttachmentCommand(attachmentId: attachmentId, location: location, kind: kind)
        case let .addTag(tag, location):
            return TagCommand(location: location, kind: .add(tag))
        case let .removeTag(tag, location):
            return TagCommand(location: location, kind: .remove(tag))
        case let .changePlanning(planning, location):
            return PlanningCommand(location: location, kind: .addOrUpdate(planning))
        case let .removePlanning(location):
            return PlanningCommand(location: location, kind: .remove)
        case let .insertText(text, location):
            return InsertTextToHeadingCommand(location: location, textToInsert: text)
        case let .replaceHeading(fromLocation, toLocation):
            return ReplaceHeadingCommand(fromLocation: fromLocation, toLocation: toLocation)
        case let .archive(location):
            return ArchiveCommand(location: location)
        case let .unarchive(location):
            return UnarchiveCommand(location: location)
        case .insertSeparator(let location):
            return IncreaseIndentCommand(location: location)
        case .addMark(let markType, let range):
            return AddMarkCommand(markType: markType, range: range)
        case .increaseIndent(let location):
            return IncreaseIndentCommand(location: location)
        case .decreaseIndent(let location):
            return DecreaseIndentCommand(location: location)
        case .quoteBlock(let location):
            return QuoteBlockCommand(location: location)
        case .codeBlock(let location):
            return CodeBlockCommand(location: location)
        case .foldAll:
            return FoldAllCommand()
        case .unfoldAll:
            return UnFoldAllCommand()
        case let .updateDateAndTime(range, dateAndTime):
            return UpdateDateAndTimeCommand(range: range, dateAndTime: dateAndTime)
        case let .unorderedListSwitch(location):
            return UnorderdListSwitchCommand(location: location)
        case let .orderedListSwitch(location):
            return OrderedListSwitchCommand(location: location)
        case let .checkboxSwitch(location):
            return CheckboxSwitchCommand(location: location)
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
    
    @discardableResult
    public func performAction(_ action: EditAction, undoManager: UndoManager) -> DocumentContentCommandResult {
        let result = self.editorService.toggleContentAction(command: action.command)
        
        undoManager.registerUndo(withTarget: self.editorService) { service in
            _ = service.toggleContentAction(command: ReplaceTextCommand(range: result.range!, textToReplace: result.content!))
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
