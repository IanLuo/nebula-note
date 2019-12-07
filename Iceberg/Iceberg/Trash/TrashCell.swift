//
//  TrashCell.swift
//  Iceberg
//
//  Created by ian luo on 2019/12/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public class TrashCell: UITableViewCell {
    public static let reuseIdentifier = "TrashCell"
    
//    public let nameLabel: UILabel = {
//        let label = LabelStyle.title.create()
//        label.numberOfLines = 0
//        return label
//    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
//        self.contentView.addSubview(self.nameLabel)
        
//        self.nameLabel.allSidesAnchors(to: self.contentView, edgeInsets: Layout.edgeInsets)
//        self.nameLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        
        self.interface { (me, theme) in
            let cell = me as! TrashCell
            
            cell.contentView.backgroundColor = theme.color.background1
            cell.backgroundColor = theme.color.background1
            cell.tintColor = theme.color.interactive
            cell.textLabel?.textColor = theme.color.interactive
//            cell.nameLabel.textColor = theme.color.interactive
        }
    }
    
    public func configureCell(cellModel: TrashCellModel) {
        self.textLabel?.text = cellModel.name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
