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
            me.textColor = theme.color.descriptiveHighlighted
        })
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        return label
    }()
    
    private let _dateAndTimeLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.textColor = theme.color.warning
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
            me.image = Asset.Assets.tag.image.fill(color: theme.color.descriptiveHighlighted)
        })

        return imageView
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.interface({ (me, theme) in
            let me = me as! UILabel
            me.textColor = theme.color.descriptiveHighlighted
            me.font = theme.font.footnote
        })
        label.textAlignment = .left
        return label
    }()
    
    private let _actionButton: UIButton = {
        let button = UIButton()
        
        button.interface({ (me, theme) in
            let me = me as! UIButton
            button.setImage(Asset.Assets.moreV.image.fill(color: theme.color.descriptiveHighlighted), for: .normal)
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
        self.documentNameLabel.sizeAnchor(height: 20)
        
        self._dateAndTimeLabel.sideAnchor(for: [.right, .top, .right], to: self.infoView, edgeInsets: .init(top: 20, left: 20, bottom: 0, right: -20))
        self._dateAndTimeLabel.sizeAnchor(height: 20)
        
        self.documentNameLabel.columnAnchor(view: self.headingTextLabel, space: 10)
        self.headingTextLabel.sideAnchor(for: [.left, .right], to: self.infoView, edgeInsets: .init(top: 0, left: 20, bottom: 0, right: -20))
        self.headingTextLabel.sizeAnchor(height: 20)
        
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
        if let planning = cellModel.planning {
            let style = OutlineTheme.planningStyle(isFinished: SettingsAccessor.shared.finishedPlanning.contains(planning))
            aString.append(NSAttributedString(string: planning + " ", attributes: style.textStyle.attributes))
        }
        
        if let priority = cellModel.priority {
            let style = OutlineTheme.priorityStyle(priority)
            aString.append(NSAttributedString(string: priority + " ", attributes: style.textStyle.attributes))
        }
        
        aString.append(NSAttributedString(string: cellModel.headingText, attributes: OutlineTheme.headingStyle(level: cellModel.level).attributes))
        self.headingTextLabel.attributedText = aString
        
        if let tags = cellModel.tags {
            self.tagsView.constraint(for: Position.height)?.constant = 20
            self.tagsView.isHidden = false
            self.tagsLabel.text = tags.joined(separator: " ")
        } else {
            self.tagsView.constraint(for: Position.height)?.constant = 0
            self.tagsView.isHidden = true
        }
        
        self._dateAndTimeLabel.isHidden = cellModel.dateAndTime == nil
        self._dateAndTimeLabel.attributedText = cellModel.dateAndTime?.agendaLabel
        
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
    public var agendaLabel: NSAttributedString? {
        
        var text: String? = ""
        var color: UIColor = InterfaceTheme.Color.finished
        
        let today = Date()
        if self.isSchedule {
            if today.isSameDay(self.date) {
                text = L10n.Agenda.startToday
                color = InterfaceTheme.Color.unfinished
            } else if today.timeIntervalSince1970 > self.date.timeIntervalSince1970 {
                let daysBeforeDate = today.dayBegin.daysFrom(self.date)
                if daysBeforeDate == 1 {
                    text = L10n.Agenda.startYesterdayWithPlaceHodlerYesterday
                    color = InterfaceTheme.Color.warning
                } else {
                    text = L10n.Agenda.startDaysAgoWithPlaceHodler("\(today.daysFrom(self.date))")
                    color = InterfaceTheme.Color.warning
                }
            } else {
                let daysFromToday = self.date.dayBegin.daysFrom(today)
                if daysFromToday == 1 {
                    text = L10n.Agenda.startTomorrowWithPlaceHolder
                    color = InterfaceTheme.Color.unfinished
                } else {
                    text = L10n.Agenda.startInDaysWithPlaceHolder("\(daysFromToday)")
                    color = InterfaceTheme.Color.unfinished
                }
            }
        } else if self.isDue {
            if today.isSameDay(self.date) {
                text = L10n.Agenda.dueToday
                color = InterfaceTheme.Color.unfinished
            } else if today.timeIntervalSince1970 > self.date.timeIntervalSince1970 {
                let dateFromToday = today.daysFrom(self.date)
                if dateFromToday == 1 {
                    text = L10n.Agenda.overdueYesterdayWihtPlaceHolder
                    color = InterfaceTheme.Color.unfinished
                } else {
                    text = L10n.Agenda.overdueDaysWihtPlaceHolder("\(dateFromToday)")
                    color = InterfaceTheme.Color.unfinished
                }
            } else {
                let daysAfterToday = self.date.daysFrom(today)
                if daysAfterToday == 1 {
                    text = L10n.Agenda.willOverduTomorrowWithPlaceHolder
                    color = InterfaceTheme.Color.warning
                } else {
                    text = L10n.Agenda.willOverduInDaysWithPlaceHolder("\(daysAfterToday)")
                    color = InterfaceTheme.Color.warning
                }
            }
        } else {
            text = nil
        }
        
        if let text = text {
            return NSAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor : color])
        } else {
            return nil
        }
    }
}
