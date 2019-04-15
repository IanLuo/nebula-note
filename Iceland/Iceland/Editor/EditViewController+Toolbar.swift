//
//  EditViewController+Toolbar.swift
//  Iceland
//
//  Created by ian luo on 2019/3/20.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

extension DocumentEditViewController: DocumentEditToolbarDelegate {
    private func commandCompletionActionMoveCursorMapTheLengthOfStringChange(result: DocumentContentCommandResult) {
        self.textView.selectedRange = self.textView.selectedRange.offset(result.delta)
    }
    
    private func commandCompletionActionMoveCursorForTextMark(result: DocumentContentCommandResult) {
        if result.delta > 0 {
            self.textView.selectedRange = self.textView.selectedRange.offset(1)
        } else {
            self.textView.selectedRange = self.textView.selectedRange.offset(-1)
        }
    }
    
    private func commandCompletionActionMoveCursorForBlock(result: DocumentContentCommandResult) {
        let middle = (self.textView.text as NSString).lineRange(for: NSRange(location: result.range!.upperBound - 1, length: 0)).location - 1
        self.textView.selectedRange = NSRange(location: middle, length: 0)
        
    }
    
    private func commandCompletionActionMoveCursorSelectChangeRange(result: DocumentContentCommandResult) {
        self.textView.selectedRange = result.range!
    }
    
    public func didTriggerAction(_ action: ToolbarActionProtocol) {
        if let textViewAction = action as? TextViewAction {
            textViewAction.toggle(textView: self.textView, location: self.textView.selectedRange.location)
        } else if let documentAction = action as? DocumentActon {
            // attachment
            if let attachmentAction = documentAction as? AttachmentAction {
                self.viewModel.coordinator?.showAttachmentPicker(kind: attachmentAction.AttachmentKind, complete: { [unowned self] attachmentId in
                    self.viewModel.performAction(EditAction.addAttachment(self.textView.selectedRange.location,
                                                                          attachmentId, attachmentAction.AttachmentKind.rawValue),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: { [unowned self] result in
                                                    self.textView.selectedRange = self.textView.selectedRange.offset(result.delta)
                    })
                }, cancel: {})
            }
            
            // other document actions
            else if let normalAction = documentAction as? NormalAction {
                switch normalAction {
                case .heading:
                    break // TODO:
                case .increaseIndent:
                    self.viewModel.performAction(EditAction.increaseIndent(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorMapTheLengthOfStringChange)
                case .decreaseIndent:
                    self.viewModel.performAction(EditAction.decreaseIndent(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorMapTheLengthOfStringChange)
                case .undo:
                    UndoCommand().toggle(textView: self.textView)
                case .redo:
                    RedoCommand().toggle(textView: self.textView)
                case .bold:
                    self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.bold, self.textView.selectedRange),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForTextMark)
                case .italic:
                    self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.italic, self.textView.selectedRange),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForTextMark)
                case .underscore:
                    self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.underscore, self.textView.selectedRange),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForTextMark)
                case .strikethrough:
                    self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.strikethrough, self.textView.selectedRange),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForTextMark)
                case .code:
                    self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.code, self.textView.selectedRange),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForTextMark)
                case .verbatim:
                    self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.verbatim, self.textView.selectedRange),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForTextMark)
                case .checkbox:
                    self.viewModel.performAction(.checkboxSwitch(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorMapTheLengthOfStringChange)
                case .list:
                    self.viewModel.performAction(.unorderedListSwitch(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorMapTheLengthOfStringChange)
                case .orderedList:
                    self.viewModel.performAction(.orderedListSwitch(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorMapTheLengthOfStringChange)
                case .sourcecode:
                    self.viewModel.performAction(.codeBlock(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForBlock)
                case .quote:
                    self.viewModel.performAction(.quoteBlock(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!,
                                                 completion: commandCompletionActionMoveCursorForBlock)
                    
                case .moveUp:
                    self.viewModel.performAction(.moveLineUp(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!) { (result) in
                                                    // TODO:
                    }
                case .moveDown:
                    self.viewModel.performAction(.moveLineDown(self.textView.selectedRange.location),
                                                 undoManager: self.textView.undoManager!) { (result) in
                                                    // TODO:
                    }
                case .dateAndTime:
                    self.showDateAndTimeCreator(location: self.textView.selectedRange.location)
                case .planning:
                    self.showPlanningSelector(location: self.textView.selectedRange.location, current: nil)
                case .tag:
                    self.showTagEditor(location: self.textView.selectedRange.location)
                }
            }
        }
    }
}
