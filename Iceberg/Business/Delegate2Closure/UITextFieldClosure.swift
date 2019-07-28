//
//  UITextFieldClosure.swift
//  UIComponent
//
//  Created by ian luo on 2018/6/26.
//  Copyright © 2017年 wod. All rights reserved.
//

import Foundation
import UIKit.UITextField

extension UITextField {
    public func textChanged(_ action: @escaping (String?) -> Void) {
        triggered(event: .editingChanged) {
            action(($0 as? UITextField)?.text)
        }
    }
}
