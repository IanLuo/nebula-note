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
    case captureIdea
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
    
    var isGlobal: Bool {
        switch self {
        case .captureIdea:
            return true
        case .toggleLeftPart:
            return true
        case .toggleMiddlePart:
            return true
        case .agendaTab:
            return true
        case .searchTab:
            return true
        case .ideaTab:
            return true
        case .browserTab:
            return true
        case .toggleFullWidth:
            return true
        case .foldAll:
            return true
        case .unfoldAll:
            return true
        case .outline:
            return true
        case .inspector:
            return true
        default: return false
        }
    }
    
    var title: String {
        switch self {
            
        case .toggleLeftPart:
            return L10n.Key.Command.toggleLeftPart
        case .toggleMiddlePart:
            return L10n.Key.Command.toggleMiddlePart
        case .agendaTab:
            return L10n.Key.Command.agendaTab
        case .searchTab:
            return L10n.Key.Command.searchTab
        case .ideaTab:
            return L10n.Key.Command.ideaTab
        case .browserTab:
            return L10n.Key.Command.browserTab
        case .captureIdea:
            return L10n.Key.Command.captureTab
        case .paragraphMenu:
            return L10n.Key.Command.paragraphMenu
        case .headingMenu:
            return L10n.Key.Command.headingMenu
        case .statusMenu:
            return L10n.Key.Command.statusMenu
        case .tagMenu:
            return L10n.Key.Command.tagMenu
        case .priorityMenu:
            return L10n.Key.Command.priorityMenu
        case .bold:
            return L10n.Key.Command.boldText
        case .italic:
            return L10n.Key.Command.italicText
        case .underscore:
            return L10n.Key.Command.underscoreText
        case .strikeThrough:
            return L10n.Key.Command.strikeThroughText
        case .highlight:
            return L10n.Key.Command.highlightText
        case .moveUp:
            return L10n.Key.Command.moveUp
        case .moveDown:
            return L10n.Key.Command.moveDown
        case .seperator:
            return L10n.Key.Command.seperator
        case .codeBlock:
            return L10n.Key.Command.codeBlock
        case .quoteBlock:
            return L10n.Key.Command.quoteBlock
        case .checkbox:
            return L10n.Key.Command.checkbox
        case .dateTimeMenu:
            return L10n.Key.Command.dateAndTime
        case .list:
            return L10n.Key.Command.list
        case .orderedList:
            return L10n.Key.Command.orderedList
        case .fileLink:
            return L10n.Key.Command.fileLink
        case .pickIdeaMenu:
            return L10n.Key.Command.pickIdeaMenu
        case .pickAttachmentMenu:
            return L10n.Key.Command.pickerAttachmentMenu
        case .addAttachmentMenu:
            return L10n.Key.Command.addAttachment
        case .toggleFullWidth:
            return L10n.Key.Command.toggleFullWidth
        case .foldAll:
            return L10n.Key.Command.foldAll
        case .unfoldAll:
            return L10n.Key.Command.unfoldAll
        case .outline:
            return L10n.Key.Command.outline
        case .inspector:
            return L10n.Key.Command.inspector
        }
    }
    
    var image: UIImage? {
        return nil
    }
    
    var documentAction: DocumentActon {
        switch self {
            
        case .captureIdea:
            return OtherAction.captureIdea
        case .toggleLeftPart:
            return OtherAction.toggleLeftPart
        case .toggleMiddlePart:
            return OtherAction.toggleMiddlePart
        case .agendaTab:
            return OtherAction.agendaTab
        case .searchTab:
            return OtherAction.searchTab
        case .ideaTab:
            return OtherAction.ideaTab
        case .browserTab:
            return OtherAction.browserTab
        case .paragraphMenu:
            return NormalAction.paragraph
        case .headingMenu:
            return NormalAction.heading
        case .statusMenu:
            return NormalAction.planning
        case .tagMenu:
            return NormalAction.tag
        case .priorityMenu:
            return NormalAction.priority
        case .bold:
            return NormalAction.bold
        case .italic:
            return NormalAction.italic
        case .underscore:
            return NormalAction.underscore
        case .strikeThrough:
            return NormalAction.strikethrough
        case .highlight:
            return NormalAction.highlight
        case .moveUp:
            return NormalAction.moveUp
        case .moveDown:
            return NormalAction.moveDown
        case .seperator:
            return NormalAction.seperator
        case .codeBlock:
            return NormalAction.sourcecode
        case .quoteBlock:
            return NormalAction.quote
        case .checkbox:
            return NormalAction.checkbox
        case .dateTimeMenu:
            return NormalAction.dateAndTime
        case .list:
            return NormalAction.list
        case .orderedList:
            return NormalAction.orderedList
        case .fileLink:
            return NormalAction.fileLink
        case .pickIdeaMenu:
            return NormalAction.captured
        case .pickAttachmentMenu:
            return NormalAction.allAttachments
        case .addAttachmentMenu:
            return NormalAction.newAttachment
        case .toggleFullWidth:
            return OtherAction.toggleFullWidth
        case .foldAll:
            return OtherAction.foldAll
        case .unfoldAll:
            return OtherAction.unfoldAll
        case .outline:
            return OtherAction.outline
        case .inspector:
            return OtherAction.inspector
        }
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
        .checkbox: "cmd`shift`x",
        .list: "cmd`shift`l",
        .orderedList: "cmd`shift`o"
    ]
    
    public func constructMenu(builder: UIMenuBuilder) {
        guard builder.system == UIMenuSystem.main else { return }
        
        enum Menu: String {
            case panel
            case tab
            case editor
            case capture
            
            case editorAttachment
            case editorText
            case editorAction
            case editorInsert
            case editorOther
            case editorOther2
            case editorOther3
            
            var identifier: UIMenu.Identifier {
                return UIMenu.Identifier(self.rawValue)
            }
        }
        
        builder.insertSibling(UIMenu(title: "View",
                                     image: nil,
                                     identifier: Menu.panel.identifier,
                                     options: [],
                                     children: [KeyAction.toggleLeftPart,
                                                KeyAction.toggleMiddlePart,
                                        ].map { self.create(for: $0) }),
                              afterMenu: UIMenu.Identifier.application)
        
        builder.insertChild(UIMenu(title: "Tab",
                                     image: nil,
                                     identifier: Menu.tab.identifier,
                                     options: [.displayInline],
                                     children: [KeyAction.agendaTab,
                                                KeyAction.ideaTab,
                                                KeyAction.searchTab,
                                                KeyAction.browserTab
                                        ].map { self.create(for: $0) }),
                              atEndOfMenu: Menu.panel.identifier)
        
        
        builder.insertSibling(UIMenu(title: "Edit",
                                     identifier: Menu.editor.identifier),
                              afterMenu: Menu.panel.identifier)
        
        builder.insertSibling(UIMenu(title: "Capture",
                                     identifier: Menu.capture.identifier,
                                     children: [KeyAction.captureIdea]
                                        .map { self.create(for: $0) }),
                              afterMenu: Menu.editor.identifier)
        
        builder.insertChild(UIMenu(title: "Actions",
                                     image: nil,
                                     identifier: Menu.editorAction.identifier,
                                     options: [],
                                     children: [
                                        KeyAction.paragraphMenu,
                                        KeyAction.headingMenu,
                                        KeyAction.statusMenu,
                                        KeyAction.tagMenu,
                                        KeyAction.priorityMenu,
                                        KeyAction.dateTimeMenu,
                                        ].map { self.create(for: $0) }),
                              atStartOfMenu: Menu.editor.identifier)
        
        builder.insertSibling(UIMenu(title: "Attachments",
                                   image: nil,
                                   identifier: Menu.editorAttachment.identifier,
                                   options: [],
                                   children: [KeyAction.fileLink,
                                              KeyAction.pickIdeaMenu,
                                              KeyAction.pickAttachmentMenu,
                                              KeyAction.addAttachmentMenu,
                                    ].map { self.create(for: $0) }),
                            afterMenu: Menu.editorAction.identifier)
        
        builder.insertSibling(UIMenu(title: "Text",
                                   image: nil,
                                   identifier: Menu.editorText.identifier,
                                   options: [],
                                   children: [KeyAction.bold,
                                              KeyAction.italic,
                                              KeyAction.underscore,
                                              KeyAction.strikeThrough,
                                              KeyAction.highlight
                                    ].map { self.create(for: $0) }),
        afterMenu: Menu.editorAttachment.identifier)
        
        builder.insertSibling(UIMenu(title: "Insert",
                                   image: nil,
                                   identifier: Menu.editorInsert.identifier,
                                   options: [],
                                   children: [
                                    KeyAction.seperator,
                                    KeyAction.codeBlock,
                                    KeyAction.quoteBlock,
                                    KeyAction.checkbox,
                                    KeyAction.list,
                                    KeyAction.orderedList,
                                    ].map { self.create(for: $0) }),
        afterMenu: Menu.editorText.identifier)
        
        builder.insertSibling(UIMenu(title: "Other",
                                   image: nil,
                                   identifier: Menu.editorOther.identifier,
                                   options: [],
                                   children: [
                                    KeyAction.foldAll,
                                    KeyAction.unfoldAll,
                                    KeyAction.outline,
                                    KeyAction.inspector,
                                    ].map { self.create(for: $0) }),
        afterMenu: Menu.editorInsert.identifier)
        
        builder.insertSibling(UIMenu(title: "Other",
                                   image: nil,
                                   identifier: Menu.editorOther2.identifier,
                                   options: [.displayInline],
                                   children: [
                                    KeyAction.moveUp,
                                    KeyAction.moveDown,
                                    ].map { self.create(for: $0) }),
        afterMenu: Menu.editorOther.identifier)
        
        builder.insertSibling(UIMenu(title: "Other",
                                   image: nil,
                                   identifier: Menu.editorOther3.identifier,
                                   options: [.displayInline],
                                   children: [
                                    KeyAction.toggleFullWidth,
                                    ].map { self.create(for: $0) }),
        afterMenu: Menu.editorOther2.identifier)
    }
    
    
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
    
    @available(iOS 13.0, *)
    public func create(for action: KeyAction) -> UIKeyCommand {
        let command = UIKeyCommand(title: action.title,
                                   action: #selector(UIWindow.onAction),
                                   input: self.getInput(with: action),
                                   modifierFlags: self.getModifier(with: action),
                                   propertyList: ["title": action.documentAction.title, "is-global": action.isGlobal])
        return command
    }
    
    public func addAction(for action: KeyAction, on: UIViewController?, block: @escaping () -> Void) {
        UIApplication.shared.windows.forEach { $0.addAction(for: action, on: on, block: block) }
    }
}

