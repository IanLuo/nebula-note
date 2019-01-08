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
    private let button: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = InterfaceTheme.Font.subTitle
        button.setTitleColor(InterfaceTheme.Color.descriptive, for: .normal)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.subTitle
        label.textColor = InterfaceTheme.Color.descriptive
        return label
    }()
    
    public func setTitle(_ title: String?) {
        self.titleLabel.text = title
        self.updateUI()
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
    
    public init() {
        super.init(frame: .zero)
        self.setupUI()
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
        
        self.button.sideAnchor(for: [.top, .left, .right], to: self, edgeInsets: .zero)
        self.button.ratioAnchor(1)
        self.button.sideAnchor(for: .bottom, to: self.titleLabel, edgeInset: 5)
        
        self.titleLabel.sideAnchor(for: [.left, .right, .bottom], to: self, edgeInsets: .zero)
        
        self.setBackgroundColor(InterfaceTheme.Color.background1, for: .normal)
        self.setBorder(color: InterfaceTheme.Color.background2)
    }
    
    private func updateUI() {
        self.titleLabel.isHidden = self.titleLabel.text?.count == 0
    }
}
