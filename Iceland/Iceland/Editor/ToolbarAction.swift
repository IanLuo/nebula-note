//
//  ToolbarAction.swift
//  Iceland
//
//  Created by ian luo on 2019/3/19.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import Business

public protocol ToolbarActionProtocol {
    var icon: UIImage { get }
}

public protocol DocumentActon {}

public protocol TextViewAction {
    func toggle(textView: UITextView, location: Int)
}

public enum NormalAction: ToolbarActionProtocol, DocumentActon {
    case heading
    case increaseIndent
    case decreaseIndent
    case moveUp
    case moveDown
    case undo
    case redo
    case bold
    case italic
    case underscore
    case strikethrough
    /// inline code
    case code
    case verbatim
    case checkbox
    case list
    case orderedList
    case quote
    /// code block
    case sourcecode
    case dateAndTime
    case planning
    case tag
    
    case captured
    
    public var icon: UIImage {
        switch self {
        case .heading:
            return Asset.Assets.heading.image
        case .increaseIndent:
            return Asset.Assets.tapAdd.image
        case .decreaseIndent:
            return Asset.Assets.tapMinus.image
        case .moveUp:
            return Asset.Assets.moveUp.image
        case .moveDown:
            return Asset.Assets.moveDown.image
        case .undo:
            return Asset.Assets.undo.image
        case .redo:
            return Asset.Assets.redo.image
        case .bold:
            return Asset.Assets.bold.image
        case .italic:
            return Asset.Assets.italic.image
        case .underscore:
            return Asset.Assets.underline.image
        case .strikethrough:
            return Asset.Assets.strikethrough.image
        case .code:
            return Asset.Assets.code.image
        case .verbatim:
            return Asset.Assets.code.image
        case .checkbox:
            return Asset.Assets.checkboxChecked.image
        case .list:
            return Asset.Assets.list.image
        case .orderedList:
            return Asset.Assets.orderedList.image
        case .quote:
            return Asset.Assets.quote.image
        case .sourcecode:
            return Asset.Assets.sourcecode.image
        case .dateAndTime:
            return Asset.Assets.agenda.image
        case .planning:
            return Asset.Assets.agenda.image
        case .tag:
            return Asset.Assets.tag.image
        case .captured:
            return Asset.Assets.capture.image
        }
    }
}

public enum AttachmentAction: ToolbarActionProtocol, DocumentActon {
    case image
    case audio
    case video
    case sketch
    case location
    case link
    
    public var AttachmentKind: Attachment.Kind {
        switch self {
        case .image: return Attachment.Kind.image
        case .audio: return Attachment.Kind.audio
        case .video: return Attachment.Kind.video
        case .sketch: return Attachment.Kind.sketch
        case .location: return Attachment.Kind.location
        case .link: return Attachment.Kind.link
        }
    }
    
    public var icon: UIImage {
        switch self {
        case .image: return Asset.Assets.imageLibrary.image
        case .audio: return Asset.Assets.audio.image
        case .video: return Asset.Assets.video.image
        case .sketch: return Asset.Assets.sketch.image
        case .location: return Asset.Assets.location.image
        case .link: return Asset.Assets.link.image
        }
    }
}

public enum CursorAction: ToolbarActionProtocol, TextViewAction {
    case moveUp
    case moveDown
    case moveLeft
    case moveRight
    
    public var icon: UIImage {
        switch self {
        case .moveUp: return Asset.Assets.up.image
        case .moveDown: return Asset.Assets.down.image
        case .moveLeft: return Asset.Assets.left.image
        case .moveRight: return Asset.Assets.right.image
        }
    }
    
    public func toggle(textView: UITextView, location: Int) {
        switch self {
        case .moveUp: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.up).toggle(textView: textView)
        case .moveDown: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.down).toggle(textView: textView)
        case .moveLeft: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.left).toggle(textView: textView)
        case .moveRight: MoveCursorCommand(locaton: location, direction: MoveCursorCommand.Direction.right).toggle(textView: textView)
        }
    }
}
