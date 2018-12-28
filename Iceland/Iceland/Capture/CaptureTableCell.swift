//
//  CaptureTableCell.swift
//  Iceland
//
//  Created by ian luo on 2018/12/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol CaptureTableCellDelegate: class {
    func didTapDelete(cell: CaptureTableCell)
    func didTapRefile(cell: CaptureTableCell)
}

public class CaptureTableCell: UITableViewCell {
    public weak var delegate: CaptureTableCellDelegate?
    public var attachment: Attachment? {
        didSet {
            self.setupUI()
        }
    }
    
    private func setupUI() {
        // TODO:
    }
    
    private func showActions(animated: Bool) {
        // TODO:
    }
    
    private func hideActions(animated: Bool) {
        // TODO
    }
    
    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if self.isSelected {
            self.showActions(animated: animated)
        } else {
            self.hideActions(animated: animated)
        }
    }
}
