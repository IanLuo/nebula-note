//
//  DocumentEditViewController+Input.swift
//  Iceland
//
//  Created by ian luo on 2019/5/10.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

extension DocumentEditorViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.viewModel.didUpdate()
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        let location = textView.selectedRange.location
        
        self.viewModel.cursorLocationChanged(location)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard self.textView.isEditable else { return }
        
        let location = textView.selectedRange.location
        
        self.viewModel.cursorLocationChanged(location)
        
        let lastLocation = self._lastLocation
        self._lastLocation = location
        
        if location < textView.text.nsstring.length {
            if let lastLocation = lastLocation,
                let hiddenRange = self.viewModel.hiddenRange(at: location),
                hiddenRange.upperBound != location,
                textView.selectedRange.length == 0,
                location != lastLocation {
                log.info("hidden range: \(hiddenRange), hidden string: \(self.textView.text.nsstring.substring(with: hiddenRange))")
                if location < lastLocation { // move back
                    self._isAdjustingSelectRange = true
                    textView.selectedRange = NSRange(location: max(0, hiddenRange.location - 1), length: 0)
                    self._isAdjustingSelectRange = false
                } else if location > lastLocation { // move forward
                    self._isAdjustingSelectRange = true
                    textView.selectedRange = NSRange(location: hiddenRange.upperBound, length: 0)
                    self._isAdjustingSelectRange = false
                }
                log.info("adjust to \(textView.selectedRange)")
            }
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // ignore when cursor in hidden range
        if let hiddenRange = self.viewModel.hiddenRange(at: range.location) {
            if hiddenRange.location <= range.location && hiddenRange.upperBound >= range.upperBound {
                return false
            }
        }
        
        // handle inupt at end of folded paragraph
        if textView.text.count > 0 {
            let lastPosition = range.location - 1
            if let heading = self.viewModel.heading(at: lastPosition) {
                var paragraphContentRange: NSRange = heading.subheadingsRange
                if paragraphContentRange.upperBound != textView.text.nsstring.length {
                    paragraphContentRange = paragraphContentRange.moveRightBound(by: -1)
                }

                if paragraphContentRange.upperBound == range.location && viewModel.isSectionFolded(at: lastPosition) {
                    self.viewModel.unfoldExceptTo(location: lastPosition)
                    return false
                }
            }
        }
        
        if text == "\n" { // 换行
            return self._handleLineBreak(textView)
        } else if text == "" { // 删除
            return self._handelBackspace(textView)
        } else if text == "\t" { // tab
            return self._handleTab(textView)
        }
        
        return true
    }
}

extension DocumentEditorViewController {
    private func _handleLineBreak(_ textView: UITextView) -> Bool {
        // 如果在 heading 中，换行不在当前位置，而在 heading 之后
        guard let currentPosition = textView.selectedTextRange?.start else { return true }
        
        // 如果当前位置在 heading 内部(除开最前端)，回车的时候，先查找 tag 的位置，将 tag 之前，光标之后的内容，添加到行位
        for case let heading in self.viewModel.currentTokens where heading is HeadingToken {
            let heading = heading as! HeadingToken
            
            guard self.textView.selectedRange.location != heading.range.location else { return true }
            
            if let tagRange = heading.tags, tagRange.upperBound > self.textView.selectedRange.location  {
                let breakRange = NSRange(location: textView.selectedRange.location, length: tagRange.location - textView.selectedRange.location)
                let textToPutInNextLine = "\n" + textView.text.nsstring.substring(with: breakRange)
                _ = self.viewModel.performAction(EditAction.replaceText(NSRange(location: heading.range.upperBound, length: 0), textToPutInNextLine), textView: textView)
                _ = self.viewModel.performAction(EditAction.replaceText(breakRange, ""), textView: textView)
                textView.selectedRange = NSRange(location: heading.range.upperBound + 1, length: 0) // +1 是因为添加了一个换行符
                return false
            } else {
                return true
            }
        }
        
        // 有序列表，自动添加列表前缀，如果真有前缀没有内容，则删除前缀
        for case let token in self.viewModel.currentTokens where token is OrderedListToken {
            if token.range.length == (token as! OrderedListToken).prefix.length {
                let oldSelectedRange = textView.selectedRange
                let result = self.viewModel.performAction(EditAction.replaceText((token as! OrderedListToken).prefix, ""), textView: self.textView)
                textView.selectedRange = oldSelectedRange.offset(result.delta)
            } else {
                textView.replace(textView.textRange(from: currentPosition, to: currentPosition)!, withText: "\n")
                let result = self.viewModel.performAction(EditAction.orderedListSwitch(textView.selectedRange.location), textView: self.textView)
                textView.selectedRange = NSRange(location: result.range!.upperBound, length: 0)
            }
            return false
        }
        
        // 无序列表，自动添加列表前缀，如果真有前缀没有内容，则删除前缀
        for case let token in self.viewModel.currentTokens where token is UnorderdListToken {
            if token.range.length == (token as! UnorderdListToken).prefix.length {
                let oldSelectedRange = textView.selectedRange
                let result = self.viewModel.performAction(EditAction.replaceText((token as! UnorderdListToken).prefix, ""), textView: self.textView)
                textView.selectedRange = oldSelectedRange.offset(result.delta)
            } else {
                textView.replace(textView.textRange(from: currentPosition, to: currentPosition)!, withText: "\n")
                let result = self.viewModel.performAction(EditAction.unorderedListSwitch(textView.selectedRange.location), textView: self.textView)
                textView.selectedRange = NSRange(location: result.range!.upperBound, length: 0)
            }
            return false
        }
        
        // checkbox, 自动添加 checkbox 前缀，如果真有前缀没有内容，则删除前缀
        for case let token in self.viewModel.currentTokens where token is CheckboxToken {
            if token.range.length == (token as! CheckboxToken).status.length {
                let oldSelectedRange = textView.selectedRange
                let result = self.viewModel.performAction(EditAction.replaceText((token as! CheckboxToken).status, ""), textView: self.textView)
                textView.selectedRange = oldSelectedRange.offset(result.delta)
            } else {
                textView.replace(textView.textRange(from: currentPosition, to: currentPosition)!, withText: "\n")
                let result = self.viewModel.performAction(EditAction.checkboxSwitch(textView.selectedRange.location), textView: self.textView)
                textView.selectedRange = NSRange(location: result.range!.upperBound, length: 0)
            }
            return false
        }
        
        return true
    }
    
