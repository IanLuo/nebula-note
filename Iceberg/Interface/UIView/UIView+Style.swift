//
//  UIView+Style.swift
//  Interface
//
//  Created by ian luo on 2019/10/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    func roundConer(radius: CGFloat, corners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]) {
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = corners
        self.layer.masksToBounds = true
    }
    
    func border(color: UIColor, width: CGFloat) {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
}
