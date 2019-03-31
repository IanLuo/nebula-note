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
                    self.viewModel.performAction(EditAction.addAttachment(self.textView.selectedRange.location, attachmentId, attachmentAction.AttachmentKind.rawValue))
                }, cancel: {
                    
                })
            }
            
            // other document actions
            else if let normalAction = documentAction as? NormalAction {
                switch normalAction {
                case .heading:
                    break // TODO:
                case .increaseIndent:
                    if self.viewModel.performAction(EditAction.increaseIndent(self.textView.selectedRange.location)) {
                        MoveCursorCommand(locaton: self.textView.selectedRange.location,
                                          direction: MoveCursorCommand.Direction.right)
                            .toggle(textView: self.textView)
                    }
                case .decreaseIndent:
                    if self.viewModel.performAction(EditAction.decreaseIndent(self.textView.selectedRange.location)) {
                        MoveCursorCommand(locaton: self.textView.selectedRange.location,
                                          direction: MoveCursorCommand.Direction.left)
                            .toggle(textView: self.textView)
                    }
                case .moveUp:
                    break // TOOD:
                case .moveDown:
                    break // TODO:
                case .undo:
                    UndoCommand().toggle(textView: self.textView)
                case .redo:
                    RedoCommand().toggle(textView: self.textView)
                case .bold:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.bold, self.textView.selectedRange))
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .italic:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.italic, self.textView.selectedRange))
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .underscore:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.underscore, self.textView.selectedRange))
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .strikethrough:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.strikethrough, self.textView.selectedRange))
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .code:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.code, self.textView.selectedRange))
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .verbatim:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.verbatim, self.textView.selectedRange))
                    
                    self._moveSursorIfNeeded(selectedRange: self.textView.selectedRange)
                case .checkbox:
                    break // TODO:
                case .list:
                    break // TODO:
                case .orderedList:
                    break // TODO:
                case .sourcecode:
                    break // TODO:
                case .quote:
                    break // TODO:
                }
            }
        }
    }
    
    private func _moveSursorIfNeeded(selectedRange: NSRange) {
        if selectedRange.length == 0 {
            MoveCursorCommand(locaton: self.textView.selectedRange.location,
                              direction: MoveCursorCommand.Direction.right)
                .toggle(textView: self.textView)
        }
    }
}