    /// 输入退格键，自动选中某些 tokne 范围
    private func _handelBackspace(_ textView: UITextView) -> Bool {
        // 只有在没有选中多个字符时有效
        if textView.selectedRange.length == 0 {
            let locationToDelete = max(0, self.textView.selectedRange.location - 1)
            if let foldedRange = self.viewModel.foldedRange(at: locationToDelete) {
                textView.selectedRange = NSRange(location: foldedRange.location - 1, length: 0)
                return false
            }
            
            for case let attachmentToken in self.viewModel.currentTokens where attachmentToken is AttachmentToken {
                guard self.textView.selectedRange.location != attachmentToken.range.location else { return true }
                
                textView.selectedRange = attachmentToken.range
                return false
            }
            
            for case let linkToken in self.viewModel.currentTokens where linkToken is LinkToken {
                guard self.textView.selectedRange.location != linkToken.range.location else { return true }
                
                textView.selectedRange = linkToken.range
                return false
            }
            
            for case let dateAndTimeToken in self.viewModel.currentTokens where dateAndTimeToken is DateAndTimeToken {
                guard self.textView.selectedRange.location != dateAndTimeToken.range.location else { return true }
                
                textView.selectedRange = dateAndTimeToken.range
                return false
            }
            
            for case let textMark in self.viewModel.currentTokens where textMark is TextMarkToken {
                guard self.textView.selectedRange.location != textMark.range.location else { return true }
                
                if textMark.range.length == 2 /* 没有内容 */ {
                    let oldSelectedRange = textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.replaceText(textMark.range, ""), textView: textView)
                    textView.selectedRange = oldSelectedRange.offset(result.range!.location - oldSelectedRange.location)
                    return false
                }
            }
            
            for case let blockMark in self.viewModel.currentTokens where blockMark is BlockToken {
                guard self.textView.selectedRange.location != blockMark.range.location else { return true }

                var anotherEndToken: BlockToken?
                if let beginToken = blockMark as? BlockBeginToken {
                    anotherEndToken = beginToken.endToken
                } else if let endToken = blockMark as? BlockEndToken {
                    anotherEndToken = endToken.beginToken
                }
                
                if blockMark.tokenRange.contains(locationToDelete) || blockMark.tokenRange.lastCharacterLocation == locationToDelete {
                    textView.selectedRange = blockMark.range
                    return false
                } else if let anotherEndToken = anotherEndToken, anotherEndToken.tokenRange.contains(locationToDelete) || anotherEndToken.tokenRange.lastCharacterLocation == locationToDelete {
                    textView.selectedRange = anotherEndToken.range
                    return false
                }
            }
            
            for case let token in self.viewModel.currentTokens where token is HeadingToken {
                let headingToken = token as! HeadingToken
                let location = textView.selectedRange.location
                
                if let tagsRange = headingToken.tags {
                    guard self.textView.selectedRange.location != tagsRange.location else { return true }
                    
                    if tagsRange.contains(location) || tagsRange.upperBound == location {
                        textView.selectedRange = tagsRange
                        return false
                    }
                }
                
                if let planningRange = headingToken.planning {
                    guard self.textView.selectedRange.location != planningRange.location else { return true }
                    
                    if planningRange.contains(location) || planningRange.upperBound == location {
                        textView.selectedRange = planningRange
                        return false
                    }
                }
                
                if let priorityRange = headingToken.priority {
                    guard self.textView.selectedRange.location != priorityRange.location else { return true }
                    
                    if priorityRange.contains(location) || priorityRange.upperBound == location {
                        textView.selectedRange = priorityRange
                        return false
                    }
                }
                
                // when backspace at in the prefix range, or the space after the prefix in heading, will select the whole prifix
                if headingToken.prefix.contains(location) || headingToken.prefix.upperBound == location || headingToken.prefix.upperBound + 1 == location {
                    
                    // if user backspace at begining of a heading, just move the cursor back, dont' delete the '\n', otherwise will break the heading
                    if self.textView.selectedRange.location == headingToken.prefix.location {
                        if locationToDelete - 1 > 0 {
                            self.textView.selectedRange = NSRange(location: locationToDelete, length: 0)
                        } else {
                            return true
                        }
                        return false
                    }
                    
                    textView.selectedRange = headingToken.prefix
                    return false
                }
            }
            
            if let hiddenRange = self.viewModel.hiddenRange(at: locationToDelete) {
                guard self.textView.selectedRange.location != hiddenRange.location else { return true }
                
                textView.selectedRange = hiddenRange
                return false
            }
        }
        
