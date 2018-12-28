//
//  AgendaTableCell.swift
//  Iceland
//
//  Created by ian luo on 2018/12/27.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol AgendaTableCellDelegate: class {
    
}

public class AgendaTableCell: UITableViewCell {
    public static let reuseIdentifier = "AgendaTableCell"
    
    public weak var delegate: AgendaTableCellDelegate?
    
    public var cellModel: AgendaCellModel? {
        didSet {
            self.setupUI()
        }
    }
    
    public init() {
        super.init(style: .default, reuseIdentifier: AgendaTableCell.reuseIdentifier)
    }
    
    private func setupUI() {
        // TODO:
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

