//
//  BrowserListCell.swift
//  x3Note
//
//  Created by ian luo on 2021/2/16.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import RxSwift

public class BrowserListCell: BrowserCell, BrowserCellProtocol {
    public static let reuseIdentifier: String = "BrowserListCell"
    
    public let iconView: UIImageView = {
        let imageView = UIImageView()

        imageView.interface { (me, theme) in
            me.backgroundColor = theme.color.background2
        }
        
        imageView.roundConer(radius: Layout.cornerRadius)
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    public let titleLabel: UILabel = {
        let label = LabelStyle.title.create()
        label.numberOfLines = 0
        return label
    }()
    
    public let lastModifiedDateLabel: UILabel = {
        let label = LabelStyle.description.create()
        return label
    }()
    
    public var actionButton: RoundButton = RoundButton()
    public let actionsContainerView: UIView = UIView()
    
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {        
        self.container.addSubview(self.iconView)
        self.container.addSubview(self.titleLabel)
        self.container.addSubview(self.actionsContainerView)
        self.container.addSubview(self.lastModifiedDateLabel)
        
        self.interface { [weak self] (me, theme) in
            let cell = me as! BrowserListCell
            cell.backgroundColor = theme.color.background1
            cell.titleLabel.textColor = theme.color.interactive
            cell.titleLabel.font = theme.font.title
            cell.contentView.backgroundColor = theme.color.background1
            self?.container.backgroundColor = theme.color.background2
            self?.lastModifiedDateLabel.textColor = theme.color.descriptive
            self?.lastModifiedDateLabel.font = theme.font.footnote
        }
        
        self.iconView.sideAnchor(for: [.left, .top, .bottom],
                                 to: self.container,
                                 edgeInsets: .init(top: 10, left: 10, bottom: -10, right: 0))
        self.iconView.ratioAnchor(2.0 / 3)
        self.iconView.sizeAnchor(height: 100)
        
        self.iconView.rowAnchor(view: self.titleLabel, space: 10, alignment: .top)
        self.titleLabel.sideAnchor(for: [.top],
                                   to: self.container,
                                   edgeInsets: .init(top: 10, left: 0, bottom: -10, right: 0))
        
        self.titleLabel.rowAnchor(view: self.actionsContainerView, space: 10, alignment: .top)
        self.actionsContainerView.sideAnchor(for: [.top, .bottom, .right],
                                             to: self.container,
                                             edgeInsets: .init(top: 10, left: 0, bottom: 0, right: -10))
        
        self.iconView.rowAnchor(view: self.lastModifiedDateLabel, space: 10, alignment: .bottom)
        self.titleLabel.columnAnchor(view: self.lastModifiedDateLabel, space: 8, alignment: .leading)
        self.lastModifiedDateLabel.sizeAnchor(height: 14)
        

        self.container.roundConer(radius: Layout.cornerRadius)
        self.enableHover(on: self.container, hoverColor: isMac ? InterfaceTheme.Color.background3 : InterfaceTheme.Color.background2)
    }
    
    lazy var actionsViewWithTwoButtons: UIView = {
        let view = UIView()
        
        let actionButton = RoundButton()
        actionButton.isHidden = self.cellModel?.shouldShowActions == false
        actionButton.interface { (me, theme) in
            if let button = me as? RoundButton {
                actionButton.setIcon(Asset.SFSymbols.ellipsis.image.fill(color: theme.color.descriptive), for: .normal)
                actionButton.setBackgroundColor(theme.color.background2, for: .normal)
            }
        }
        actionButton.tapped { [weak self] view in
            guard let strongSelf = self else { return }
            strongSelf.onPresentingModalViewController.onNext((strongSelf.actionViewController, view))
        }
        
        self.actionButton = actionButton
        
        let enterButton = UIButton()
        enterButton.interface { (me, theme) in
            if let button = me as? UIButton {
                if isMac {
                    button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
                } else {
                    button.setBackgroundImage(UIImage.create(with: theme.color.background3, size: .singlePoint), for: .normal)
                }
                
                button.setImage(Asset.SFSymbols.arrowRight.image.fill(color: theme.color.interactive), for: .normal)
            }
        }
        
        enterButton.roundConer(radius: 10)
        
        enterButton.rx.tap.subscribe(onNext: { [weak self] in
            if let cellModel = self?.cellModel {
                self?.onEnter.onNext(cellModel.url)
            }
        }).disposed(by: self.disposeBag)
        
        view.addSubview(actionButton)
        view.addSubview(enterButton)
        actionButton.sideAnchor(for: [.left, .top, .right], to: view, edgeInset: 0)
        actionButton.sizeAnchor(width: 49)
        actionButton.columnAnchor(view: enterButton)
        enterButton.sideAnchor(for: [.left, .bottom, .right], to: view, edgeInsets: .init(top: 0, left: 0, bottom: -5, right: -5))
        enterButton.sizeAnchor(width: 44, height: 44)
        return view
    }()
    
    func loadActionsView() {
        self.actionsContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        if self.cellModel?.hasSubDocuments == true {
            self.actionsContainerView.addSubview(self.actionsViewWithTwoButtons)
            self.actionsViewWithTwoButtons.allSidesAnchors(to: self.actionsContainerView, edgeInset: 0)
        } else {
            self.actionsContainerView.addSubview(self.actionsViewWithOneButton)
            self.actionsViewWithOneButton.allSidesAnchors(to: self.actionsContainerView, edgeInset: 0)
        }
    }
    
    lazy var actionsViewWithOneButton: UIView = {
        let view = UIView()
        
        let actionButton = RoundButton()
        actionButton.isHidden = self.cellModel?.shouldShowActions == false
        actionButton.interface { (me, theme) in
            if let button = me as? RoundButton {
                button.setIcon(Asset.SFSymbols.ellipsis.image.fill(color: theme.color.descriptive), for: .normal)
                button.setBackgroundColor(theme.color.background2, for: .normal)
            }
        }
        actionButton.tapped { [weak self] view in
            guard let strongSelf = self else { return }
            strongSelf.actionViewController.fromView = view
            strongSelf.onPresentingModalViewController.onNext((strongSelf.actionViewController, view))
        }
        
        self.actionButton = actionButton
        
        view.addSubview(actionButton)
        actionButton.sizeAnchor(width: 44)
        view.sizeAnchor(width: 44)
        actionButton.centerAnchors(position: [.centerX, .centerY], to: view)
        
        return view
    }()
    
    public func configure(cellModel: BrowserCellModel) {
        self.reuseDisposeBag = DisposeBag() // this line is important, if missed, the cell might bind multiple times
        
        self.cellModel = cellModel
        
        self.titleLabel.text = cellModel.url.packageName
        self.iconView.image = cellModel.cover ?? Asset.Assets.smallIcon.image
        self.lastModifiedDateLabel.text = cellModel.updateDate.format(DateFormatter.Style.short, timeStyle: DateFormatter.Style.short)
                
        self.loadActionsView()
        
        super.showAsFolder(cellModel.hasSubDocuments)
                
        if cellModel.downloadingProcess < 100 {
            self.iconView.showProcessingAnimation()
        } else {
            self.iconView.hideProcessingAnimation()
        }
    }
}
