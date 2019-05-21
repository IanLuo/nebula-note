//
//  RoundButton.swift
//  Business
//
//  Created by ian luo on 2019/1/8.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class RoundButton: UIView {
    public enum Style {
        case verticle // default
        case horizontal
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        button.layer.cornerRadius = button.bounds.width / 2
    }
    
    public let style: Style
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.layer.masksToBounds = true
        button.titleLabel?.font = InterfaceTheme.Font.subtitle
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        button.addTarget(self, action: #selector(tapped_), for: .touchUpInside)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.subtitle
        label.textColor = InterfaceTheme.Color.descriptive
        label.textAlignment = .center
        return label
    }()
    
    public var title: String? {
        set {
            self.titleLabel.text = newValue
            self.updateUI()
        }
        
        get {
            return self.titleLabel.text
        }
    }
    
    public var isEnabled: Bool {
        get { return self.button.isEnabled }
        set { self.button.isEnabled = newValue }
    }
    
    public func setBorder(color: UIColor?) {
        if let color = color {
            self.button.layer.borderWidth = 1
            self.button.layer.borderColor = color.cgColor
        } else {
            self.button.layer.borderWidth = 0
        }
    }
    
    public func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        self.button.setBackgroundImage(UIImage.create(with: color, size: .singlePoint), for: state)
    }
    
    public func setIcon(_ image: UIImage?, for state: UIControl.State) {
        self.button.setImage(image, for: state)
    }
    
    @objc public func tapped(_ action: @escaping (RoundButton) -> Void) {
        self.tappedAction = action
    }
    
    private var tappedAction: ((RoundButton) -> Void)?
    @objc private func tapped_() {
        self.tappedAction?(self)
    }
    
    public init(style: Style = .verticle) {
        self.style = style
        super.init(frame: .zero)
        self.setupUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(tap:)))
        self.addGestureRecognizer(tap)
    }
    
    @objc private func tapped(tap: UITapGestureRecognizer) {
        switch tap.state {
        case .began:
            self.button.isHighlighted = true
        case .cancelled:
            self.button.isHighlighted = false
        case .failed:
            self.button.isHighlighted = false
        case .changed:
            self.button.isHighlighted = true
        case .ended:
            self.button.isHighlighted = false
            self.tappedAction?(self)
        case .possible:
            break
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func tintColorDidChange() {
        self.button.tintColor = self.tintColor
        self.titleLabel.textColor = self.tintColor
    }
    
    private func setupUI() {
        self.addSubview(self.button)
        self.addSubview(self.titleLabel)
        
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.button.ratioAnchor(1)
        
        switch self.style {
        case .verticle:
            self.button.sideAnchor(for: [.top, .left, .right], to: self, edgeInset: 0)
            self.button.columnAnchor(view: self.titleLabel, space: 5)
            
            self.titleLabel.sideAnchor(for: .bottom, to: self, edgeInset: 0)
            self.titleLabel.centerAnchors(position: .centerX, to: self)
        case .horizontal:
            self.button.sideAnchor(for: [.top, .left, .bottom], to: self, edgeInset: 10)
            self.button.rowAnchor(view: self.titleLabel, space: 15)
            
            self.titleLabel.sideAnchor(for: .right, to: self, edgeInset: 10)
            self.titleLabel.centerAnchors(position: .centerY, to: self)
        }
        
        self.titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        self.button.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.horizontal)
        self.button.setContentHuggingPriority(UILayoutPriority.required, for: NSLayoutConstraint.Axis.vertical)
        
        self.setBackgroundColor(InterfaceTheme.Color.background1, for: .normal)
        
        // default border color
        self.setBorder(color: nil)
    }
    
    private func updateUI() {
        self.titleLabel.isHidden = self.titleLabel.text?.count == 0
    }
}
