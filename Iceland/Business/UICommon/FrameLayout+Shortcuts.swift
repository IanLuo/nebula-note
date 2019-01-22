//
//  FrameLayout+Shortcuts.swift
//  Business
//
//  Created by ian luo on 2019/1/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

extension CGRect {
    public var bottomRightCorner: CGPoint {
        return CGPoint(x: self.maxX, y: self.maxY)
    }
}
