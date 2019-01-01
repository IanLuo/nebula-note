//
//  CaptureTableCell.swift
//  Iceland
//
//  Created by ian luo on 2018/12/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol CaptureTableCellDelegate: class {
    func didTapDelete(cell: CaptureTableCell)
    func didTapRefile(cell: CaptureTableCell)
}

public class CaptureTableCell: UITableViewCell {
    public static let reuseIdentifier = "CaptureTableCell"
    public weak var delegate: CaptureTableCellDelegate?
    public var cellModel: CaptureTableCellModel? {
        didSet {
            if let cellModel = cellModel {
                self.setupAttachmentUI(attachmentView: cellModel.attachmentView)
            }
        }
    }
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.descriptive
        return label
    }()
    
    private let attachmentContentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var actionsView: ActionsView = {
        let view = ActionsView()
        view.delegate = self
        return view
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.attachmentContentView)
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.attachmentContentView.translatesAutoresizingMaskIntoConstraints = false
        
        self.titleLabel.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 30).isActive = true
        self.titleLabel.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -30).isActive = true
        self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 30).isActive = true
        self.titleLabel.bottomAnchor.constraint(equalTo: self.attachmentContentView.topAnchor, constant: -30).isActive = true
        
        self.attachmentContentView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 30).isActive = true
        self.attachmentContentView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -30).isActive = true
        self.attachmentContentView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -30).isActive = true
    }
    
    private func setupAttachmentUI(attachmentView: AttachmentViewType) {
        self.contentView.addSubview(attachmentView)
        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        
        self.attachmentContentView.addSubview(attachmentView)
        
        attachmentView.allSidesAnchors(to: self.attachmentContentView, edgeInsets: .zero)
    }
    
    public override func prepareForReuse() {
        self.titleLabel.text = ""
        self.attachmentContentView.subviews.forEach { $0.removeFromSuperview() }
    }
        
    private func showActions(animated: Bool) {
        if self.actionsView.superview == nil {
            self.attachmentContentView.addSubview(self.actionsView)
            self.actionsView.translatesAutoresizingMaskIntoConstraints = false
            self.actionsView.sideAnchor(for: [.left, .bottom, .right], to: self.attachmentContentView, edgeInsets: .init(top: 0, left: 0, bottom: 60, right: 0))
            self.actionsView.heightAnchor.constraint(equalToConstant: 60)
        }
        
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.actionsView.constraint(for: Position.bottom)?.constant = 0
        }
    }
    
    private func hideActions(animated: Bool) {
        UIView.animate(withDuration: animated ? 0.25 : 0) {
            self.actionsView.constraint(for: Position.bottom)?.constant = 60
        }
    }
    
    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if self.isSelected {
            self.showActions(animated: animated)
        } else {
            self.hideActions(animated: animated)
        }
    }
}

// MARK: - ActionsViewDelegate
extension CaptureTableCell: ActionsViewDelegate {
    func didTapDelete() {
        self.hideActions(animated: true)
        self.delegate?.didTapDelete(cell: self)
    }
    
    func didTapRefile() {
        self.hideActions(animated: true)
        self.delegate?.didTapRefile(cell: self)
    }
}

// MARK: - ActionsView
protocol ActionsViewDelegate: class {
    func didTapDelete()
    func didTapRefile()
}

private class ActionsView: UIView {
    fileprivate let deleteButton: UIButton = UIButton()
    fileprivate let refileButton: UIButton = UIButton()
    fileprivate weak var delegate: ActionsViewDelegate?
    
    fileprivate init() {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background2
        
        self.addSubview(self.deleteButton)
        self.addSubview(self.refileButton)
        
        self.deleteButton.translatesAutoresizingMaskIntoConstraints = false
        self.refileButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.deleteButton.sideAnchor(for: [.top, .bottom, .left], to: self, edgeInsets: .zero)
        self.refileButton.sideAnchor(for: [.top, .bottom, .right], to: self, edgeInsets: .zero)
        self.deleteButton.rightAnchor.constraint(equalTo: self.refileButton.leftAnchor).isActive = true
        self.deleteButton.widthAnchor.constraint(equalTo: self.refileButton.widthAnchor).isActive = true
        
        self.setBorder(position: Border.Position.centerV, color: InterfaceTheme.Color.descriptive, width: 1)
    }
}
