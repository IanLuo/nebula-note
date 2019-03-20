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
                case .increaseIndent:
                    if self.viewModel.performAction(EditAction.increaseIndent(self.textView.selectedRange.location)) {
                        self.textView.selectedRange = self.textView.selectedRange.offset(1)
                    }
                case .decreaseIndent:
                    if self.viewModel.performAction(EditAction.decreaseIndent(self.textView.selectedRange.location)) {
                        self.textView.selectedRange = self.textView.selectedRange.offset(-1)
                    }
                case .undo:
                    UndoCommand().toggle(textView: self.textView)
                case .redo:
                    RedoCommand().toggle(textView: self.textView)
                case .bold:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.bold, self.textView.selectedRange))
                case .italic:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.italic, self.textView.selectedRange))
                case .underscore:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.underscore, self.textView.selectedRange))
                case .strikethrough:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.strikethrough, self.textView.selectedRange))
                case .code:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.code, self.textView.selectedRange))
                case .verbatim:
                    self.viewModel.performAction(EditAction.addMark(OutlineParser.MarkType.verbatim, self.textView.selectedRange))
                }
            }
        }
    }
}
