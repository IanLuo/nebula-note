//
//  SearchTableCell.swift
//  Iceland
//
//  Created by ian luo on 2019/1/22.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public class SearchTableCell: UITableViewCell {
    public static let reuseIdentifier = "SearchTableCell"
    
    public var cellModel: SearchTabelCellModel? {
        didSet {
            guard let cellModel = cellModel else { return }
            self.updateUI(cellModel: cellModel)
        }
    }
    
    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.footnote
        
        label.interface { (view, theme) in
            let label = view as! UILabel
            label.textColor = theme.color.descriptive
        }
        return label
    }()
    
    private let foundTextLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.body
        label.numberOfLines = 0
        label.interface { (view, theme) in
            let label = view as! UILabel
            label.textColor = theme.color.interactive
        }
        return label
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.fileNameLabel)
        self.contentView.addSubview(self.foundTextLabel)
        
        self.enableHover(on: self.contentView, hoverColor: InterfaceTheme.Color.background3)
        
        self.fileNameLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 10, left: 30, bottom: 0, right: -30))
        self.fileNameLabel.columnAnchor(view: self.foundTextLabel, space: 10)
        self.foundTextLabel.sideAnchor(for: [.left, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 30, bottom: -20, right: -30))
    }
    
    private func updateUI(cellModel: SearchTabelCellModel) {
        self.fileNameLabel.text = cellModel.fileName

        let attributedString = NSMutableAttributedString(string: cellModel.textString)
        attributedString.addAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.spotlight], range: cellModel.hilightRange)
        self.foundTextLabel.attributedText = attributedString
    }
    
    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = InterfaceTheme.Color.background2
        } else {
            self.backgroundColor = InterfaceTheme.Color.background1
        }
    }
    
    override public func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.backgroundColor = InterfaceTheme.Color.background2
        } else {
            self.backgroundColor = InterfaceTheme.Color.background1
        }
    }
}

