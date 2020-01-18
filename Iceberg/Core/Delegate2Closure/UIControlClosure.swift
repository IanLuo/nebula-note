//
//  UIControlClosure.swift
//  HNAApp
//
//  Created by ian luo on 2018/6/27.
//  Copyright © 2017年 wod. All rights reserved.
//

import Foundation
import UIKit.UIControl

private var key: Void?

extension UIControl {
    public func triggered(event: UIControl.Event, action: @escaping ((UIControl) -> Void)) {
        let dummyHandler = DummyHandler(action: action)
        addTarget(dummyHandler, action: #selector(DummyHandler.handler), for: event)
        setValue(dummyHandler, key: &key)
    }
}

fileprivate class DummyHandler {
    let action: (UIControl) -> Void
    
    init(action: @escaping (UIControl) -> Void) {
        self.action = action
    }
    
    @objc func handler(control: UIControl) {
        action(control)
    }
}

extension UISwitch {
    public func onValueChanged(_ action: @escaping (UISwitch, Bool) -> Void) {
        self.triggered(event: UIControl.Event.valueChanged) { control in
            let switchButton = (control as! UISwitch)
            action(switchButton, switchButton.isOn)
        }
    }
}
