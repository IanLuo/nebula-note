//
//  MenuController.swift
//  Interface
//
//  Created by ian luo on 2020/8/24.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public struct MenuBar {
    let file: MenuItem
    let view: MenuItem
    let edit: MenuItem
}

public enum MenuType {
    @available(iOS 13.0, *)
    case command(UICommand)
    case group([MenuItem])
}

public struct MenuItem {
    let title: String
    let icon: UIImage?
    let type: MenuType
}

public class MenuController {
    
}

fileprivate func +(lhs: MenuItem, rhs: MenuItem) -> [MenuItem] {
    return [lhs, rhs]
}

fileprivate func +(lhs: [MenuItem], rhs: MenuItem) -> [MenuItem] {
    var lhss = lhs
    lhss.append(rhs)
    return lhss
}

fileprivate func +(lhs: MenuItem, rhs: [MenuItem]) -> [MenuItem] {
    var rhss = rhs
    rhss.append(lhs)
    return rhss
}

@available(iOS 13.0, *)
public extension DesktopHomeViewController {
    var toggleLeftPartCommand: UIKeyCommand {
        let isLeftPartVisiable = self.isLeftPartVisiable == true
        let title = isLeftPartVisiable
        ? "Hide Left Part"
        : "Show Left Part"
        return UIKeyCommand(title: title, image: Asset.Assets.leftPart.image, input: "1", modifierFlags: [.shift, .command], action: {
            self.toggleLeftPartVisiability(visiable: !isLeftPartVisiable)
        })
    }
    
    var toggleMiddlePartCommand: UIKeyCommand {
        let isMiddlePartVisiable = self.isMiddlePartVisiable == true
        let title = isMiddlePartVisiable
        ? "Hide Left Part"
        : "Show Left Part"
        return UIKeyCommand(title: title, image: Asset.Assets.leftPart.image, input: "2", modifierFlags: [.shift, .command], action: {
            self.toggleMiddlePartVisiability(visiable: !isMiddlePartVisiable)
        })
    }
}

extension DocumentEditorViewController {
    public func initKeyCommands() -> [UIKeyCommand] {
        if #available(iOS 13.0, *) {
            return [
                UIKeyCommand(title: "Paragraph Action", image: nil, action: #selector(showParagraphActionsInPlace), input: "p", modifierFlags: UIKeyModifierFlags.command, propertyList: nil, alternates: [], discoverabilityTitle: nil, attributes: UIMenuElement.Attributes(), state: UIMenuElement.State.on),
                UIKeyCommand(title: "Headings Action", image: nil, action: #selector(showParagraphActionsInPlace), input: "h", modifierFlags: UIKeyModifierFlags.command, propertyList: nil, alternates: [], discoverabilityTitle: nil, attributes: UIMenuElement.Attributes(), state: UIMenuElement.State.on),
                self.dismissKeyCommand
            ]
        } else {
            return []
        }
    }
    
    @objc func showParagraphActionsInPlace() {
        self.showParagraphActions(at: self.textView.selectedRange.location)
    }
    
    @objc func showHeadingsActionInPlace() {
        self.showHeadingEdit(at: self.textView.selectedRange.location)
    }
}

private var key: Void?
@available(iOS 13.0, *)
extension UIKeyCommand {
    public convenience init(title: String, image: UIImage?, input: String, modifierFlags: UIKeyModifierFlags, action: @escaping () -> Void) {
        self.init(title: title, image: image, action: #selector(a), input: input, modifierFlags: modifierFlags)
        objc_setAssociatedObject(self, &key, action, .OBJC_ASSOCIATION_RETAIN)
    }
        
    @objc private func a() {
        (objc_getAssociatedObject(self, &key) as? () -> Void)?()
    }
}
