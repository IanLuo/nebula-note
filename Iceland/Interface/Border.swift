//
//  Line.swift
//  UI
//
//  Created by ian luo on 2017/7/26.
//  Copyright © 2017年 wod. All rights reserved.
//

import Foundation
import UIKit.UIView

public class Border: UIView {
    public struct Position: OptionSet {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public let rawValue: Int
        public static let top = Position(rawValue: 1 << 0)
        public static let left = Position(rawValue: 1 << 1)
        public static let right = Position(rawValue: 1 << 2)
        public static let bottom = Position(rawValue: 1 << 3)
        public static let centerH = Position(rawValue: 1 << 4)
        public static let centerV = Position(rawValue: 1 << 5)
    }
    
    public enum Style {
        case solid
        case dash(CGFloat, CGFloat)
    }
    
    public enum Insect {
        case none
        case head(CGFloat)
        case tail(CGFloat)
        case both(CGFloat)
    }
    
    public enum Direction {
        case horizontal
        case vertical
    }

    public var style: Style?
    public var lineColor: UIColor?
    public var direction: Direction?
    
    public convenience init(style: Style, direction: Direction = .horizontal) {
        self.init(frame: CGRect.zero)
        self.style = style
        self.direction = direction
        backgroundColor = UIColor.clear
    }
    
    override public func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext(), let color = lineColor {
            context.clear(rect)
            context.setStrokeColor(color.cgColor)
        }
        
        if let style = style {
            let path = UIBezierPath()
            switch style {
            case .solid:
                break
            case .dash(let width1, let width2):
                var dashes: [CGFloat] = [width1, width2]
                path.setLineDash(&dashes, count: dashes.count, phase: 0)
            }
            
            switch direction! {
            case .horizontal:
                path.lineWidth = bounds.height
                path.move(to: CGPoint(x: 0, y: rect.height / 2))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            case .vertical:
                path.lineWidth = bounds.width
                path.move(to: CGPoint(x: rect.width / 2, y: 0))
                path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
            }
            path.stroke()
        }
    }
}

extension UIView {
    public func setBorder(position: Border.Position, style: Border.Style = .solid, color: UIColor, width: CGFloat, insets: Border.Insect = .none) {
        removeBorders()
        
        var insectHead: CGFloat = 0
        var insectTail: CGFloat = 0
        let width: CGFloat = width
        
        switch insets {
        case .both(let bothInsect):
            insectHead = bothInsect
            insectTail = bothInsect
        case .head(let headInsect):
            insectHead = headInsect
        case .tail(let tailInsect):
            insectTail = tailInsect
        case .none: break
        }
        
        let metrics = ["w": width, "h": insectHead, "t": insectTail]
        
        if position.contains(.top) {
            let border = Border(style: style)
            addSubview(border)
            border.translatesAutoresizingMaskIntoConstraints = false
            border.lineColor = color
            addConstraint(NSLayoutConstraint(item: border, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: border, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-h-[b]-t-|", options: [], metrics: metrics, views: ["b" : border]))
        }
        if position.contains(.left) {
            let border = Border(style: style, direction: .vertical)
            addSubview(border)
            border.translatesAutoresizingMaskIntoConstraints = false
            border.lineColor = color
            addConstraint(NSLayoutConstraint(item: border, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: border, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-h-[b]-t-|", options: [], metrics: metrics, views: ["b" : border]))
        }
        if position.contains(.right) {
            let border = Border(style: style, direction: .vertical)
            addSubview(border)
            border.translatesAutoresizingMaskIntoConstraints = false
            border.lineColor = color
            addConstraint(NSLayoutConstraint(item: border, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: border, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-h-[b]-t-|", options: [], metrics: metrics, views: ["b" : border]))
        }
        if position.contains(.bottom) {
            let border = Border(style: style)
            addSubview(border)
            border.translatesAutoresizingMaskIntoConstraints = false
            border.lineColor = color
            addConstraint(NSLayoutConstraint(item: border, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: border, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-h-[b]-t-|", options: [], metrics: metrics, views: ["b" : border]))
        }
        
        if position.contains(.centerH) {
            let border = Border(style: style)
            addSubview(border)
            border.translatesAutoresizingMaskIntoConstraints = false
            border.lineColor = color
            addConstraint(NSLayoutConstraint(item: border, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: border, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-h-[b]-t-|", options: [], metrics: metrics, views: ["b" : border]))
        }
        
        if position.contains(.centerV) {
            let border = Border(style: style, direction: .vertical)
            addSubview(border)
            border.translatesAutoresizingMaskIntoConstraints = false
            border.lineColor = color
            addConstraint(NSLayoutConstraint(item: border, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
            addConstraint(NSLayoutConstraint(item: border, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-h-[b]-t-|", options: [], metrics: metrics, views: ["b" : border]))
        }
    }
    
    public func removeBorders() {
        subviews.forEach {
            if let border = $0 as? Border {
                border.removeFromSuperview()
            }
        }
    }
}
