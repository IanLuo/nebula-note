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

public protocol FilteredItemTableCellDelegate: class {
    
}

public class FilteredItemTableCell: UITableViewCell {
    
    public static let reuseIdentifier = "FilteredItemTableCell"
    
    public weak var delegate: FilteredItemTableCellDelegate?
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .center
        return label
    }()
    
    private let documentNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        return label
    }()
    
    private let headingTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        return label
    }()
    
    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.interactive
        label.font = InterfaceTheme.Font.footnote
        label.numberOfLines = 3
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
        
        self.contentView.addSubview(self.documentNameLabel)
        self.contentView.addSubview(self.headingTextLabel)
        self.contentView.addSubview(self.summaryLabel)
        self.contentView.addSubview(self.tagsView)
        self.contentView.addSubview(self.statusLabel)
        self.contentView.addSubview(self.scheduleAndDueLabel)
        
        self.documentNameLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 20, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        self.documentNameLabel.columnAnchor(view: self.headingTextLabel, space: 10)
        
        self.headingTextLabel.sideAnchor(for: [.left, .right], to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        self.headingTextLabel.columnAnchor(view: self.tagsView, space: 10)
        
        self.tagsView.sideAnchor(for: [.left, .right], to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        self.tagsView.sizeAnchor(height: 0)
        
        self.tagsView.addSubview(self.tagsIcon)
        self.tagsView.addSubview(self.tagsLabel)
        
        self.tagsIcon.sideAnchor(for: [.left, .top, .bottom], to: self.tagsView, edgeInset: 0)
        self.tagsIcon.sizeAnchor(width: 24)
        self.tagsIcon.rowAnchor(view: self.tagsLabel, space: 10)
        self.tagsLabel.sideAnchor(for: [.top, .right, .bottom], to: self.tagsView, edgeInset: 0)
        
        self.tagsView.columnAnchor(view: self.statusLabel, space: 10)
        
        self.statusLabel.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        self.statusLabel.rowAnchor(view: self.scheduleAndDueLabel, space: 10)
        
        self.scheduleAndDueLabel.sideAnchor(for: .right, to: self.contentView, edgeInset: -Layout.edgeInsets.right)
        self.scheduleAndDueLabel.sizeAnchor(height: 0)
        
        self.scheduleAndDueLabel.columnAnchor(view: self.summaryLabel, space: 20)
        
        self.summaryLabel.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: -20, right: -Layout.edgeInsets.right))
    }
    
    private func updateUI(cellModel: AgendaCellModel) {
        self.statusLabel.text = cellModel.planning
        self.summaryLabel.text = cellModel.contentSummary
        self.documentNameLabel.text = cellModel.url.fileName
        self.headingTextLabel.text = cellModel.headingText
        
        if let tags = cellModel.tags {
            self.tagsView.constraint(for: Position.height)?.isActive = false
            self.tagsView.isHidden = false
            self.tagsLabel.text = tags.joined(separator: " ")
            self.summaryLabel.constraint(for: Position.bottom)?.constant = -10
        } else {
            self.tagsView.constraint(for: Position.height)?.isActive = true
            self.tagsView.isHidden = true
            self.summaryLabel.constraint(for: Position.bottom)?.constant = 0
        }
        
        if let planning = cellModel.planning {
            self.statusLabel.text = planning
            self.statusLabel.isHidden = false
            if let width = self.statusLabel.constraint(for: .width),
                let height = self.statusLabel.constraint(for: .height) {
                self.statusLabel.removeConstraints([width, height])
            }
        } else {
            self.statusLabel.sizeAnchor(width: 0, height: 0)
            self.statusLabel.isHidden = true
        }
        
        let viewAboveScheduleAndDueLabel = self.tagsView.isHidden ? self.summaryLabel : self.tagsView
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

