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
    func didTapActionButton(url: URL)
}

public class AgendaTableCell: UITableViewCell {
    
    public static let reuseIdentifier = "AgendaTableCell"
    
    public weak var delegate: AgendaTableCellDelegate?
    
    private let infoView: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background2
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let documentNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptiveHighlighted
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        return label
    }()
    
    private let headingTextLabel: UILabel = {
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
        imageView.image = Asset.Assets.tag.image.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        imageView.tintColor = InterfaceTheme.Color.descriptiveHighlighted
        return imageView
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptiveHighlighted
        label.textAlignment = .left
        label.font = InterfaceTheme.Font.footnote
        return label
    }()
    
    private let _actionButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Assets.more.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
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
        self.backgroundColor = InterfaceTheme.Color.background1
        
        self.contentView.addSubview(self.infoView)
        self.infoView.sideAnchor(for: [.left, .top, .bottom, .right],
                                 to: self.contentView,
                                 edgeInsets: .init(top: 10, left: Layout.edgeInsets.left, bottom: -10, right: -Layout.edgeInsets.right))
        
        self.infoView.addSubview(self.documentNameLabel)
        self.infoView.addSubview(self.headingTextLabel)
        self.infoView.addSubview(self.tagsView)
        self.infoView.addSubview(self._actionButton)
        
        self._actionButton.sideAnchor(for: [.top, .right, .bottom], to: self.infoView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -Layout.edgeInsets.right))
        self._actionButton.sizeAnchor(width: 44)
        
        self.documentNameLabel.sideAnchor(for: [.left, .top, .right], to: self.infoView, edgeInsets: .init(top: 10, left: Layout.edgeInsets.left, bottom: 0, right: -44 - Layout.edgeInsets.right))
        self.documentNameLabel.sizeAnchor(height: 20)
        
        self.documentNameLabel.columnAnchor(view: self.headingTextLabel, space: 10)
        self.headingTextLabel.sideAnchor(for: [.left, .right], to: self.infoView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -44 - Layout.edgeInsets.right))
        self.headingTextLabel.sizeAnchor(height: 20)
        
        self.headingTextLabel.columnAnchor(view: self.tagsView, space: 10)
        self.tagsView.sideAnchor(for: [.left, .right, .bottom], to: self.infoView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -44 - Layout.edgeInsets.right))
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
        self.documentNameLabel.text = cellModel.url.fileName
        
        let aString: NSMutableAttributedString = NSMutableAttributedString()
        if let planning = cellModel.planning {
            let color = SettingsAccessor.shared.unfinishedPlanning.contains(planning) ? InterfaceTheme.Color.warning : InterfaceTheme.Color.spotlight
            aString.append(NSAttributedString(string: planning + " ", attributes: [NSAttributedString.Key.foregroundColor : color,
                                                                                      NSAttributedString.Key.font: InterfaceTheme.Font.footnote]))
        }
        
        if let priority = cellModel.priority {
            aString.append(NSAttributedString(string: priority + " ", attributes: [NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptiveHighlighted,
                                                                                      NSAttributedString.Key.font: InterfaceTheme.Font.footnote]))
        }
        
        aString.append(NSAttributedString(string: cellModel.headingText, attributes: [NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.interactive,
                                                                                               NSAttributedString.Key.font: InterfaceTheme.Font.body]))
        self.headingTextLabel.attributedText = aString
        
        if let tags = cellModel.tags {
            self.tagsView.constraint(for: Position.height)?.constant = 20
            self.tagsView.constraint(for: Position.bottom)?.constant = -10
            self.tagsView.isHidden = false
            self.tagsLabel.text = tags.joined(separator: " ")
        } else {
            self.tagsView.constraint(for: Position.bottom)?.constant = 0
            self.tagsView.constraint(for: Position.height)?.constant = 0
            self.tagsView.isHidden = true
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
        self.delegate?.didTapActionButton(url: self.cellModel!.url)
    }
}

