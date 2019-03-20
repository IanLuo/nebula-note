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
    var title: String { get }
    var icon: UIImage { get }
}

public protocol DocumentActon {}

public protocol TextViewAction {
    func toggle(textView: UITextView, location: Int)
}

public protocol ToolbarActionGroupProtocol: ToolbarActionProtocol {
    var actions: [ToolbarActionProtocol] { get }
}

public struct CursorActions: ToolbarActionGroupProtocol {
    public var actions: [ToolbarActionProtocol] = [CursorAction.moveUp, CursorAction.moveDown, CursorAction.moveLeft, CursorAction.moveRight]
    
    public var title: String = ""
    
    public var icon: UIImage = Asset.Assets.add.image
}

public struct Attachments: ToolbarActionGroupProtocol {
    public var actions: [ToolbarActionProtocol] = [AttachmentAction.image, AttachmentAction.sketch, AttachmentAction.link, AttachmentAction.location, AttachmentAction.audio, AttachmentAction.video]
    
    public var title: String = ""
    
    public var icon: UIImage = Asset.Assets.imageLibrary.image
}

public struct TextMarkActions: ToolbarActionGroupProtocol {
    public var actions: [ToolbarActionProtocol] = [NormalAction.bold, NormalAction.italic, NormalAction.underscore, NormalAction.strikethrough, NormalAction.code, NormalAction.verbatim]
    
    public var title: String = ""
    
    public var icon: UIImage = UIImage()
}

public struct IndentActions: ToolbarActionGroupProtocol {
    public var actions: [ToolbarActionProtocol] = [NormalAction.increaseIndent, NormalAction.decreaseIndent]
    
    public var title: String = ""
    
    public var icon: UIImage = UIImage()
}

public struct UndoActions: ToolbarActionGroupProtocol {
    public var actions: [ToolbarActionProtocol] = [NormalAction.undo, NormalAction.redo]
    
    public var title: String = ""
    
    public var icon: UIImage = UIImage()
}

public enum NormalAction: ToolbarActionProtocol, DocumentActon {
    case increaseIndent
    case decreaseIndent
    case undo
    case redo
    case bold
    case italic
    case underscore
    case strikethrough
    case code
    case verbatim
    
    public var title: String {
        switch self {
        case .increaseIndent:
            return L10n.Document.Edit.Action.increaseIndent
        case .decreaseIndent:
            return L10n.Document.Edit.Action.decreaseIndent
        case .undo:
            return L10n.Document.Edit.Action.undo
        case .redo:
            return L10n.Document.Edit.Action.redo
        case .bold:
            return L10n.Document.Edit.Action.Mark.bold
        case .italic:
            return L10n.Document.Edit.Action.Mark.italic
        case .underscore:
            return L10n.Document.Edit.Action.Mark.underscore
        case .strikethrough:
            return L10n.Document.Edit.Action.Mark.strikthrough
        case .code:
            return L10n.Document.Edit.Action.Mark.code
        case .verbatim:
            return L10n.Document.Edit.Action.Mark.verbatim
        }
    }
    
    public var icon: UIImage {
        switch self {
        case .increaseIndent:
            return Asset.Assets.imageLibrary.image
        case .decreaseIndent:
            return Asset.Assets.imageLibrary.image
        case .undo:
            return Asset.Assets.imageLibrary.image
        case .redo:
            return Asset.Assets.imageLibrary.image
        case .bold:
            return Asset.Assets.imageLibrary.image
        case .italic:
            return Asset.Assets.imageLibrary.image
        case .underscore:
            return Asset.Assets.imageLibrary.image
        case .strikethrough:
            return Asset.Assets.imageLibrary.image
        case .code:
            return Asset.Assets.imageLibrary.image
        case .verbatim:
            return Asset.Assets.imageLibrary.image
        }
    }
    
    public func toggle(viewModel: DocumentEditViewModel) {
        // TODO
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
        case .audio: return Asset.Assets.imageLibrary.image
        case .video: return Asset.Assets.imageLibrary.image
        case .sketch: return Asset.Assets.imageLibrary.image
        case .location: return Asset.Assets.imageLibrary.image
        case .link: return Asset.Assets.imageLibrary.image
        }
    }
    
    public var title: String {
        switch self {
        case .image: return L10n.Attachment.Kind.image
        case .audio: return L10n.Attachment.Kind.audio
        case .video: return L10n.Attachment.Kind.video
        case .sketch: return L10n.Attachment.Kind.sketch
        case .location: return L10n.Attachment.Kind.location
        case .link: return L10n.Attachment.Kind.link
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
    
    public var title: String {
        switch self {
        case .moveUp: return L10n.Document.Edit.Action.arrowUp
        case .moveDown: return L10n.Document.Edit.Action.moveDown
        case .moveLeft: return L10n.Document.Edit.Action.arrowLeft
        case .moveRight: return L10n.Document.Edit.Action.arrowRight
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
