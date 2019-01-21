//
//  Rect.swift
//  Business
//
//  Created by ian luo on 2019/1/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {
    public func offsetX(_ x: CGFloat) -> CGRect {
        return offset(x: x, y: 0)
    }
    
    public func offsetY(_ y: CGFloat) -> CGRect {
        return offset(x: 0, y: y)
    }
    
    public func offset(x: CGFloat, y: CGFloat) -> CGRect {
        var rect = self
        rect.origin.x = x
        rect.origin.y = y
        return rect
    }
}
