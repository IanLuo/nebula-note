//
//  Autolayout+Shortcuts.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public struct Position: OptionSet {
    public var rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let top: Position = Position(rawValue: 1 << 0)
    public static let left: Position = Position(rawValue: 1 << 1)
    public static let bottom: Position = Position(rawValue: 1 << 2)
    public static let right: Position = Position(rawValue: 1 << 3)
    public static let centerX: Position = Position(rawValue: 1 << 4)
    public static let centerY: Position = Position(rawValue: 1 << 5)
    public static let width: Position = Position(rawValue: 1 << 6)
    public static let height: Position = Position(rawValue: 1 << 7)
    public static let ratio: Position = Position(rawValue: 1 << 8)
    
    public func identifier(for view: UIView) -> String {
        return "\(self) @\(view)"
    }
}

extension UIView {
    public func centerAnchors(position: Position, to view: UIView, constaint: CGFloat = 0, multiplier: CGFloat = 1) {
        if position.contains(Position.centerX) {
            let centerX = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: multiplier, constant: constaint)
            centerX.identifier = Position.centerX.identifier(for: self)
            centerX.isActive = true
            view.addConstraint(centerX)
        }
        
        if position.contains(Position.centerY) {
            let centerY = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: multiplier, constant: constaint)
            centerY.identifier = Position.centerX.identifier(for: self)
            centerY.isActive = true
            view.addConstraint(centerY)
        }
    }
    
    public func allSidesAnchors(to view: UIView, edgeInsets: UIEdgeInsets) {
        self.sideAnchor(for: [.left, .top, .right, .bottom], to: view, edgeInsets: edgeInsets)
    }
    
    public func allSidesAnchors(to view: UIView, edgeInset: CGFloat) {
        self.sideAnchor(for: [.left, .top, .right, .bottom], to: view, edgeInset: edgeInset)
    }
    
    public func sizeAnchor(width: CGFloat? = nil, height: CGFloat? = nil) {
        if let width = width {
            let width = self.widthAnchor.constraint(equalToConstant: width)
            width.identifier = Position.width.identifier(for: self)
            width.isActive = true
        }
        
        if let height = height {
            let height = self.heightAnchor.constraint(equalToConstant: height)
            height.identifier = Position.height.identifier(for: self)
            height.isActive = true
        }
    }
    
    public func sideAnchor(for position: Position, to view: UIView, edgeInset: CGFloat) {
        self.sideAnchor(for: position, to: view, edgeInsets: UIEdgeInsets(top: edgeInset, left: edgeInset, bottom: -edgeInset, right: -edgeInset))
    }
    
    public func ratioAnchor(_ ratio: CGFloat) {
        let width = self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: ratio)
        width.identifier = Position.ratio.identifier(for: self)
        width.isActive = true
    }
    
    public func rowAnchor(view: UIView, space: CGFloat = 0) {
        let right = self.rightAnchor.constraint(equalTo: view.leftAnchor, constant: -space)
        right.identifier = Position.right.identifier(for: self)
        right.isActive = true
    }
    
    public func columnAnchor(view: UIView, space: CGFloat = 0) {
        let bottom = self.bottomAnchor.constraint(equalTo: view.topAnchor, constant: -space)
        bottom.identifier = Position.bottom.identifier(for: self)
        bottom.isActive = true
    }
    
    public func sideAnchor(for position: Position, to view: UIView, edgeInsets: UIEdgeInsets) {
        if position.contains(Position.left) {
            let left = self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: edgeInsets.left)
            left.identifier = Position.left.identifier(for: self)
            left.isActive = true
        }
        
        if position.contains(Position.right) {
            let right = self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: edgeInsets.right)
            right.identifier = Position.right.identifier(for: self)
            right.isActive = true
        }
        
        if position.contains(Position.top) {
            let top = self.topAnchor.constraint(equalTo: view.topAnchor, constant: edgeInsets.top)
            top.identifier = Position.top.identifier(for: self)
            top.isActive = true
        }
        
        if position.contains(Position.bottom) {
            if #available(iOS 11, *) {
                let bottom = self.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: edgeInsets.bottom)
                bottom.identifier = Position.bottom.identifier(for: self)
                bottom.isActive = true
            } else {
                let bottom = self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: edgeInsets.bottom)
                bottom.identifier = Position.bottom.identifier(for: self)
                bottom.isActive = true
            }
        }
    }
    
    public func constraint(for position: Position) -> NSLayoutConstraint? {
        // 先检查父 view
        for case let constraint in self.superview?.constraints ?? []
            where constraint.identifier == position.identifier(for: self)
            && (constraint.firstItem as? UIView) == self {
            return constraint
        }
        
        // 再检查自己
        for case let constraint in self.constraints
            where constraint.identifier == position.identifier(for: self)
                && (constraint.firstItem as? UIView) == self {
                    return constraint
        }
        
        return nil
    }
}

extension Array {
    public func forPair(_ action: (Element, Element) -> Void) {
        guard self.count >= 2 else { return }
        
        for (index, _) in self.enumerated() {
            if index + 1 <= self.count - 1 {
                action(self[index], self[index + 1])
            }
        }
    }
}
