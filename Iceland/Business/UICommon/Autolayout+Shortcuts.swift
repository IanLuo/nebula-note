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
    
    public func identifier(for view: UIView) -> String {
        return "\(self) @\(view)"
    }
}

extension UIView {
    public func centerAnchors(position: Position, to view: UIView, offset: CGFloat = 0) {
        if position.contains(Position.centerX) {
            let left = self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
            left.identifier = Position.centerX.identifier(for: self)
            left.isActive = true
        }
        
        if position.contains(Position.centerY) {
            let left = self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset)
            left.identifier = Position.centerY.identifier(for: self)
            left.isActive = true
        }
    }
    
    public func allSidesAnchors(to view: UIView, edgeInsets: UIEdgeInsets) {
        self.sideAnchor(for: [.left, .top, .right, .bottom], to: view, edgeInsets: edgeInsets)
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
        for case let constraint in self.superview?.constraints ?? []
            where constraint.identifier == position.identifier(for: self)
            && (constraint.firstItem as? UIView) == self {
            return constraint
        }
        
        return nil
    }
}
