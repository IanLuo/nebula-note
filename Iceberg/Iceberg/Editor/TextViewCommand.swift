//
//  CursorCommand.swift
//  Iceland
//
//  Created by ian luo on 2019/3/20.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol TextViewCommandProtocol {
    func toggle(textView: UITextView)
}

public struct UndoCommand: TextViewCommandProtocol {
    public func toggle(textView: UITextView) {
        if textView.undoManager?.canUndo == true {
            textView.undoManager?.undo()
        }
    }
}

public struct RedoCommand: TextViewCommandProtocol {
    public func toggle(textView: UITextView) {
        if textView.undoManager?.canRedo == true {
            textView.undoManager?.redo()
        }
    }
}

public struct MoveCursorCommand: TextViewCommandProtocol {
    public enum Direction {
        case up
        case down
        case left
        case right
    }
    
    public func toggle(textView: UITextView) {
        switch direction {
        case .up:
            if let range = textView.selectedTextRange,
                let s = textView.position(from: range.start, in: UITextLayoutDirection.up, offset: 1) {
                textView.selectedTextRange = textView.textRange(from: s, to: s)
            }
        case .down:
            if let range = textView.selectedTextRange,
                let s = textView.position(from: range.start, in: UITextLayoutDirection.down, offset: 1) {
                textView.selectedTextRange = textView.textRange(from: s, to: s)
            }
        case .left:
            if let range = textView.selectedTextRange,
                let position = textView.position(from: range.start, offset: -1) {
                textView.selectedTextRange = textView.textRange(from: position, to: position)
            }
        case .right:
            if let range = textView.selectedTextRange,
                let position = textView.position(from: range.start, offset: 1) {
                textView.selectedTextRange = textView.textRange(from: position, to: position)
            }
        }
    }
    
    let locaton: Int
    let direction: Direction
}
