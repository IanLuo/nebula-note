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
            break // TODO
        case .down:
            break // TODO
        case .left:
            textView.selectedRange = textView.selectedRange.offset(-1)
        case .right:
            textView.selectedRange = textView.selectedRange.offset(1)
        }
    }
    
    let locaton: Int
    let direction: Direction
}
