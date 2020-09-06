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
    case captureIdea
    
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
    
    var title: String {
        return ""
    }
    
    var image: UIImage? {
        return nil
    }
}

public struct KeyPair {
    let modifier: UIKeyModifierFlags
    let input: String
}

public struct KeyBinding {
    public init() {}
    
    let keyBindingMap: [KeyAction: String] = [
        .toggleLeftPart: "ctl`shift`1",
        .toggleMiddlePart: "ctl`shift`2",
        .agendaTab: "ctl`cmd`1",
        .ideaTab: "ctl`cmd`2",
        .searchTab: "ctl`cmd`3",
        .browserTab: "ctl`cmd`4",
        .paragraphMenu: "ctl`cmd`p",
        .headingMenu: "ctl`cmd`h",
        .statusMenu: "ctl`cmd`s",
        .tagMenu: "ctl`cmd`t",
        .priorityMenu: "ctl`cmd`r",
        .dateTimeMenu: "ctl`cmd`d",
        .fileLink: "ctl`cmd`f",
        .pickIdeaMenu: "ctl`cmd`i",
        .pickAttachmentMenu: "ctl`cmd`a",
        .addAttachmentMenu: "ctl`cmd`=",
        .toggleFullWidth: "ctl`cmd`/",
        .foldAll: "ctl`cmd`[",
        .unfoldAll: "ctl`cmd`]",
        .outline: "ctl`cmd`'",
        .inspector: "ctl`cmd`;",
        .captureIdea: "ctl`cmd`c",
        .bold: "cmd`shift`b",
        .italic: "cmd`shift`i",
        .underscore: "cmd`shift`u",
        .strikeThrough: "cmd`shift`s",
        .highlight: "cmd`shift`h",
        .moveUp: "cmd`shift`\(UIKeyCommand.inputUpArrow)",
        .moveDown: "cmd`shift`\(UIKeyCommand.inputDownArrow)",
        .seperator: "cmd`shift`-",
        .codeBlock: "cmd`shift`c",
        .quoteBlock: "cmd`shift`q",
        .checkbox: "cmd`shift`c",
        .list: "cmd`shift`l",
        .orderedList: "cmd`shift`o"
    ]
    
    
    public let modifierMap: [String: UIKeyModifierFlags] = [
        "ctl": .control,
        "cmd": .command,
        "alt": .alternate,
        "shift": .shift,
    ]
    
    private func getModifier(with action: KeyAction) -> UIKeyModifierFlags {
        let keys = self.keyBindingMap[action]!.components(separatedBy: "`")
        if keys.count < 2 {
            return []
        } else {
            let optionalSet: UIKeyModifierFlags = []
            return keys.dropLast().map {
                self.modifierMap[$0]!
            }.reduce(optionalSet) { result, next in
                return [result, next]
            }
        }
    }
    
    private func getInput(with action: KeyAction) -> String {
        let keys = self.keyBindingMap[action]!.components(separatedBy: "`")
        return keys.last!
    }
    
    public func create(for action: KeyAction, block: @escaping () -> Void) -> UIKeyCommand {
        return UIKeyCommand(input: self.getInput(with: action), modifier: self.getModifier(with: action), block: block)
    }
}

private var key: Void?
extension UIKeyCommand {
    public convenience init(input: String, modifier: UIKeyModifierFlags, block: @escaping () -> Void) {
        self.init(input: input, modifierFlags: modifier, action: #selector(UIWindow.onAction))
        self.addAction(block)
    }
    
    public func addAction(_ action: @escaping () -> Void) {
        objc_setAssociatedObject(self, &key, action, .OBJC_ASSOCIATION_RETAIN)
    }
}

extension UIWindow {
    @objc fileprivate func onAction(command: UIKeyCommand) {
        (objc_getAssociatedObject(command, &key) as? () -> Void)?()
    }
}

private var commandKey: Void?
extension UIViewController {
    @available(iOS 13.0, *)
    public var dismissKeyCommand: UIKeyCommand {
        let command = UIKeyCommand(title: "esc", action: #selector(UIWindow.dismissPopover), input: UIKeyCommand.inputEscape)
        objc_setAssociatedObject(command, &commandKey, self, .OBJC_ASSOCIATION_ASSIGN)
        return command
    }
}

extension UIWindow {
    @objc fileprivate func dismissPopover(command: UIKeyCommand) {
        guard let viewController = objc_getAssociatedObject(command, &commandKey) as? UIViewController else { return }
        if let presentedViewController = viewController.presentedViewController, presentedViewController.modalPresentationStyle == .popover {
            presentedViewController.dismiss(animated: true)
        }
    }
}
