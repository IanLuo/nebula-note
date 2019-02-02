//
//  HeadingCell.swift
//  Iceland
//
//  Created by ian luo on 2019/2/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class HeadingCell: UITableViewCell {
    public static let reuseIdentifier: String = "HeadingCell"
    
    public var cellModel: AgendaCellModel? {
        didSet {
            guard let cellModel = cellModel else { return }
            
            self.updateUI(cellModel: cellModel)
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
    }
    
    private func updateUI(cellModel: AgendaCellModel) {
        
    }
}
