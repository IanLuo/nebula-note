//
//  UIView+Convenience.swift
//  Interface
//
//  Created by ian luo on 2020/7/18.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    @discardableResult
    func backgroundColor(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }
}

public extension UIButton {
    @discardableResult
    func title(_ title: String, `for` state: UIControl.State) -> UIButton {
        self.setTitle(title, for: state)
        return self
    }
    
    @discardableResult
    func titleColor(_ color: UIColor, `for` state: UIControl.State) -> UIButton {
        self.setTitleColor(color, for: state)
        return self
    }
    
    
 }
