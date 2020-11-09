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
    
    @discardableResult
    func roundConer(radius: CGFloat, corners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]) -> Self {
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = corners
        self.layer.masksToBounds = true
        return self
    }
    
    @discardableResult
    func border(color: UIColor, width: CGFloat) -> Self {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        return self
    }
}

public extension UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    @discardableResult
    func font(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
    
    @discardableResult
    func textColor(_ color: UIColor) -> Self {
        self.textColor = color
        return self
    }
}

public extension UIButton {
    @discardableResult
    convenience init(title: String, `for`: UIControl.State) {
        self.init()
        self.title(title, for: `for`)
    }
    
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
    
    @discardableResult
    func backgroundImage(_ color: UIColor, `for` state: UIControl.State) -> UIButton {
        self.setBackgroundImage(UIImage.create(with: color, size: .singlePoint), for: state)
        return self
    }
    
 }


public extension UIStackView {
    convenience init(subviews: [UIView],
                     axis: NSLayoutConstraint.Axis = .horizontal,
                     distribution: Distribution = .equalCentering,
                     alignment: Alignment = .center) {
        self.init(arrangedSubviews: subviews)
        
        self.distribution = distribution
        self.axis = axis
        self.alignment = alignment
    }
}
