//
//  Image+Generation.swift
//  Iceland
//
//  Created by ian luo on 2018/11/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage

extension UIImage {
    public static func create(with color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        
        var image: UIImage?
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
}
