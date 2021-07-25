//
//  UIView+Convenience.swift
//  Interface
//
//  Created by ian luo on 2020/7/18.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

public class Padding: UIView {
    public init(child: UIView, all: CGFloat) {
        super.init(frame: .zero)
        self.addSubview(child)
        child.allSidesAnchors(to: self, edgeInset: all)
    }
    
    public init(child: UIView, insets: UIEdgeInsets) {
        super.init(frame: .zero)
        self.addSubview(child)
        child.allSidesAnchors(to: self, edgeInsets: insets)
    }
    
    public init(child: UIView, horizontal: CGFloat = 0, vertical: CGFloat = 0) {
        super.init(frame: .zero)
        self.addSubview(child)
        child.allSidesAnchors(to: self, edgeInsets: UIEdgeInsets(top: vertical, left: horizontal, bottom: -vertical, right: -horizontal))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init() {
        super.init(frame: .zero)
    }
    
    public func childBuilder<T>(bindTo: Observable<T>, all: CGFloat, builder: @escaping (T) -> UIView) -> Self {
        _ = bindTo.take(until: self.rx.deallocated).subscribe(onNext: {
            let newChild = builder($0)
            self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(newChild)
            newChild.allSidesAnchors(to: self, edgeInset: all)
        })
        
        return self
    }
    
    public func childBuilder<T>(bindTo: Observable<T>, insets: UIEdgeInsets, builder: @escaping (T) -> UIView) -> Self {
        _ = bindTo.take(until: self.rx.deallocated).subscribe(onNext: {
            let newChild = builder($0)
            self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(newChild)
            newChild.allSidesAnchors(to: self, edgeInsets: insets)
        })
        
        return self
    }
    
    public func childBuilder<T>(bindTo: Observable<T>, horizontal: CGFloat = 0, vertical: CGFloat = 0, builder: @escaping (T) -> UIView) -> Self {
        _ = bindTo.take(until: self.rx.deallocated).subscribe(onNext: {
            let newChild = builder($0)
            self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(newChild)
            newChild.allSidesAnchors(to: self, edgeInsets: UIEdgeInsets(top: vertical, left: horizontal, bottom: -vertical, right: -horizontal))
        })
        
        return self
    }
}

public enum SubViewPosition {
    case equalToSuper
    case center
    case padding(UIEdgeInsets)
}

public extension UIView {
    func childBuilder<T>(topView: UIView? = nil, bindTo: Observable<T>, position: SubViewPosition = .equalToSuper, builder: @escaping (T) -> UIView) -> Self {
        _ = bindTo.take(until: self.rx.deallocated).subscribe(onNext: { [weak topView] in
            let newChild = builder($0)
            self.subviews.forEach { $0.removeFromSuperview() }
            self.addSubview(newChild)
            
            switch position {
            case .equalToSuper:
                newChild.allSidesAnchors(to: self, edgeInset: 0)
            case .center:
                newChild.centerAnchors(position: [.centerX, .centerY], to: self)
            case .padding(let edgeInsets):
                newChild.allSidesAnchors(to: self, edgeInsets: edgeInsets)
            }
            
            topView?.setNeedsLayout()
            topView?.layoutIfNeeded()
        })
        
        return self
    }
    
    func isHidden(observe: Observable<Bool>) -> Self {
        _ = observe.take(until: self.rx.deallocated).observe(on: MainScheduler()).subscribe(onNext: {
            self.isHidden = $0
        })
        return self
    }
    
    convenience init(child: UIView) {
        self.init(frame: .zero)
        self.addSubview(child)
        child.allSidesAnchors(to: self, edgeInset: 0)
    }
    
    @discardableResult
    func contentMode(_ mode: UIView.ContentMode) -> Self {
        self.contentMode = mode
        return self
    }
    
    @discardableResult
    func backgroundColor(_ color: UIColor) -> Self {
        self.backgroundColor = color
        return self
    }
    
    @discardableResult
    func roundConer(radius: CGFloat, corners: CACornerMask = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]) -> Self {
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = corners
        self.layer.masksToBounds = true
        return self
    }
    
    @discardableResult
    func border(color: UIColor, width: CGFloat) -> Self {
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
        return self
    }
    
    @discardableResult
    func tapGesture(_ tapped: @escaping (Self) -> Void) -> Self {
        let gesture = UITapGestureRecognizer()
        _ = gesture.rx.event.take(until: self.rx.deallocated).subscribe(onNext: { [unowned self] in
            if $0.state == .ended {
                tapped(self)
            }
        })
        self.enableHover(on: self)
        self.addGestureRecognizer(gesture)
        return self
    }
}

public extension UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
    }
    
    @discardableResult
    func font(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
    
    @discardableResult
    func textColor(_ color: UIColor) -> Self {
        self.textColor = color
        return self
    }
    
    @discardableResult
    func numberOfLines(_ number: Int) -> Self {
        self.numberOfLines = number
        return self
    }
    
    @discardableResult
    func textAlignment(_ alignment: NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
}

public extension UIButton {
    @discardableResult
    convenience init(title: String, `for`: UIControl.State) {
        self.init()
        self.title(title, for: `for`)
    }
    
    @discardableResult
    func title(_ title: String, `for` state: UIControl.State) -> UIButton {
        self.setTitle(title, for: state)
        return self
    }
    
    @discardableResult
    func titleColor(_ color: UIColor, `for` state: UIControl.State) -> UIButton {
        self.setTitleColor(color, for: state)
        return self
    }
    
    @discardableResult
    func backgroundImage(_ color: UIColor, `for` state: UIControl.State) -> Self {
        self.setBackgroundImage(UIImage.create(with: color, size: .singlePoint), for: state)
        return self
    }
  
    @discardableResult
    func image(_ image: UIImage, `for` state: UIControl.State) -> Self {
        self.setImage(image, for: state)
        return self
    }
    
    @discardableResult
    func contentEdgeInsets(_ insets: UIEdgeInsets) -> Self {
        self.contentEdgeInsets = insets
        return self
    }
    
    @discardableResult
    func titleFont(_ font: UIFont) -> Self {
        self.titleLabel?.font = font
        return self
    }
 }


public extension UIStackView {
    convenience init(subviews: [UIView],
                     axis: NSLayoutConstraint.Axis = .horizontal,
                     distribution: Distribution = .equalCentering,
                     alignment: Alignment = .center,
                     spacing: CGFloat = 0) {
        self.init(arrangedSubviews: subviews)
        
        self.distribution = distribution
        self.axis = axis
        self.alignment = alignment
        self.spacing = spacing
    }
}
