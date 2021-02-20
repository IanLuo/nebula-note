//
//  BrowserCellIcon.swift
//  x3Note
//
//  Created by ian luo on 2021/2/17.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Interface

public class BrowserCellIcon: BrowserCell, BrowserCellProtocol {
    public static let reuseIdentifier: String = "BrowserCellIcon"
    
    public func configure(cellModel: BrowserCellModel) {
        self.reuseDisposeBag = DisposeBag()
        
        self.titleLabel.text = cellModel.url.packageName
        self.icon.image = cellModel.cover
        self.enterButton.isHidden = self.cellModel?.hasSubDocuments == false
        
        super.showAsFolder(cellModel.hasSubDocuments)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let titleLabel: UILabel = UILabel()
    
    let enterButton: UIButton = UIButton()
        
    let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        self.container.interface { (me, theme) in
            me.backgroundColor = theme.color.background2
        }
        
        self.titleLabel.interface { (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.interactive
            label.font = theme.font.body
            label.textAlignment = .center
        }
        
        let actionButton = UIButton().interface({ (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.SFSymbols.ellipsis.image.fill(color: theme.color.interactive).resize(upto: CGSize(width: 20, height: 20)), for: .normal)
        })
        
        self.enterButton.interface({ (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.SFSymbols.arrowRight.image.fill(color: theme.color.interactive).resize(upto: CGSize(width: 20, height: 20)), for: .normal)
        })
        
        actionButton.rx.tap.subscribe(onNext: { [unowned actionButton] button in
            super.actionViewController.fromView = actionButton
            self.onPresentingModalViewController.onNext((super.actionViewController, actionButton))
            self.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.hide()
        }).disposed(by: self.disposeBag)
        
        self.enterButton.rx.tap.subscribe(onNext: { [weak self] in
            if let cellModel = self?.cellModel {
                self?.onEnter.onNext(cellModel.url)
            }
        }).disposed(by: self.disposeBag)
                
        self.container.addSubview(self.icon)
        icon.sideAnchor(for: [.top, .left, .right], to: self.container, edgeInset: 0)
        
        let actionsView
            = Padding(child: UIStackView(subviews: [actionButton, enterButton]), all: 5)
            .interface({ (me, theme) in
                me.backgroundColor = theme.color.background3
            })

        self.container.addSubview(actionsView)
        actionsView.sizeAnchor(height: 34)
        actionsView.sideAnchor(for: [.bottom, .left, .right], to: self.container, edgeInset: 0)
        
        self.icon.columnAnchor(view: actionsView)
        
        self.container.addSubview(self.titleLabel.numberOfLines(0).interface({ (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.interactive
            label.font = theme.font.footnote
            label.layer.shadowColor = UIColor.black.cgColor
            label.layer.shadowOffset = CGSize(width: 1, height: 1)
            label.layer.shadowOpacity = 0.8
            label.layer.shadowRadius = 2
        }))
        self.titleLabel.bottomAnchor.constraint(equalTo: actionsView.topAnchor, constant: -5).isActive = true
        self.titleLabel.sideAnchor(for: [.left, .right], to: self.container, edgeInset: 10)
    }
}
