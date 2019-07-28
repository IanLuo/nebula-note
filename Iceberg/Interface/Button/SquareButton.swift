//
//  SquareButton.swift
//  Business
//
//  Created by ian luo on 2019/1/31.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class SquareButton: UIButton {
    public var title: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.interactive
        return label
    }()
    
    public var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = InterfaceTheme.Color.descriptive
        return imageView
    }()
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupUI()
    }
    
    private func setupUI() {
        self.addSubview(self.title)
        self.addSubview(self.icon)
        
        self.title.sideAnchor(for: [.left, .top, .bottom], to: self, edgeInsets: .init(top: 15, left: 30, bottom: -15, right: 0))
        self.icon.sideAnchor(for: [.top, .bottom, .right], to: self, edgeInsets: .init(top: 15, left: 0, bottom: -15, right: -30))
    }
}
