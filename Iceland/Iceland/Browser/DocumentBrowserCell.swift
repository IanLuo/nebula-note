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
        return button
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.subTitle
        label.textColor = InterfaceTheme.Color.interactive
        label.textAlignment = .left
        return label
    }()
    private let actionButton: UIButton = {
        let button = UIButton()
        button.setTitle("…", for: .normal)
        return button
    }()
    
    public weak var delegate: DocumentBrowserCellDelegate?
    public var cellModel: DocumentBrowserCellModel? {
        didSet {
            if let cellModel = cellModel {
                setupUI(cellModel: cellModel)
                
                self.arrowButton.addTarget(self, action: #selector(didTapArrow), for: .touchUpInside)
                self.actionButton.addTarget(self, action: #selector(didTapAction), for: .touchUpInside)
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
            self.delegate?.didTapUnfold(url: cellModel.url)
        } else {
            self.delegate?.didTapFold(url: cellModel.url)
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        self.contentView.addSubview(self.arrowButton)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.actionButton)
        
        self.arrowButton.sideAnchor(for: [.left, .top, .bottom], to: self.contentView, edgeInsets: .zero)
        self.arrowButton.sizeAnchor(width: 30, height: 60)
        self.arrowButton.rowAnchor(view: self.titleLabel, space: 10)
        self.titleLabel.sideAnchor(for: [.top, .bottom], to: self.contentView, edgeInset: 0)
        
        self.titleLabel.rowAnchor(view: self.actionButton, space: 10)
        self.actionButton.sideAnchor(for: [.top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -30))

        self.contentView.backgroundColor = InterfaceTheme.Color.background1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(cellModel: DocumentBrowserCellModel) {
        self.arrowButton.constraint(for: .left)?.constant = CGFloat(cellModel.levelFromRoot * 10 + 10)
        
        self.titleLabel.text = self.cellModel?.url.deletingPathExtension().lastPathComponent
        
        if cellModel.hasSubDocuments {
            if cellModel.isFolded {
                self.arrowButton.setTitle("+", for: .normal)
            } else {
                self.arrowButton.setTitle("-", for: .normal)
            }
        } else {
            self.arrowButton.setTitle("", for: .normal)
        }
    }
}
