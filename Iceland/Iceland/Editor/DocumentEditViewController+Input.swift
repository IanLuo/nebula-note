//
//  DocumentEditViewController+Input.swift
//  Iceland
//
//  Created by ian luo on 2019/5/10.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

extension DocumentEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.viewModel.didUpdate()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        self.viewModel.cursorLocationChanged(textView.selectedRange.location)
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

extension DocumentEditViewController {
    private func _handleLineBreak(_ textView: UITextView) -> Bool {
        // 如果在 heading 中，换行不在当前位置，而在 heading 之后
        guard let currentPosition = textView.selectedTextRange?.start else { return true }
        
        for case let heading in self.viewModel.currentTokens where heading is HeadingToken {
            let result = self.viewModel.performAction(EditAction.addNewLineBelow(location: textView.selectedRange.location), textView: textView)
            textView.selectedRange = NSRange(location: result.range!.location, length: 0)
            return false
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
        if textView.selectedRange.length == 0 {
            for case let attachmentToken in self.viewModel.currentTokens where attachmentToken is AttachmentToken {
                textView.selectedRange = attachmentToken.range
                return false
            }
            
            for case let dateAndTimeToken in self.viewModel.currentTokens where dateAndTimeToken is DateAndTimeToken {
                textView.selectedRange = dateAndTimeToken.range
                return false
            }
            
            for case let textMark in self.viewModel.currentTokens where textMark is TextMarkToken {
                if textMark.range.length == 2 /* 没有内容 */ {
                    let oldSelectedRange = textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.replaceText(textMark.range, ""), textView: textView)
                    textView.selectedRange = oldSelectedRange.offset(result.range!.location - oldSelectedRange.location)
                    return false
                }
            }
            
            for case let token in self.viewModel.currentTokens where token is HeadingToken {
                let headingToken = token as! HeadingToken
                let location = textView.selectedRange.location
                
                if let tagsRange = headingToken.tags {
                    if tagsRange.contains(location) || tagsRange.upperBound == location {
                        textView.selectedRange = tagsRange
                        return false
                    }
                }
                
                if let planningRange = headingToken.planning {
                    if planningRange.contains(location) || planningRange.upperBound == location {
                        textView.selectedRange = planningRange
                        return false
                    }
                }
                
                if let priorityRange = headingToken.priority {
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
    
    internal func _moveTo(location: Int) {
        // FIXME:
        if let position = self.textView.position(from: self.textView.beginningOfDocument, offset: location) {
            let r = self.textView.firstRect(for: self.textView.textRange(from: position, to: position)!)
            self.textView.setContentOffset(CGPoint(x: self.textView.contentOffset.x, y: r.origin.y), animated: false)
        }
    }
}

