//
//  AgendaTableCell.swift
//  Iceland
//
//  Created by ian luo on 2018/12/27.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public protocol AgendaTableCellDelegate: class {
    func didTapActionButton(cellModel: AgendaCellModel)
}

public class AgendaTableCell: UITableViewCell {
    
    public static let reuseIdentifier = "AgendaTableCell"
    
    public weak var delegate: AgendaTableCellDelegate?
    
    private let infoView: UIView = {
        let view = UIView()
        
        view.interface({ (me, theme) in
            me.backgroundColor = theme.color.background2
        })
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let documentNameLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.textColor = theme.color.descriptive
        })
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        return label
    }()
    
    private let _dateAndTimeLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.font = theme.font.footnote
        })
        return label
    }()
    
    private let headingTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private let tagsView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let tagsIcon: UIImageView = {
        let imageView = UIImageView()
        
        imageView.interface({ (me, theme) in
            let me = me as! UIImageView
            me.image = Asset.SFSymbols.tag.image.fill(color: theme.color.descriptive)
        })

        return imageView
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.textColor = theme.color.descriptive
            me.font = theme.font.footnote
        })
        label.textAlignment = .left
        return label
    }()
    
    private let _actionButton: UIButton = {
        let button = UIButton()
        
        button.interface({ (me, theme) in
            let me = me as! UIButton
            button.setImage(Asset.Assets.moreV.image.fill(color: theme.color.descriptive), for: .normal)
        })
        return button
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
        
        self._actionButton.addTarget(self, action: #selector(_didTapActionButton), for: .touchUpInside)
        
    }
    
    private func setupUI() {
        self.backgroundView = UIView()
        
        self.interface { (me, theme) in
            let me = me as! AgendaTableCell
            me.backgroundColor = theme.color.background1
            me.contentView.backgroundColor = theme.color.background1
            if let cellModel = me.cellModel {
                me.updateUI(cellModel: cellModel) // update the theme
            }
        }
        self.enableHover(on: self.infoView, hoverColor: InterfaceTheme.Color.background3)
        
        self.contentView.addSubview(self.infoView)
        self.infoView.sideAnchor(for: [.left, .top, .bottom, .right],
                                 to: self.contentView,
                                 edgeInsets: .init(top: 10, left: Layout.edgeInsets.left, bottom: -10, right: -Layout.edgeInsets.right))
        
        self.infoView.addSubview(self.documentNameLabel)
        self.infoView.addSubview(self.headingTextLabel)
        self.infoView.addSubview(self._dateAndTimeLabel)
        self.infoView.addSubview(self.tagsView)
        self.infoView.addSubview(self._actionButton)
        
        self._actionButton.sideAnchor(for: [.top, .right, .bottom], to: self.infoView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: 0))
        self._actionButton.sizeAnchor(width: 44)
        
        self._actionButton.isHidden = true // 现在不需要显示 action
        
        self.documentNameLabel.sideAnchor(for: [.left, .top, .right], to: self.infoView, edgeInsets: .init(top: 20, left: 20, bottom: 0, right: -20))
        
        self._dateAndTimeLabel.sideAnchor(for: [.right, .top, .right], to: self.infoView, edgeInsets: .init(top: 20, left: 20, bottom: 0, right: -20))
        
        self.documentNameLabel.columnAnchor(view: self.headingTextLabel, space: 10)
        self.headingTextLabel.sideAnchor(for: [.left, .right], to: self.infoView, edgeInsets: .init(top: 0, left: 20, bottom: 0, right: -20))
        
        self.headingTextLabel.columnAnchor(view: self.tagsView, space: 10)
        self.tagsView.sideAnchor(for: [.left, .right, .bottom], to: self.infoView, edgeInsets: .init(top: 0, left: 20, bottom: -10, right: -20))
        self.tagsView.sizeAnchor(height: 0)
        
        self.tagsView.addSubview(self.tagsIcon)
        self.tagsView.addSubview(self.tagsLabel)
        
        self.tagsIcon.sideAnchor(for: .left, to: self.tagsView, edgeInset: 0)
        self.tagsIcon.ratioAnchor(1)
        self.tagsIcon.sizeAnchor(width: 10)
        self.tagsIcon.rowAnchor(view: self.tagsLabel, space: 3)
        self.tagsLabel.sideAnchor(for: [.top, .right, .bottom], to: self.tagsView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -Layout.edgeInsets.right))
    }
    
    private func updateUI(cellModel: AgendaCellModel) {
        self.documentNameLabel.text = cellModel.url.packageName
        
        let aString: NSMutableAttributedString = NSMutableAttributedString()
        if let isFinished = cellModel.isFinished, let planning = cellModel.planning {
            let style = OutlineTheme.planningStyle(isFinished: isFinished)
            aString.append(NSAttributedString(string: planning + " ", attributes: [NSAttributedString.Key.foregroundColor: style.buttonColor, NSAttributedString.Key.font: OutlineTheme.markStyle.font]))
        }
        
        if let priority = cellModel.priority {
            let style = OutlineTheme.priorityStyle(priority)
            aString.append(NSAttributedString(string: priority + " ", attributes: [NSAttributedString.Key.foregroundColor: style.buttonColor, NSAttributedString.Key.font: OutlineTheme.markStyle.font]))
        }
        
        aString.append(NSAttributedString(string: cellModel.headingText, attributes: OutlineTheme.headingStyle(level: cellModel.level).attributes))
        
        self.headingTextLabel.attributedText = aString
        
        if let tags = cellModel.tags {
            self.tagsView.constraint(for: Position.height)?.constant = 20
            self.tagsIcon.isHidden = false
            self.tagsLabel.isHidden = false
            self.tagsLabel.text = tags.joined(separator: ", ")
        } else {
            self.tagsView.constraint(for: Position.height)?.constant = 0
            self.tagsIcon.isHidden = true
            self.tagsLabel.isHidden = true
        }
        
        self._dateAndTimeLabel.isHidden = cellModel.dateAndTime == nil
        if let currentDate = cellModel.currentDate {
            self._dateAndTimeLabel.attributedText = cellModel.dateAndTime?.agendaLabel(today: currentDate)
        }
        
        self.layoutIfNeeded()
    }
    
    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            if highlighted {
                self.infoView.backgroundColor = InterfaceTheme.Color.background3
            } else {
                self.infoView.backgroundColor = InterfaceTheme.Color.background2
            }
        }
    }
    
    override public func setSelected(_ selected: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.3) {
            if selected {
                self.infoView.backgroundColor = InterfaceTheme.Color.background3
            } else {
                self.infoView.backgroundColor = InterfaceTheme.Color.background2
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @objc private func _didTapActionButton() {
        self.delegate?.didTapActionButton(cellModel: self.cellModel!)
    }
}

extension DateAndTimeType {
    public func agendaLabel(today: Date) -> NSAttributedString? {
        if let notice = self.checkNotice(relative: today) {
            return NSAttributedString(string: notice.message, attributes: [NSAttributedString.Key.foregroundColor : notice.alertLevel.color])
        } else {
            return nil
        }
    }
}
