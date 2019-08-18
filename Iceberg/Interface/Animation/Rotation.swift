//
//  Rotation.swift
//  Business
//
//  Created by ian luo on 2019/1/31.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    public func perspectiveRotate(angel: CGFloat, skipAnimation: Bool = false) {
        var perspective = CATransform3DIdentity
        perspective.m34 = 1.0 / -1800.0
        
        let transform = CATransform3DRotate(perspective, angel, 1, 0, 0)

        if skipAnimation {
            self.layer.transform = transform
            return
        }
        
        self.layer.zPosition = 100

        UIView.animate(withDuration: 0.5) {
            self.layer.transform = transform
        }
    }
    
    public func rotate(angel: CGFloat, skipAnimation: Bool = false) {
        if skipAnimation {
            self.layer.setAffineTransform(CGAffineTransform(rotationAngle: angel))
            return
        }
        
        UIView.animate(withDuration: 0.25) {
            self.layer.setAffineTransform(CGAffineTransform(rotationAngle: angel))
        }
    }
}
