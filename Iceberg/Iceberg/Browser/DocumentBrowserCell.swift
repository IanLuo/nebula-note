//
//  DocumentTableCell.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public protocol DocumentBrowserCellDelegate: class {
    func didTapUnfold(url: URL)
    func didTapFold(url: URL)
    func didTapActions(url: URL)
}

public class DocumentBrowserCell: UITableViewCell {
    public static let reuseIdentifier: String = "DocumentBrowserCell"
    private let arrowButton: UIButton = {
        let button = UIButton()
        button.interface({ (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.Assets.right.image.resize(upto: CGSize(width: 10, height: 10)).fill(color: theme.color.spotlight), for: .normal)
        })
        button.isHidden = true
        return button
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.subtitle
            label.textColor = theme.color.interactive
        })
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private let actionButton: UIButton = {
        let button = UIButton()
        button.interface({ (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.Assets.more.image.fill(color: theme.color.spotlight), for: .normal)
        })
        return button
    }()
    
    public weak var delegate: DocumentBrowserCellDelegate?
    public var cellModel: DocumentBrowserCellModel? {
        didSet {
            if let cellModel = cellModel {
                updateUI(cellModel: cellModel)
                
                self.actionButton.isHidden = !cellModel.shouldShowActions
                
                if cellModel.shouldShowChooseHeadingIndicator {
                    self.accessoryType = .disclosureIndicator
                } else {
                    self.accessoryType = .none
                }
            }
        }
    }
    
    @objc func didTapAction() {
        if let url = self.cellModel?.url {
            self.delegate?.didTapActions(url: url)
        }
    }
    
    @objc func didTapArrow() {
        guard let cellModel = self.cellModel else { return }

        if cellModel.isFolded {
            self.arrowButton.rotate(angel: CGFloat.pi / 2)
            self.delegate?.didTapUnfold(url: cellModel.url)
        } else {
            self.arrowButton.rotate(angel: 0)
            self.delegate?.didTapFold(url: cellModel.url)
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupUI()
        
        self.arrowButton.addTarget(self, action: #selector(didTapArrow), for: .touchUpInside)
        self.actionButton.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.arrowButton)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.actionButton)
        
        self.arrowButton.sideAnchor(for: [.left, .top, .bottom], to: self.contentView, edgeInsets: .zero)
        self.arrowButton.sizeAnchor(width: 40, height: 60)
        self.arrowButton.rowAnchor(view: self.titleLabel, space: 10)
        self.titleLabel.sideAnchor(for: [.top, .bottom], to: self.contentView, edgeInset: 0)
        
        self.titleLabel.rowAnchor(view: self.actionButton, space: 10)
        self.actionButton.sideAnchor(for: [.top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -10))
        self.actionButton.ratioAnchor(1)
        
        self.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
    }
    
    private func updateUI(cellModel: DocumentBrowserCellModel) {
        self.arrowButton.constraint(for: .left)?.constant = CGFloat(cellModel.levelFromRoot * 10 + 10)
        
        self.separatorInset = UIEdgeInsets(top: 0, left: CGFloat(cellModel.levelFromRoot * 10 + 30), bottom: 0, right: 30)
        
        self.titleLabel.text = self.cellModel?.url.packageName
        
        if cellModel.hasSubDocuments {
            self.arrowButton.isHidden = false
            if cellModel.isFolded {
                self.arrowButton.rotate(angel: 0, skipAnimation: true)
            } else {
                self.arrowButton.rotate(angel: CGFloat.pi / 2, skipAnimation: true)
            }
        } else {
            self.arrowButton.isHidden = true
        }
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
}
