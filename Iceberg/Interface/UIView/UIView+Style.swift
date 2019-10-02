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
    func roundConer(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}
