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
    
    @objc public func fill(color: UIColor) -> UIImage {
        var image: UIImage!
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { fatalError("no image context") }
        context.setFillColor(color.cgColor)
        self.withRenderingMode(UIImage.RenderingMode.alwaysTemplate).draw(at: .zero)
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    @objc public func resize(upto: CGSize) -> UIImage {
        if self.size.width * self.scale <= upto.width
            && self.size.height * self.scale <= upto.height {
            return self
        }
        
        let newSize = self.size.aspectFitSizeScale(for: upto)
        
        var image: UIImage!
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        
        self.draw(in: CGRect(origin: .zero, size: newSize))
        
        image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @objc public func translation(offset: CGPoint) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width + offset.x, height: size.height + offset.y), false, 0)
        draw(at: offset)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    @objc public func insets(_ insects: UIEdgeInsets) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(x: insects.left, y: insects.top, width: self.size.width - insects.left - insects.right, height: self.size.height - insects.top -  insects.bottom))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    public func addSubImage(_ image: UIImage) -> UIImage {
        var newImage: UIImage!
        
        let newSize = CGSize(width: max(image.size.width, self.size.width), height: max(image.size.height, self.size.height))
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        
        self.draw(in: CGRect(origin: CGPoint(x: (newSize.width - self.size.width) / 2, y: (newSize.height - self.size.height) / 2), size: size))

        image.draw(in: CGRect(origin: CGPoint(x: (newSize.width - image.size.width) / 2, y: (newSize.height - image.size.height) / 2), size: image.size), blendMode: CGBlendMode.normal, alpha: 1)
        
        newImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        
        return newImage
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
