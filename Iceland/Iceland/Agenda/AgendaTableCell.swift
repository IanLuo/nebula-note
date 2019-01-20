//
//  AgendaTableCell.swift
//  Iceland
//
//  Created by ian luo on 2018/12/27.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol AgendaTableCellDelegate: class {
    
}

public class AgendaTableCell: UITableViewCell {
    public static let reuseIdentifier = "AgendaTableCell"
    
    public weak var delegate: AgendaTableCellDelegate?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .center
        return label
    }()
    
    private let infoView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let documentNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        return label
    }()
    
    private let headingContentLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.interactive
        label.font = InterfaceTheme.Font.footnote
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()
    
    private let tagsView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let tagsIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "tag.png")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        imageView.tintColor = InterfaceTheme.Color.descriptive
        return imageView
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.textAlignment = .left
        label.font = InterfaceTheme.Font.footnote
        return label
    }()
    
    private let scheduleAndDueLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        return label
    }()
    
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
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background1
        self.contentView.addSubview(self.statusLabel)
        self.statusLabel.centerAnchors(position: .centerY, to: self.contentView)
        self.statusLabel.sizeAnchor(width: 120)
        
        self.contentView.addSubview(self.infoView)
        self.infoView.sideAnchor(for: [.left, .top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 120, bottom: 0, right: 0))
        
        self.infoView.addSubview(self.documentNameLabel)
        self.infoView.addSubview(self.headingContentLabel)
        self.infoView.addSubview(self.tagsView)
        self.infoView.addSubview(self.scheduleAndDueLabel)
        
        self.documentNameLabel.sideAnchor(for: [.left, .top, .right], to: self.infoView, edgeInsets: .init(top: 20, left: 0, bottom: 0, right: -30))
        self.documentNameLabel.columnAnchor(view: self.headingContentLabel, space: 10)

        self.headingContentLabel.sideAnchor(for: [.left, .right], to: self.infoView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -30))
        self.headingContentLabel.columnAnchor(view: self.tagsView)
        
        self.tagsView.sideAnchor(for: [.left, .right], to: self.infoView, edgeInset: 0)
        self.tagsView.sizeAnchor(height: 0)
        self.tagsView.columnAnchor(view: self.scheduleAndDueLabel)
        
        self.tagsView.addSubview(self.tagsIcon)
        self.tagsView.addSubview(self.tagsLabel)
        
        self.tagsIcon.sideAnchor(for: [.left, .top, .bottom], to: self.tagsView, edgeInset: 0)
        self.tagsIcon.rowAnchor(view: self.tagsLabel, space: 10)
        self.tagsLabel.sideAnchor(for: [.top, .right, .bottom], to: self.tagsView, edgeInset: 0)
        
        self.tagsView.columnAnchor(view: self.scheduleAndDueLabel)
        self.scheduleAndDueLabel.sideAnchor(for: [.left, .right, .bottom], to: self.infoView, edgeInsets: .init(top: 0, left: 0, bottom: -20, right: -30))
        self.scheduleAndDueLabel.sizeAnchor(height: 0)
    }
    
    private func updateUI(cellModel: AgendaCellModel) {
        self.statusLabel.text = cellModel.planning
        self.headingContentLabel.text = cellModel.trimmedHeading
        
        self.documentNameLabel.text = cellModel.url.fileName
        
        if let tags = cellModel.tags {
            self.tagsView.constraint(for: Position.height)?.isActive = false
            self.tagsView.isHidden = false
            self.tagsLabel.text = tags.joined(separator: " ")
            self.headingContentLabel.constraint(for: Position.bottom)?.constant = -10
        } else {
            self.tagsView.constraint(for: Position.height)?.isActive = true
            self.tagsView.isHidden = true
            self.headingContentLabel.constraint(for: Position.bottom)?.constant = 0
        }
        
        let viewAboveScheduleAndDueLabel = self.tagsView.isHidden ? self.headingContentLabel : self.tagsView
        switch (cellModel.schedule, cellModel.due) {
        case (nil, nil):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.isActive = true
            viewAboveScheduleAndDueLabel.constraint(for: Position.bottom)?.constant = 0
            self.scheduleAndDueLabel.isHidden = true
        case (let schedule?, nil):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.isActive = false
            viewAboveScheduleAndDueLabel.constraint(for: Position.bottom)?.constant = -10
            self.scheduleAndDueLabel.text = "\(schedule.description) ⇢"
            self.scheduleAndDueLabel.isHidden = false
        case (let schedule?, let due?):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.isActive = false
            viewAboveScheduleAndDueLabel.constraint(for: Position.bottom)?.constant = -10
            self.scheduleAndDueLabel.text = "\(schedule.description) ⇢ \(due.description)"
            self.scheduleAndDueLabel.isHidden = false
        case (nil, let due?):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.isActive = false
            viewAboveScheduleAndDueLabel.constraint(for: Position.bottom)?.constant = -10
            self.scheduleAndDueLabel.isHidden = false
            // 检查是否过期
            let today = Date()
            var overdueString = ""
            if due.date <= today {
                overdueString = " (+\(today.daysFrom(due.date)))"
            }
            self.scheduleAndDueLabel.text = "⇢ \(due.description)" + overdueString
        }
        
        self.layoutIfNeeded()
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
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

