//
//  UIScrollView+Scrolling.swift
//  Interface
//
//  Created by ian luo on 2020/6/26.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
    public var visiableRect: CGRect {
        return CGRect(origin: self.contentOffset, size: self.frame.size)
    }
    
    public func scrollRectToVisibleIfneeded(_ rect: CGRect, animated: Bool) {
        if !self.visiableRect.intersects(rect) {
            self.scrollRectToVisible(rect, animated: animated)
        }
    }
}
