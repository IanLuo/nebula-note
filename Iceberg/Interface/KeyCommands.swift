//
//  KeyCommands.swift
//  x3Note
//
//  Created by ian luo on 2020/8/19.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit

public enum KeyAction: String {
    // view
    case toggleLeftPart
    case toggleMiddlePart
    case agendaTab
    case searchTab
    case ideaTab
    case browserTab
    
    // editor
    case paragraphMenu
    case headingMenu
    case statusMenu
    case tagMenu
    case priorityMenu
    case bold
    case italic
    case underscore
    case strikeThrough
    case highlight
    case moveUp
    case moveDown
    case seperator
    case codeBlock
    case quoteBlock
    case checkbox
    case dateTimeMenu
    case list
    case orderedList
    case fileLink
    case pickIdeaMenu
    case pickAttachmentMenu
    case addAttachmentMenu
    case toggleFullWidth
    case foldAll
    case unfoldAll
    case outline
    case inspector
}

public struct KeyPair {
    let modifier: UIKeyModifierFlags
    let input: String
}

public struct KeyPairBinding {
    let keyPair: KeyPair
    let action: KeyAction
}

public struct Key: ExpressibleByStringLiteral, Hashable {
    public static func == (lhs: Key, rhs: Key) -> Bool {
        return lhs.value == rhs.value
    }
    
    public typealias StringLiteralType = String
    public let value: String
    
    public init(stringLiteral value: String) {
        self.value = value
    }
}

func +(lhs: Key, rhs: Key) -> [Key] {
    return [lhs, rhs]
}

func +(lhs: [Key], rhs: [Key]) -> [Key] {
    return [lhs, rhs].flatMap{ $0 }
}

func +(lhs: Key, rhs: [Key]) -> [Key] {
    var r = rhs
    r.append(lhs)
    return r
}

func +(lhs: [Key], rhs: Key) -> [Key] {
    var l = lhs
    l.append(rhs)
    return l
}

public struct KeyBindingMap {
    let keyBindingMap: [Key: KeyAction] = [
        "ctl+shift+1": .toggleLeftPart,
        "ctl+shift+2": .toggleMiddlePart,
        "ctl+cmd+1": .agendaTab,
        "ctl+cmd+2": .ideaTab,
        "ctl+cmd+3": .searchTab,
        "ctl+cmd+4": .browserTab,
        "cmd+shift+p": .paragraphMenu,
        "cmd+shift+h": .headingMenu,
        "cmd+shift+s": .statusMenu,
        "9": .tagMenu,
        "10": .priorityMenu,
        "11": .bold,
        "12": .italic,
        "13": .underscore,
        "14": .strikeThrough,
        "15": .highlight,
        "16": .moveUp,
        "17": .moveDown,
        "18": .seperator,
        "19": .codeBlock,
        "20": .quoteBlock,
        "21": .checkbox,
        "22": .dateTimeMenu,
        "23": .list,
        "24": .orderedList,
        "25": .fileLink,
        "26": .pickIdeaMenu,
        "27": .pickAttachmentMenu,
        "28": .addAttachmentMenu,
        "29": .toggleFullWidth,
        "30": .foldAll,
        "31": .unfoldAll,
        "32": .outline,
        "33": .inspector
    ]
    
    public static let seperator: String = "-"
    public static let ctr: Key = "ctr"
    public static let cmd: Key = "cmd"
    public static let alt: Key = "alt"
    public static let shift: Key = "shift"
    
    public static let modifierMap: [Key: UIKeyModifierFlags] = [
        Self.ctr: .control,
        Self.cmd: .command,
        Self.alt: .alternate,
        Self.shift: .shift,
    ]
    
    public func getModifier(with key: [Key]) -> UIKeyModifierFlags {
        if key.count < 2 {
            return []
        } else {
            return Self.modifierMap[key.last!] ?? []
        }
    }
    
    public func getInput(with key: [Key]) -> String {
        if key.count > 0 {
            return key.last!.value
        } else {
            return ""
        }
    }
}

extension UIViewController {
    @available(iOS 13.0, *)
    public var dismissKeyCommand: UIKeyCommand {
        return UIKeyCommand(title: "esc", action: #selector(dismissPopover), input: UIKeyCommand.inputEscape)
    }
    
    @objc private func dismissPopover() {
        if let presentedViewController = self.presentedViewController, presentedViewController.modalPresentationStyle == .popover {
            presentedViewController.dismiss(animated: true)
        }
    }
}
