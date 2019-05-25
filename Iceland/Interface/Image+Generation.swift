//
//  Image+Generation.swift
//  Iceland
//
//  Created by ian luo on 2018/11/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage

public enum UIImageStyle {
    case squre
    case circle
}

extension UIImage {
    public static func create(with color: UIColor, size: CGSize, style: UIImageStyle = .squre) -> UIImage {
        var isOpaque = true
        switch style {
        case .squre:
            break
        case .circle:
            isOpaque = false
        }
        
        UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0)
        
        var image: UIImage?
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            switch style {
            case .squre:
                context.fill(CGRect(origin: .zero, size: size))
            case .circle:
                context.fillEllipse(in: CGRect(origin: .zero, size: size))
            }
        }
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    public func fill(color: UIColor) -> UIImage {
        var image: UIImage!
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { fatalError("no image context") }
        context.setFillColor(color.cgColor)
        self.withRenderingMode(UIImage.RenderingMode.alwaysTemplate).draw(at: .zero)
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    public func resize(upto: CGSize) -> UIImage {
        let newSize = self.size.aspectFitSizeScale(for: upto)
        
        var image: UIImage!
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        
        self.draw(in: CGRect(origin: .zero, size: newSize))
        
        image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    public func translation(offset: CGPoint) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width + offset.x, height: size.height + offset.y), false, 0)
        draw(at: offset)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

extension UIView {
    public var snapshot: UIImage? {
        var image: UIImage?
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        } else {
            let bitmapBytesPerRow = Int(self.bounds.size.width) * 4 * 8
            let bitmapByteCount = bitmapBytesPerRow * Int(self.bounds.size.height)
            let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
            
            let context = CGContext(data: pixelData,
                                    width: Int(self.bounds.size.width),
                                    height: Int(self.bounds.size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: bitmapBytesPerRow,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!
            self.layer.render(in: context)
            if let cgImage = context.makeImage() {
                image = UIImage(cgImage: cgImage)
            }
        }

        UIGraphicsEndImageContext()
        
        return image
    }
}
