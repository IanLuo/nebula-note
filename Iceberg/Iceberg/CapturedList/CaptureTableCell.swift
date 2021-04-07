//
//  CaptureTableCell.swift
//  Iceland
//
//  Created by ian luo on 2018/12/28.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import CoreLocation
import Interface

public protocol CaptureTableCellDelegate: class {
    func didTapActions(attachment: Attachment, from: UIView)
    func didTapActionsWithLink(attachment: Attachment, link: String?, from: UIView)
    func didTapActionsWithLocation(attachment: Attachment, location: CLLocationCoordinate2D, from: UIView)
}

public class CaptureTableCell: UICollectionViewCell {
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
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.title
            label.textColor = theme.color.descriptive
        })
        return label
    }()
    
    private var dateAndTimelabel: UILabel = {
        let label = UILabel()
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.callout
            label.textColor = theme.color.descriptive
        })
        return label
    }()
    
    private let actionsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let attachmentContentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        
        view.interface({ (me, theme) in
            me.backgroundColor = InterfaceTheme.Color.background2
        })
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
        
        self.enableHover(on: self.attachmentContentView, hoverColor: InterfaceTheme.Color.background3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.interface { (me, theme) in
            me.backgroundColor = InterfaceTheme.Color.background1
        }
        
        self.contentView.addSubview(self.attachmentContentView)
        self.contentView.addSubview(self.actionsContainerView)
        
        self.actionsContainerView.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 30, bottom: 0, right: -30))
        self.actionsContainerView.sizeAnchor(height: 60)
        
        self.actionsContainerView.addSubview(self.titleLabel)
        self.titleLabel.sideAnchor(for: [.left, .top, .bottom], to: self.actionsContainerView, edgeInset: 0)
        
        self.actionsContainerView.addSubview(self.dateAndTimelabel)
        self.titleLabel.rowAnchor(view: self.dateAndTimelabel, space: 10)
        self.dateAndTimelabel.sideAnchor(for: [.bottom, .right], to: self.actionsContainerView, edgeInset: 0)
                
        self.actionsContainerView.columnAnchor(view: self.attachmentContentView)
        self.attachmentContentView.sideAnchor(for: [.left, .bottom, .right], to: self.contentView, edgeInset: 30)
    }
    
    private func setupAttachmentUI(attachmentView: AttachmentViewType) {
        self.titleLabel.text = attachmentView.attachment.kind.name
            + (attachmentView.attachment.duration != nil ? "(\(attachmentView.attachment.durationString))" : "")
        self.dateAndTimelabel.text = attachmentView.attachment.date.shortDateString
        
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
                self.delegate?.didTapActionsWithLink(attachment: attachment, link: dic["link"], from: self)
            } catch {
                log.error(error)
                self.delegate?.didTapActions(attachment: attachment, from: self)
            }
        case .location:
            do {
                let jsonDecoder = JSONDecoder()
                let coord = try jsonDecoder.decode(CLLocationCoordinate2D.self, from: try Data(contentsOf: attachment.url))
                self.delegate?.didTapActionsWithLocation(attachment: attachment, location: coord, from: self)
            } catch {
                log.error(error)
                self.delegate?.didTapActions(attachment: attachment, from: self)
            }
        default: self.delegate?.didTapActions(attachment: attachment, from: self)
        }
    }
    
    public override func prepareForReuse() {
        self.titleLabel.text = ""
        self.attachmentContentView.subviews.forEach { $0.removeFromSuperview() }
    }
}
