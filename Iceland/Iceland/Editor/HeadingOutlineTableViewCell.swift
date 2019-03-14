//
//  HeadingOutlineTableViewCell.swift
//  Iceland
//
//  Created by ian luo on 2019/1/4.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class HeadingOutlineTableViewCell: UITableViewCell {
    public static let reuseIdentifier: String = "HeadingOutlineTableViewCell"
    
    public let label: UILabel = {
        let tv = UILabel()
        return tv
    }()
    
    public var string: String = "" {
        didSet {
            let prefix = "∙" * (self.level - 1) * 3
            let infix = prefix.count > 0 ? " " : ""
            let labelString = prefix + infix + string
            let attributedString = NSMutableAttributedString(string: labelString)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive,
                                            NSAttributedString.Key.font : InterfaceTheme.Font.subtitle],
                                           range: NSRange(location: 0, length: prefix.count))
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.interactive,
                                            NSAttributedString.Key.font : InterfaceTheme.Font.subtitle],
                                           range: NSRange(location: prefix.count, length: labelString.count - prefix.count))
            
            self.label.attributedText = attributedString
        }
    }
    
    public var level: Int = 0
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.backgroundColor = InterfaceTheme.Color.background2
        self.label.font = InterfaceTheme.Font.subtitle
        self.label.textColor = InterfaceTheme.Color.interactive
        
        self.contentView.addSubview(self.label)
        
        self.label.translatesAutoresizingMaskIntoConstraints = false
        
        self.label.allSidesAnchors(to: self.contentView, edgeInsets: .zero)
        
        self.label.constraint(for: .left)?.constant = 40
        self.label.constraint(for: .right)?.constant = -40
    }
}

fileprivate func *(lhs: String, rhs: Int) -> String {
    guard rhs > 0 else { return "" }
    var s = lhs
    for _ in 1..<rhs {
        s.append(lhs)
    }
    
    return s
}
