//
//  ToolbarAction.swift
//  Iceland
//
//  Created by ian luo on 2019/3/19.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol ToolbarActionProtocol {
    var icon: UIImage { get }
    var isMemberFunction: Bool { get }
    
}

public extension ToolbarActionProtocol {
    var isMemberFunction: Bool { return false }
}

public protocol DocumentActon {
    var title: String { get }
}

public protocol TextViewAction {
    func toggle(textView: UITextView, location: Int)
}

public enum OtherAction: String, DocumentActon {
    public var title: String { return self.rawValue }
    
    case captureIdea
    case toggleLeftPart
    case toggleMiddlePart
    case agendaTab
    case searchTab
    case ideaTab
    case browserTab
    case toggleFullWidth
    case foldAll
    case unfoldAll
    case outline
    case inspector
    case cancel
}

public enum NormalAction: String, ToolbarActionProtocol, DocumentActon {
    case paragraph
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
    case highlight
    case verbatim
    case checkbox
    case list
    case orderedList
    case quote
    case seperator
    /// code block
    case sourcecode
    case dateAndTime
    case planning
    case tag
    case priority
    
    case captured
    case allAttachments
    case newAttachment
    case fileLink
    case save
    
    public var title: String { return self.rawValue }
    
    public var icon: UIImage {
        switch self {
        case .paragraph:
            return Asset.Assets.paragraph.image
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
        case .highlight:
            return Asset.Assets.markerPen.image
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
            return Asset.Assets.calendar.image
        case .planning:
            return Asset.Assets.planning.image
        case .tag:
            return Asset.Assets.tag.image
        case .priority:
            return Asset.Assets.priority.image
        case .captured:
            return Asset.Assets.inspiration.image
        case .allAttachments:
            return Asset.Assets.attachment.image
        case .seperator:
            return Asset.Assets.seperator.image
        case .newAttachment:
            return Asset.Assets.add.image
        case .fileLink:
            return Asset.Assets.fileLink.image
        case .save:
            return Asset.Assets.save.image
        }
    }
}
