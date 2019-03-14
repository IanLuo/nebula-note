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
import CoreLocation

public protocol CaptureTableCellDelegate: class {
    func didTapActions(attachment: Attachment)
    func didTapActionsWithLink(attachment: Attachment, link: String?)
    func didTapActionsWithLocation(attachment: Attachment, location: CLLocationCoordinate2D)
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
    
    private lazy var actionsButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = InterfaceTheme.Font.body
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        button.setImage(Asset.Assets.more.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        return button
    }()
    
    private let actionsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let attachmentContentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
        
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background1
        
        self.contentView.addSubview(self.attachmentContentView)
        self.contentView.addSubview(self.actionsContainerView)
        
        self.actionsContainerView.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 30, bottom: 0, right: -30))
        self.actionsContainerView.sizeAnchor(height: 60)
        
        self.actionsContainerView.addSubview(self.titleLabel)
        self.titleLabel.sideAnchor(for: [.left, .top, .bottom], to: self.actionsContainerView, edgeInset: 0)
        
        self.actionsContainerView.addSubview(self.actionsButton)
        self.actionsButton.sideAnchor(for: [.top, .right, .bottom], to: self.actionsContainerView, edgeInset: 0)
        self.actionsButton.sizeAnchor(width: 60, height: 60)
        
        self.actionsContainerView.columnAnchor(view: self.attachmentContentView)
        self.attachmentContentView.sideAnchor(for: [.left, .bottom, .right], to: self.contentView, edgeInset: 30)
    }
    
    private func setupAttachmentUI(attachmentView: AttachmentViewType) {
        self.titleLabel.text = attachmentView.attachment.kind.rawValue
        self.attachmentContentView.addSubview(attachmentView)
        attachmentView.allSidesAnchors(to: self.attachmentContentView, edgeInset: 0)
    }
    
    @objc private func didTapActionButton() {
        guard let attachment = self.cellModel?.attachmentView.attachment else { return }
        switch attachment.kind {
        case .link:
            do {
                let jsonDecoder = JSONDecoder()
                let dic = try jsonDecoder.decode([String : String].self, from: try Data(contentsOf: attachment.url))
                self.delegate?.didTapActionsWithLink(attachment: attachment, link: dic["link"])
            } catch {
                log.error(error)
            }
        case .location:
            do {
                let jsonDecoder = JSONDecoder()
                let coord = try jsonDecoder.decode(CLLocationCoordinate2D.self, from: try Data(contentsOf: attachment.url))
                self.delegate?.didTapActionsWithLocation(attachment: attachment, location: coord)
            } catch {
                log.error(error)
            }
        default: self.delegate?.didTapActions(attachment: attachment)
        }
    }
    
    public override func prepareForReuse() {
        self.titleLabel.text = ""
        self.attachmentContentView.subviews.forEach { $0.removeFromSuperview() }
    }
}
