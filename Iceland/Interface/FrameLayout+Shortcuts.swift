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
    
    public var topRightCorner: CGPoint {
        return CGPoint(x: self.origin.x + self.width, y: self.origin.y)
    }
    
    public var bottomLeftCorner: CGPoint {
        return CGPoint(x: self.origin.x, y: self.maxY)
    }
    
    public var topLeftCorner: CGPoint {
        return self.origin
    }
    
    public var middleLeft: CGPoint {
        return CGPoint(x: self.origin.x, y: self.midY)
    }
    
    public var middleTop: CGPoint {
        return CGPoint(x: self.midX, y: self.origin.y)
    }
    
    public var middleRight: CGPoint{
        return CGPoint(x: self.maxX, y: self.midY)
    }
    
    public var middleBottom: CGPoint {
        return CGPoint(x: self.midX, y: self.maxY)
    }
}

extension CGPoint {
    public func shift(x: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + x, y: self.y)
    }
    
    public func shift(y: CGFloat) -> CGPoint {
        return CGPoint(x: self.x, y: self.y + y)
    }
}

public enum AlignmentPosition {
    case head
    case middle
    case tail
}

public enum AlignmentDirection {
    case left
    case right
    case top
    case bottom
}

extension UIView {
    @discardableResult
    public func fill(view: UIView) -> UIView {
        self.frame = view.bounds
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return self
    }
    
    @discardableResult
    public func align(to view: UIView, direction: AlignmentDirection, position: AlignmentPosition, inset: CGFloat) -> UIView {
        var inset = inset
        if #available (iOS 11.0, *) {
            switch direction {
            case .left: inset += view.safeAreaInsets.left
            case .top: inset += view.safeAreaInsets.top
            case .right: inset += view.safeAreaInsets.right
            case .bottom: inset -= view.safeAreaInsets.bottom
            }
        }
        self.align(to: view.frame, direction: direction, inset: inset)
        return self
    }
    
    @discardableResult
    public func alignToSuperview(direction: AlignmentDirection, inset: CGFloat) -> UIView {
        var inset = inset
        let view = self.superview!
        if #available (iOS 11.0, *) {
            switch direction {
            case .left: inset += view.safeAreaInsets.left
            case .top: inset += view.safeAreaInsets.top
            case .right: inset += view.safeAreaInsets.right
            case .bottom: inset -= view.safeAreaInsets.bottom
            }
        }
        self.align(to: view.bounds, direction: direction, inset: inset)
        return self
    }
    
    @discardableResult
    public func align(to f: CGRect, direction: AlignmentDirection, inset: CGFloat) -> UIView {
        switch direction {
        case .left:
            var frame = self.frame
            frame.origin.x = f.origin.x + inset
            self.frame = frame
        case .right:
            var frame = self.frame
            frame.origin.x = f.middleRight.x - inset - frame.width
            self.frame = frame
        case .top:
            var frame = self.frame
            frame.origin.y = f.origin.y + inset
            self.frame = frame
        case .bottom:
            var frame = self.frame
            frame.origin.y = f.bottomLeftCorner.y - inset - frame.height
            self.frame = frame
        }

        return self
    }

    public var safeArea: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
    
    @discardableResult
    public func size(width: CGFloat? = nil, height: CGFloat? = nil) -> UIView {
        var frame = self.frame
        if let width = width {
            frame.size.width = width
        }
        
        if let height = height {
            frame.size.height = height
        }
        
        self.frame = frame
        
        return self
    }
    
    @discardableResult
    public func centerX(to view: UIView, multiplier: CGFloat) -> UIView {
        var frame = self.frame
        let toCenter = view.center
        frame.origin.x = (toCenter.x - frame.width / 2) / multiplier
        self.frame = frame
        
        return self
    }
    
    @discardableResult
    public func centerY(to view: UIView, multiplier: CGFloat) -> UIView {
        var frame = self.frame
        let toCenter = view.center
        frame.origin.y = (toCenter.y - frame.height / 2) / multiplier
        self.frame = frame
        
        return self
    }
}

extension UIViewController {
    public var navigationBarBottomToStatusBarTop: CGFloat {
        return (self.navigationController?.navigationBar.frame.height ?? 0) + UIApplication.shared.statusBarFrame.height
    }
}
