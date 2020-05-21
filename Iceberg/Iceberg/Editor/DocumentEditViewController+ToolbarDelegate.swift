//
//  EditViewController+Toolbar.swift
//  Iceland
//
//  Created by ian luo on 2019/3/20.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core

extension DocumentEditorViewController: DocumentEditToolbarDelegate {
    private func commandCompletionActionMoveCursorMapTheLengthOfStringChange(_ oldSelectedRange: NSRange) -> (DocumentContentCommandResult) -> Void {
        return { result in
            self.textView.selectedRange = oldSelectedRange.offset(result.delta)
        }
    }
    
    private func commandCompletionActionMoveCursorForTextMark(_ oldSelectedRange: NSRange) -> (DocumentContentCommandResult) -> Void {
        return { result in
            if result.delta > 0 {
                self.textView.selectedRange = oldSelectedRange.offset(1)
            } else {
                self.textView.selectedRange = oldSelectedRange.offset(-1)
            }
        }
    }
    
    private func commandCompletionActionMoveCursorForBlock(result: DocumentContentCommandResult) {
        let middle = (self.textView.text as NSString).lineRange(for: NSRange(location: result.range!.upperBound - 1, length: 0)).location - 1
        self.textView.selectedRange = NSRange(location: middle, length: 0)
    }
    
    private func commandCompletionActionMoveCursorSelectChangeRange(result: DocumentContentCommandResult) {
        self.textView.selectedRange = result.range!
    }
    
    public func isMember() -> Bool {
        return self.viewModel.isMember
    }
    
    public func didTriggerAction(_ action: ToolbarActionProtocol, from: UIView) {
        
        if (action.isMemberFunction && !self.viewModel.isMember) {
            self.viewModel.context.coordinator?.showMembership()
            return
        }
        
        let currentLocation = self.textView.selectedRange.location
        
        if let textViewAction = action as? TextViewAction {
            textViewAction.toggle(textView: self.textView, location: self.textView.selectedRange.location)
        } else if let documentAction = action as? DocumentActon {
            // attachment
            if let attachmentAction = documentAction as? AttachmentAction {
                self.viewModel.dependency.globalCaptureEntryWindow?.hide()
                self.viewModel.context.coordinator?.showAttachmentPicker(kind: attachmentAction.AttachmentKind, complete: { [unowned self] attachmentId in
                    let oldSelection = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.addAttachment(currentLocation,
                                                                          attachmentId, attachmentAction.AttachmentKind.rawValue),
                                                 textView: self.textView)
                    DispatchQueue.runOnMainQueueSafely {
                        self.textView.selectedRange = oldSelection.offset(result.delta)
                        self.viewModel.dependency.globalCaptureEntryWindow?.show()
                    }
                    
                    // this is special for link, because link here do not need to save attachment file, so delete the attachment
                    if attachmentAction.AttachmentKind == .link {
                        self.viewModel.dependency.attachmentManager.delete(key: attachmentId, completion: {}, failure: { _ in })
                    }
                }, cancel: { [weak self] in
                    self?.viewModel.dependency.globalCaptureEntryWindow?.show()
                })
            }
            
            // other document actions
            else if let normalAction = documentAction as? NormalAction {
                let lineRange = (self.textView.text as NSString).lineRange(for: NSRange(location: self.textView.selectedRange.location, length: 0))
                switch normalAction {
                case .heading:
                    if self.inputbar.mode == .heading {
                        self.showHeadingEdit(at: lineRange.location)
                    } else {
                        let lineContent = self.textView.text.nsstring.substring(with: lineRange).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        if lineContent.count == 0 {
                            //  空行，直接转为标题
                            let lastSelectedRange = self.textView.selectedRange
                            let result = self.viewModel.performAction(EditAction.convertToHeading(lineRange.location), textView: self.textView)
                            self.textView.selectedRange = lastSelectedRange.offset(result.delta)
                        } else {
                            // 含有文字，显示菜单
                            self.showHeadingAdd(at: lineRange.location)
                        }
                    }
                    
                case .increaseIndent:
                    let outSelection = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.increaseIndent(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorMapTheLengthOfStringChange(outSelection)(result)
                case .decreaseIndent:
                    let outSelection = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.decreaseIndent(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorMapTheLengthOfStringChange(outSelection)(result)
                case .undo:
                    UndoCommand().toggle(textView: self.textView)
                case .redo:
                    RedoCommand().toggle(textView: self.textView)
                case .bold:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.bold, self.textView.selectedRange),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForTextMark(oldSelectedRange)(result)
                case .italic:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.italic, self.textView.selectedRange),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForTextMark(oldSelectedRange)(result)
                case .underscore:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.underscore, self.textView.selectedRange),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForTextMark(oldSelectedRange)(result)
                case .strikethrough:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.strikethrough, self.textView.selectedRange),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForTextMark(oldSelectedRange)(result)
                case .highlight:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.highlight, self.textView.selectedRange),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForTextMark(oldSelectedRange)(result)
                case .verbatim:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.textMark(OutlineParser.MarkType.verbatim, self.textView.selectedRange),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForTextMark(oldSelectedRange)(result)
                case .checkbox:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(.checkboxSwitch(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorMapTheLengthOfStringChange(oldSelectedRange)(result)
                case .list:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(.unorderedListSwitch(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorMapTheLengthOfStringChange(oldSelectedRange)(result)
                case .orderedList:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(.orderedListSwitch(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorMapTheLengthOfStringChange(oldSelectedRange)(result)
                case .sourcecode:
                    let result = self.viewModel.performAction(.codeBlock(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForBlock(result: result)
                case .quote:
                    let result = self.viewModel.performAction(.quoteBlock(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    commandCompletionActionMoveCursorForBlock(result: result)
                case .moveUp:
                    let oldSelectedRange = textView.selectedRange
                    let result = self.viewModel.performAction(.moveLineUp(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                case .moveDown:
                    let oldSelectedRange = textView.selectedRange
                    let result = self.viewModel.performAction(.moveLineDown(self.textView.selectedRange.location),
                                                 textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                case .dateAndTime:
                    self.showDateAndTimeCreator(location: self.textView.selectedRange.location)
                case .planning:
                    self.showPlanningSelector(location: self.textView.selectedRange.location, current: self.viewModel.planning(at: self.textView.selectedRange.location))
                case .tag:
                    self.showTagEditor(location: self.textView.selectedRange.location)
                case .priority:
                    self.showPriorityEditor(location: self.textView.selectedRange.location, current: self.viewModel.priority(at: self.textView.selectedRange.location))
                case .captured:
                    self.showCapturedItemList(location: self.textView.selectedRange.location)
                case .allAttachments:
                    self.showAllAttachmentPicker(location: self.textView.selectedRange.location)
                case .paragraph:
                    self.showParagraphActions(at: self.textView.selectedRange.location)
                case .seperator:
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.insertSeparator(self.textView.selectedRange.location), textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                case .newAttachment:
                    self.pickAttachment(location: currentLocation)
                }
            }
        }
    }
}
