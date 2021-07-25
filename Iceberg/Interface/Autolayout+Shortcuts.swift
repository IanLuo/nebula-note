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
    
    public static let none: Position = Position(rawValue: 0)
    public static let top: Position = Position(rawValue: 1 << 0)
    public static let left: Position = Position(rawValue: 1 << 1)
    public static let bottom: Position = Position(rawValue: 1 << 2)
    public static let right: Position = Position(rawValue: 1 << 3)
    public static let centerX: Position = Position(rawValue: 1 << 4)
    public static let centerY: Position = Position(rawValue: 1 << 5)
    public static let width: Position = Position(rawValue: 1 << 6)
    public static let height: Position = Position(rawValue: 1 << 7)
    public static let ratio: Position = Position(rawValue: 1 << 8)
    public static let widthDependency: Position = Position(rawValue: 1 << 9)
    public static let heightDependency: Position = Position(rawValue: 1 << 10)
    public static let topBaseline: Position = Position(rawValue: 1 << 11)
    public static let bottomBaseline: Position = Position(rawValue: 1 << 12)
    public static let traling: Position = Position(rawValue: 1 << 13)
    public static let leading: Position = Position(rawValue: 1 << 14)
    
    public func identifier(for view: UIView) -> String {
        return "\(self) @\(view.hash)-\(type(of: view))"
    }
}


extension UIView {
    public func makeSureTranslationIsSetToFalse() {
        if self.translatesAutoresizingMaskIntoConstraints == true {
            self.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    @discardableResult
    public func centerAnchors(position: Position, to view: UIView, constant: CGFloat = 0, multiplier: CGFloat = 1) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
        if position.contains(Position.centerX) {
            let centerX = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: multiplier, constant: constant)
            centerX.identifier = Position.centerX.identifier(for: self)
            centerX.isActive = true
            view.addConstraint(centerX)
        }
        
        if position.contains(Position.centerY) {
            let centerY = NSLayoutConstraint(item: self, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: multiplier, constant: constant)
            centerY.identifier = Position.centerY.identifier(for: self)
            centerY.isActive = true
            view.addConstraint(centerY)
        }
        
        return self
    }
    
    @discardableResult
    public func allSidesAnchors(to view: UIView, edgeInsets: UIEdgeInsets, considerSafeArea: Bool = false) -> Self {
        self.sideAnchor(for: [.left, .top, .right, .bottom], to: view, edgeInsets: edgeInsets, considerSafeArea: considerSafeArea)
        return self
    }
    
    @discardableResult
    public func allSidesAnchors(to view: UIView, edgeInset: CGFloat, considerSafeArea: Bool = false) -> Self {
        self.sideAnchor(for: [.left, .top, .right, .bottom], to: view, edgeInset: edgeInset, considerSafeArea: considerSafeArea)
        
        return self
    }
    
    @discardableResult
    public func sizeEqualAnchor(position: Position, dimention: NSLayoutDimension?) -> Self {
        if position.contains(.width) {
            let dimention = dimention ?? self.superview!.widthAnchor
            let width = self.widthAnchor.constraint(equalTo: dimention)
            width.identifier = Position.width.identifier(for: self)
            width.isActive = true
        }
        
        if position.contains(.height) {
            let dimention = dimention ?? self.superview!.heightAnchor
            let width = self.heightAnchor.constraint(equalTo: dimention)
            width.identifier = Position.height.identifier(for: self)
            width.isActive = true
        }
        
        return self
    }
    
    @discardableResult
    public func sizeAnchor(width: CGFloat? = nil, height: CGFloat? = nil) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
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
        
