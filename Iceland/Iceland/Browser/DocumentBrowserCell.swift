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

public protocol DocumentBrowserCellDelegate: class {
    func didTapUnfold(url: URL)
    func didTapFold(url: URL)
    func didTapActions(url: URL)
}

public class DocumentBrowserCell: UITableViewCell {
    public static let reuseIdentifier: String = "DocumentBrowserCell"
    private let arrowButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "down")?.resize(upto: CGSize(width: 10, height: 10)).withRenderingMode(.alwaysTemplate), for: .normal)
        button.isHidden = true
        button.tintColor = InterfaceTheme.Color.descriptiveHighlighted
        return button
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.subtitle
        label.textColor = InterfaceTheme.Color.interactive
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    private let actionButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "more")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
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
            self.arrowButton.perspectiveRotate(angel: CGFloat.pi)
            self.delegate?.didTapUnfold(url: cellModel.url)
        } else {
            self.arrowButton.perspectiveRotate(angel: 0)
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
        self.actionButton.sideAnchor(for: [.top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -30))
        self.actionButton.ratioAnchor(1)
        
        self.backgroundColor = InterfaceTheme.Color.background1
    }
    
    private func updateUI(cellModel: DocumentBrowserCellModel) {
        self.arrowButton.constraint(for: .left)?.constant = CGFloat(cellModel.levelFromRoot * 10 + 10)
        
        self.separatorInset = UIEdgeInsets(top: 0, left: CGFloat(cellModel.levelFromRoot * 10 + 30), bottom: 0, right: 30)
        
        self.titleLabel.text = self.cellModel?.url.fileName
        
        if cellModel.hasSubDocuments {
            self.arrowButton.isHidden = false
            if cellModel.isFolded {
                self.arrowButton.perspectiveRotate(angel: 0, skipAnimation: true)
            } else {
                self.arrowButton.perspectiveRotate(angel: CGFloat.pi, skipAnimation: true)
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