private var actionKey: Void?
private var validatehandlerKey: Void?
extension UIWindow {
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIWindow.onAction) {
            return true
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
    
    open override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
        if action == #selector(UIWindow.onAction) {
            return self
        }
        
        return super.target(forAction: action, withSender: sender)
    }
    
    open override func validate(_ command: UICommand) {
        if (objc_getAssociatedObject(self, &validatehandlerKey) as? (UICommand) -> Bool)?(command) ?? true {
            command.attributes = []
        } else {
            command.attributes = .disabled
        }
    }
    
    public func addValidateHandler(_ handler: @escaping (UICommand) -> Bool) {
        objc_setAssociatedObject(self, &validatehandlerKey, handler, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    @objc fileprivate func onAction(command: UIKeyCommand) {
        if let map = objc_getAssociatedObject(self, &actionKey) as? [String: WeakObj] {
            map[command.title]?.block?()
        }
    }
    
    private class WeakObj {
        weak var obj: UIViewController? {
            didSet {
                if obj == nil {
                    self.block = nil
                }
            }
        }
        
        var block: (() -> Void)?
        init(obj: UIViewController?, block: @escaping () -> Void) {
            self.obj = obj
            self.block = block
        }
    }
    
    fileprivate func addAction(for action: KeyAction, on obj: UIViewController?, block: @escaping () -> Void) {
        if var map = objc_getAssociatedObject(self, &actionKey) as? [String: WeakObj] {
            map[action.title] = WeakObj(obj: obj, block: block)
            objc_setAssociatedObject(self, &actionKey, map, .OBJC_ASSOCIATION_RETAIN)
        } else {
            objc_setAssociatedObject(self, &actionKey, [action.title: WeakObj(obj: obj, block: block)], .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

private var commandKey: Void?
extension UIViewController {
    @available(iOS 13.0, *)
    public var dismissKeyCommand: UIKeyCommand {
        let command = UIKeyCommand(title: "", action: #selector(UIWindow.dismissPopover), input: UIKeyCommand.inputEscape)
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
