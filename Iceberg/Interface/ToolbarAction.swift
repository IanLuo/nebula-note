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
    case headingProperty
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
    case toggleFoldOrUnfold
    case foldOthersExcept
    
    case template
    
    public var title: String { return self.rawValue }
    
    public var icon: UIImage {
        switch self {
        case .paragraph:
            return Asset.SFSymbols.paragraph.image
        case .heading:
            return Asset.Assets.heading.image
        case .increaseIndent:
            return Asset.SFSymbols.arrowRightToLine.image
        case .decreaseIndent:
            return Asset.SFSymbols.arrowLeftToLine.image
        case .moveUp:
            return Asset.SFSymbols.arrowUpToLine.image
        case .moveDown:
            return Asset.SFSymbols.arrowDownToLine.image
        case .undo:
            return Asset.SFSymbols.arrowUturnLeft.image
        case .redo:
            return Asset.SFSymbols.arrowUturnRight.image
        case .bold:
            return Asset.SFSymbols.bold.image
        case .italic:
            return Asset.SFSymbols.italic.image
        case .underscore:
            return Asset.SFSymbols.underline.image
        case .strikethrough:
            return Asset.SFSymbols.strikethrough.image
        case .highlight:
            return Asset.Assets.markerPen.image
        case .verbatim:
            return Asset.SFSymbols.chevronLeftSlashChevronRight.image
        case .checkbox:
            return Asset.SFSymbols.textBadgeCheckmark.image
        case .list:
            return Asset.SFSymbols.listBullet.image
        case .orderedList:
            return Asset.SFSymbols.listNumber.image
        case .quote:
            return Asset.SFSymbols.textQuote.image
        case .sourcecode:
            return Asset.SFSymbols.chevronLeftSlashChevronRight.image
        case .dateAndTime:
            return Asset.SFSymbols.calendar.image
        case .planning:
            return Asset.Assets.planning.image
        case .tag:
            return Asset.SFSymbols.tag.image
        case .priority:
            return Asset.SFSymbols.exclamationmark.image
        case .captured:
            return Asset.SFSymbols.lightbulb.image
        case .allAttachments:
            return Asset.SFSymbols.paperclip.image
        case .seperator:
            return Asset.Assets.separator.image
        case .newAttachment:
            return Asset.SFSymbols.plus.image
        case .fileLink:
            return Asset.Assets.fileLink.image
        case .save:
            return Asset.SFSymbols.squareAndArrowDown.image
        case .headingProperty:
            return Asset.SFSymbols.sliderHorizontal3.image
        case .template:
            return Asset.SFSymbols.bookClosed.image
        case .toggleFoldOrUnfold:
            return Asset.SFSymbols.star.image // not using on toolbar, the the icon is wrong
        case .foldOthersExcept:
            return Asset.SFSymbols.star.image // not using on toolbar, the the icon is wrong
        }
    }
}
