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

extension DocumentEditorViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.viewModel.didUpdate()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        let location = textView.selectedRange.location
        
        self.viewModel.cursorLocationChanged(location)
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
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
        
        return true
    }
    
    /// 输入退格键，自动选中某些 tokne 范围
    private func _handelBackspace(_ textView: UITextView) -> Bool {
        // 只有在没有选中多个字符时有效
        if textView.selectedRange.length == 0 {
            let locationToDelete = self.textView.selectedRange.location - 1
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
                
                if blockMark.tokenRange.contains(locationToDelete) || blockMark.tokenRange.lastCharacterLocation == locationToDelete {
                    textView.selectedRange = blockMark.range
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
            }
        }
        
        return true
    }
    
    private func _handleTab(_ textView: UITextView) -> Bool {
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
}