        return self
    }
    
    @discardableResult
    public func sideAnchor(for position: Position, to view: UIView, edgeInset: CGFloat, considerSafeArea: Bool = false) -> Self {
        self.sideAnchor(for: position, to: view, edgeInsets: UIEdgeInsets(top: edgeInset, left: edgeInset, bottom: -edgeInset, right: -edgeInset), considerSafeArea: considerSafeArea)
        
        return self
    }
    
    @discardableResult
    public func ratioAnchor(_ ratio: CGFloat) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
        let width = self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: ratio)
        width.identifier = Position.ratio.identifier(for: self)
        width.isActive = true
        
        return self
    }
    
    
    @discardableResult
    public func rowAnchor(view: UIView, space: CGFloat = 0, widthRatio: CGFloat? = nil, alignment: Position = .centerY) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
        let right = self.rightAnchor.constraint(equalTo: view.leftAnchor, constant: -space)
        right.identifier = Position.right.identifier(for: self)
        right.isActive = true
        
        var constraint: NSLayoutConstraint?
        if alignment.contains(.centerY) {
            constraint = view.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        } else if alignment.contains(.top) {
            constraint = view.topAnchor.constraint(equalTo: self.topAnchor)
        } else if alignment.contains(.bottom) {
            constraint = view.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        } else if alignment.contains(.topBaseline) {
            constraint = view.firstBaselineAnchor.constraint(equalTo: self.firstBaselineAnchor)
        } else if alignment.contains(.bottomBaseline) {
            constraint = view.lastBaselineAnchor.constraint(equalTo: self.lastBaselineAnchor)
        }
        
        constraint?.identifier = alignment.identifier(for: view)
        constraint?.isActive = true
        
        if let widthRatio = widthRatio {
            self.widthDependencyAnchor(view: view, widthRatio: widthRatio)
        }
        
        return self
    }
    
    @discardableResult
    public func columnAnchor(view: UIView, space: CGFloat = 0, heightRatio: CGFloat? = nil, alignment: Position = .leading) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
        let bottom = self.bottomAnchor.constraint(equalTo: view.topAnchor, constant: -space)
        bottom.identifier = Position.bottom.identifier(for: self)
        bottom.isActive = true
        
        var constraint: NSLayoutConstraint?
        if alignment.contains(.centerX) {
            constraint = view.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        } else if alignment.contains(.left) {
            constraint = view.leftAnchor.constraint(equalTo: self.leftAnchor)
        } else if alignment.contains(.right) {
            constraint = view.rightAnchor.constraint(equalTo: self.rightAnchor)
        } else if alignment.contains(.traling) {
            constraint = view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        } else if alignment.contains(.leading) {
            constraint = view.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        }
        
        constraint?.identifier = alignment.identifier(for: view)
        constraint?.isActive = true
                
        if let heightRatio = heightRatio {
            self.heightDependencyAnchor(view: view, heightRatio: heightRatio)
        }
        
        return self
    }
    
    @discardableResult
    public func widthDependencyAnchor(view: UIView, widthRatio: CGFloat) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
        let widthDependency = self.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: widthRatio)
        widthDependency.identifier = Position.widthDependency.identifier(for: self)
        widthDependency.isActive = true
        
        return self
    }
    
    @discardableResult
    public func heightDependencyAnchor(view: UIView, heightRatio: CGFloat) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
        let heightDependency = self.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: heightRatio)
        heightDependency.identifier = Position.widthDependency.identifier(for: self)
        heightDependency.isActive = true
        
        return self
    }
    
    @discardableResult
    public func sideAnchor(for position: Position, to view: UIView, edgeInsets: UIEdgeInsets, considerSafeArea: Bool = false) -> Self {
        self.makeSureTranslationIsSetToFalse()
        
        if position.contains(Position.left) {
            if #available(iOS 11, *), considerSafeArea {
                let left = self.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: edgeInsets.left)
                left.identifier = Position.left.identifier(for: self)
                left.isActive = true
            } else {
                let left = self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edgeInsets.left)
                left.identifier = Position.left.identifier(for: self)
                left.isActive = true
            }
        }
        
        if position.contains(Position.right) {
            if #available(iOS 11, *), considerSafeArea {
                let right = self.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: edgeInsets.right)
                right.identifier = Position.right.identifier(for: self)
                right.isActive = true
            } else {
                let right = self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: edgeInsets.right)
                right.identifier = Position.right.identifier(for: self)
                right.isActive = true
            }
        }
        
        if position.contains(Position.top) {
            if #available(iOS 11, *), considerSafeArea {
                let top = self.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: edgeInsets.top)
                top.identifier = Position.top.identifier(for: self)
                top.isActive = true
            } else {
                let top = self.topAnchor.constraint(equalTo: view.topAnchor, constant: edgeInsets.top)
                top.identifier = Position.top.identifier(for: self)
                top.isActive = true
            }
        }
        
        if position.contains(Position.bottom) {
            if #available(iOS 11, *), considerSafeArea {
                let bottom = self.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: edgeInsets.bottom)
                bottom.identifier = Position.bottom.identifier(for: self)
                bottom.isActive = true
            } else {
                let bottom = self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: edgeInsets.bottom)
                bottom.identifier = Position.bottom.identifier(for: self)
                bottom.isActive = true
            }
        }
        
        if position.contains(Position.leading) {
            if #available(iOS 11, *), considerSafeArea {
                let bottom = self.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: edgeInsets.left)
                bottom.identifier = Position.leading.identifier(for: self)
                bottom.isActive = true
            } else {
                let bottom = self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edgeInsets.left)
                bottom.identifier = Position.leading.identifier(for: self)
                bottom.isActive = true
            }
        }
        
        if position.contains(Position.traling) {
            if #available(iOS 11, *), considerSafeArea {
                let bottom = self.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: edgeInsets.right)
                bottom.identifier = Position.traling.identifier(for: self)
                bottom.isActive = true
            } else {
                let bottom = self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: edgeInsets.right)
                bottom.identifier = Position.traling.identifier(for: self)
                bottom.isActive = true
            }
        }
        
        return self
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
        
        for (index, item) in self.enumerated() {
            if index + 1 <= self.count - 1 {
                action(item, self[index + 1])
            }
        }
    }
}