        return true
    }
    
    private func _handleTab(_ textView: UITextView) -> Bool {
        if let heading = self.viewModel.heading(at: self.textView.selectedRange.location), self.textView.selectedRange.location == heading.range.location {
            self.viewModel.foldOrUnfold(location: heading.range.location)
            return false
        }
        
        for case let heading in self.viewModel.currentTokens where heading is HeadingToken {
            var newLevel = (heading as! HeadingToken).level + 1
            if newLevel >= SettingsAccessor.shared.maxLevel { newLevel = 1 }
            let oldSelectedRange = textView.selectedRange
            let result = self.viewModel.performAction(EditAction.updateHeadingLevel(textView.selectedRange.location, newLevel), textView: self.textView)
            textView.selectedRange = oldSelectedRange.offset(result.delta)
            return false
        }
        
        return true
    }
    
    @available(iOS 13.0, *)
    func enableKeyBindings() {
        guard isMacOrPad else { return }
        
        let binding = KeyBinding()
        
        binding.addAction(for: KeyAction.pickAttachmentMenu, on: self) {
            self.didTriggerAction(NormalAction.allAttachments, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.addAttachmentMenu, on: self) {
            self.didTriggerAction(NormalAction.newAttachment, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.paragraphMenu, on: self) {
            self.didTriggerAction(NormalAction.paragraph, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.headingMenu, on: self) {
            self.didTriggerAction(NormalAction.heading, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.statusMenu, on: self) {
            self.didTriggerAction(NormalAction.planning, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.tagMenu, on: self) {
            self.didTriggerAction(NormalAction.tag, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.priorityMenu, on: self) {
            self.didTriggerAction(NormalAction.priority, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.dateTimeMenu, on: self) {
            self.didTriggerAction(NormalAction.dateAndTime, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.fileLink, on: self) {
            self.didTriggerAction(NormalAction.fileLink, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.pickIdeaMenu, on: self) {
            self.didTriggerAction(NormalAction.captured, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.foldAll, on: self) {
            self.viewModel.foldAll()
        }
        
        binding.addAction(for: KeyAction.unfoldAll, on: self) {
            self.viewModel.unfoldAll()
        }
        
        binding.addAction(for: KeyAction.outline, on: self) {
            self.showOutline(from: self.view)
        }
        
        binding.addAction(for: KeyAction.inspector, on: self) {
            self.showInfo()
        }
        
        binding.addAction(for: KeyAction.bold, on: self) {
            self.didTriggerAction(NormalAction.bold, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.italic, on: self) {
            self.didTriggerAction(NormalAction.italic, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.underscore, on: self) {
            self.didTriggerAction(NormalAction.underscore, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.strikeThrough, on: self) {
            self.didTriggerAction(NormalAction.strikethrough, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.highlight, on: self) {
            self.didTriggerAction(NormalAction.highlight, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.moveUp, on: self) {
            self.didTriggerAction(NormalAction.moveUp, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.moveDown, on: self) {
            self.didTriggerAction(NormalAction.moveDown, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.seperator, on: self) {
            self.didTriggerAction(NormalAction.seperator, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.codeBlock, on: self) {
            self.didTriggerAction(NormalAction.sourcecode, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.quoteBlock, on: self) {
            self.didTriggerAction(NormalAction.quote, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.checkbox, on: self) {
            self.didTriggerAction(NormalAction.checkbox, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.list, on: self) {
            self.didTriggerAction(NormalAction.list, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.orderedList, on: self) {
            self.didTriggerAction(NormalAction.orderedList, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.moveRight, on: self) {
            self.didTriggerAction(NormalAction.increaseIndent, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.moveLeft, on: self) {
            self.didTriggerAction(NormalAction.decreaseIndent, from: self.textView)
        }
        
        binding.addAction(for: KeyAction.save, on: self) {
            self.viewModel.save {}
        }
        
        self.viewModel.context.coordinator?.enableGlobalNavigateKeyCommands()
    }
}

