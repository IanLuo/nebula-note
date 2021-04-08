//
//  Size.swift
//  Business
//
//  Created by ian luo on 2019/1/16.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

extension CGSize {
    public static var singlePoint: CGSize {
        return CGSize(width: 1, height: 1)
    }
}

extension CGSize {
    public func aspectFitWidthScale(for width: CGFloat) -> CGSize {
        let scale = self.width / width
        return self.applying(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
    }
    
    public func aspectFitHeightScale(for height: CGFloat) -> CGSize {
        let scale = self.height / height
        return self.applying(CGAffineTransform(scaleX: 1 / scale, y: 1 / scale))
    }
    
    public func aspectFitSizeScale(for size: CGSize) -> CGSize {
        if self.width / size.width >= self.height / size.height {
            return self.aspectFitWidthScale(for: size.width)
        } else {
            return self.aspectFitHeightScale(for: size.height)
        }
    }
    
    public func heigher(by: CGFloat) -> CGSize {
        return CGSize(width: self.width, height: self.height + by)
    }
    
    public func wider(by: CGFloat) -> CGSize {
        return CGSize(width: self.width + by, height: self.height)
    }
}


extension String {
    public func boundingBox(for width: CGFloat, font: UIFont) -> CGSize {
        return (self as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
                                               options: [],
                                               attributes: [NSAttributedString.Key.font: font], context: nil).size
    }
}
