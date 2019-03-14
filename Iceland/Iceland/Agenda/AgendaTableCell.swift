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
    
    private let planningLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptiveHighlighted
        label.font = InterfaceTheme.Font.title
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
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
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
        self.contentView.addSubview(self.planningLabel)
        self.planningLabel.centerAnchors(position: .centerY, to: self.contentView)
        self.planningLabel.sizeAnchor(width: AgendaViewController.Constants.edgeInsets.left)
        self.planningLabel.sideAnchor(for: .left, to: self.contentView, edgeInset: 0)
        
        self.contentView.addSubview(self.infoView)
        self.infoView.sideAnchor(for: [.left, .top, .bottom, .right],
                                 to: self.contentView,
                                 edgeInsets: .init(top: 0, left: AgendaViewController.Constants.edgeInsets.left, bottom: 0, right: 0))
        
        self.infoView.addSubview(self.documentNameLabel)
        self.infoView.addSubview(self.headingTextLabel)
        self.infoView.addSubview(self.summaryLabel)
        self.infoView.addSubview(self.tagsView)
        self.infoView.addSubview(self.scheduleAndDueLabel)
        
        self.documentNameLabel.sideAnchor(for: [.left, .top, .right], to: self.infoView, edgeInsets: .init(top: 10, left: 0, bottom: 0, right: -Layout.edgeInsets.right))
        self.documentNameLabel.sizeAnchor(height: 20)
        self.documentNameLabel.columnAnchor(view: self.headingTextLabel, space: 10)
        
        self.headingTextLabel.sideAnchor(for: [.left, .right], to: self.infoView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -Layout.edgeInsets.right))
        self.headingTextLabel.sizeAnchor(height: 20)
        self.headingTextLabel.columnAnchor(view: self.summaryLabel, space: 10)

        self.summaryLabel.sideAnchor(for: [.left, .right], to: self.infoView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -Layout.edgeInsets.right))
        self.summaryLabel.columnAnchor(view: self.tagsView)
        
        self.tagsView.sideAnchor(for: [.left, .right], to: self.infoView, edgeInset: 0)
        self.tagsView.sizeAnchor(height: 0)
        self.tagsView.columnAnchor(view: self.scheduleAndDueLabel)
        
        self.tagsView.addSubview(self.tagsIcon)
        self.tagsView.addSubview(self.tagsLabel)
        
        self.tagsIcon.sideAnchor(for: .left, to: self.tagsView, edgeInset: 0)
        self.tagsIcon.ratioAnchor(1)
        self.tagsIcon.sizeAnchor(width: 10)
        self.tagsIcon.rowAnchor(view: self.tagsLabel, space: 3)
        self.tagsLabel.sideAnchor(for: [.top, .right, .bottom], to: self.tagsView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -Layout.edgeInsets.right))
        
        self.tagsView.columnAnchor(view: self.scheduleAndDueLabel)
        self.scheduleAndDueLabel.sideAnchor(for: [.left, .right, .bottom], to: self.infoView, edgeInsets: .init(top: 0, left: 0, bottom: -10, right: -Layout.edgeInsets.right))
        self.scheduleAndDueLabel.sizeAnchor(height: 0)
    }
    
    private func updateUI(cellModel: AgendaCellModel) {
        self.planningLabel.text = cellModel.planning
        self.summaryLabel.text = cellModel.contentSummary
        self.documentNameLabel.text = cellModel.url.fileName
        self.headingTextLabel.text = cellModel.headingText
        
        if let tags = cellModel.tags {
            self.tagsView.constraint(for: Position.height)?.constant = 20
            self.tagsView.constraint(for: Position.bottom)?.constant = -10
            self.summaryLabel.constraint(for: Position.bottom)?.constant = -10
            self.tagsView.isHidden = false
            self.tagsLabel.text = tags.joined(separator: " ")
        } else {
            self.tagsView.constraint(for: Position.bottom)?.constant = 0
            self.summaryLabel.constraint(for: Position.bottom)?.constant = 0
            self.tagsView.constraint(for: Position.height)?.constant = 0
            self.tagsView.isHidden = true
        }
        
        if (self.summaryLabel.text?.count ?? 0) > 0 {
             self.summaryLabel.constraint(for: Position.bottom)?.constant = -10
        } else {
            self.summaryLabel.constraint(for: Position.bottom)?.constant = 0
        }
        
        let viewAboveScheduleAndDueLabel = self.tagsView.isHidden ? self.summaryLabel : self.tagsView
        switch (cellModel.schedule, cellModel.due) {
        case (nil, nil):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.constant = 0
            viewAboveScheduleAndDueLabel.constraint(for: Position.bottom)?.constant = 0
            self.scheduleAndDueLabel.isHidden = true
        case (let schedule?, nil):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.constant = 20
            viewAboveScheduleAndDueLabel.constraint(for: Position.bottom)?.constant = -10
            self.scheduleAndDueLabel.text = "\(schedule.description) ⇢"
            self.scheduleAndDueLabel.isHidden = false
        case (let schedule?, let due?):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.constant = 20
            viewAboveScheduleAndDueLabel.constraint(for: Position.bottom)?.constant = -10
            self.scheduleAndDueLabel.text = "\(schedule.description) ⇢ \(due.description)"
            self.scheduleAndDueLabel.isHidden = false
        case (nil, let due?):
            self.scheduleAndDueLabel.constraint(for: Position.height)?.constant = 20
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
        UIView.animate(withDuration: 0.3) {
            if highlighted {
                self.backgroundColor = InterfaceTheme.Color.background2
            } else {
                self.backgroundColor = InterfaceTheme.Color.background1
            }
        }
    }
    
    override public func setSelected(_ selected: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            if selected {
                self.backgroundColor = InterfaceTheme.Color.background2
            } else {
                self.backgroundColor = InterfaceTheme.Color.background1
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

