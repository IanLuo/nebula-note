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
    func didTapAdd(url: URL)
    func didTapRemove(url: URL)
    func didTapRanme(url: URL)
    func didTapUnfold(url: URL)
    func didTapFold(url: URL)
    func didTapUnfoldAll(url: URL)
    func didTap(url: URL)
}

public class DocumentBrowserCell: UITableViewCell {
    public static let reuseIdentifier: String = "DocumentBrowserCell"
    private let arrowImageView: UIImageView = UIImageView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.subTitle
        label.textColor = InterfaceTheme.Color.interactive
        return label
    }()
    private let actionButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    public weak var delegate: DocumentBrowserCellDelegate?
    public var cellModel: DocumentBrowserCellModel? {
        didSet {
            if let cellModel = cellModel {
                setupUI(cellModel: cellModel)
            }
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(self.arrowImageView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.actionButton)
        
        self.arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.arrowImageView.sideAnchor(for: [.left, .top, .bottom], to: self.contentView, edgeInsets: .zero)
        self.titleLabel.leftAnchor.constraint(equalTo: self.arrowImageView.leftAnchor, constant: 10).isActive = true
        self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -10).isActive = true
        self.titleLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        self.actionButton.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.actionButton.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        
        self.contentView.backgroundColor = InterfaceTheme.Color.background1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(cellModel: DocumentBrowserCellModel) {
        self.arrowImageView.constraint(for: .left)?.constant = CGFloat(cellModel.levelFromRoot * 10 + 10)
        
        self.titleLabel.text = self.cellModel?.url.deletingPathExtension().lastPathComponent
    }
}
