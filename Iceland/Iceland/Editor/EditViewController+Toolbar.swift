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
    public func didTriggerAction(_ action: ToolbarActionProtocol) {
        if let textViewAction = action as? TextViewAction {
            textViewAction.toggle(textView: self.textView, location: self.textView.selectedRange.location)
        } else if let documentAction = action as? DocumentActon {
            // attachment
            if let attachmentAction = documentAction as? AttachmentAction {
                self.viewModel.coordinator?.showAttachmentPicker(kind: attachmentAction.AttachmentKind, complete: { [unowned self] attachmentId in
                    self.viewModel.performAction(EditAction.addAttachment(self.textView.selectedRange.location,
                                                                          attachmentId, attachmentAction.AttachmentKind.rawValue), undoManager:
                        self.textView.undoManager!)
                }, cancel: {
                    
                })
            }
            
            // other document actions
            else if let normalAction = documentAction as? NormalAction {
                switch normalAction {
                case .heading:
                    break // TODO:
                case .increaseIndent:
                    if self.viewModel.performAction(EditAction.increaseIndent(self.textView.selectedRange.location), undoManager: self.textView.undoManager!).isModifiedContent {
                        MoveCursorCommand(locaton: self.textView.selectedRange.location,
                                          direction: MoveCursorCommand.Direction.right)
                            .toggle(textView: self.textView)
                    }
                case .decreaseIndent:
                    if self.viewModel.performAction(EditAction.decreaseIndent(self.textView.selectedRange.location), undoManager: self.textView.undoManager!).isModifiedContent {
                        MoveCursorCommand(locaton: self.textView.selectedRange.location,
                                          direction: MoveCursorCommand.Direction.left)
                            .toggle(textView: self.textView)
                    }
                case .undo:
                    UndoCommand().toggle(textView: self.textView)
                case .redo:
                    RedoCommand().toggle(textView: self.textView)
                case .bold:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.bold, self.textView.selectedRange), undoManager: self.textView.undoManager!)
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .italic:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.italic, self.textView.selectedRange), undoManager: self.textView.undoManager!)
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .underscore:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.underscore, self.textView.selectedRange), undoManager: self.textView.undoManager!)
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .strikethrough:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.strikethrough, self.textView.selectedRange), undoManager: self.textView.undoManager!)
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .code:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.code, self.textView.selectedRange), undoManager: self.textView.undoManager!)
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .verbatim:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.verbatim, self.textView.selectedRange), undoManager: self.textView.undoManager!)
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .checkbox:
                    let result = self.viewModel.performAction(.checkboxSwitch(self.textView.selectedRange.location), undoManager: self.textView.undoManager!)
                    if result.delta != 0 {
                        self.textView.selectedRange = self.textView.selectedRange.offset(result.delta)
                    }
                case .list:
                    let result = self.viewModel.performAction(.unorderedListSwitch(self.textView.selectedRange.location), undoManager: self.textView.undoManager!)
                    if result.delta != 0 {
                        self.textView.selectedRange = self.textView.selectedRange.offset(result.delta)
                    }
                case .orderedList:
                    let result = self.viewModel.performAction(.orderedListSwitch(self.textView.selectedRange.location), undoManager: self.textView.undoManager!)
                    if result.delta != 0 {
                        self.textView.selectedRange = self.textView.selectedRange.offset(result.delta)
                    }
                case .sourcecode:
                    self.viewModel.performAction(.codeBlock(self.textView.selectedRange.location), undoManager: self.textView.undoManager!)
                case .quote:
                    self.viewModel.performAction(.quoteBlock(self.textView.selectedRange.location), undoManager: self.textView.undoManager!)
                }
            }
        }
    }
    
    private func _moveSursorIfNeeded(selectedRange: NSRange) {
        if selectedRange.length == 0 {
            MoveCursorCommand(locaton: self.textView.selectedRange.location,
                              direction: MoveCursorCommand.Direction.right)
                .toggle(textView: self.textView)
        } else {
            self.textView.selectedRange = self.textView.selectedRange.offset(1)
        }
    }
}
