//
//  AttachmentManagerCell.swift
//  x3
//
//  Created by ian luo on 2020/2/8.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Core
import Interface

public class AttachmentManagerCell: UICollectionViewCell {
    public static let reuseIdentifier: String = "AttachmentManagerCell"
    
    var cellModel: AttachmentManagerCellModel?
    
    private let disposeBag = DisposeBag()
    
    public private(set) var reuseDisposeBag = DisposeBag()
    
    let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    
    public var shouldShowSelection: Bool {
        set { self.checkmarkImageView.isHidden = !newValue }
        get { return !self.checkmarkImageView.isHidden }
    }
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        imageView.layer.borderColor = InterfaceTheme.Color.background2.cgColor
        imageView.layer.borderWidth = 1
        imageView.backgroundColor = InterfaceTheme.Color.background1
        return imageView
    }()
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = InterfaceTheme.Font.footnote
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.imageView)
        
        self.imageView.allSidesAnchors(to: self.contentView, edgeInset: 0)
        
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 0)
        
        self.contentView.addSubview(self.checkmarkImageView)
        self.checkmarkImageView.sideAnchor(for: [.left, .top], to: self.contentView, edgeInset: 12)
        self.checkmarkImageView.sizeAnchor(width: 20, height: 20)
        self.checkmarkImageView.layer.cornerRadius = 10
        self.checkmarkImageView.backgroundColor = InterfaceTheme.Color.background1
        self.checkmarkImageView.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(cellModel: AttachmentManagerCellModel) {
        cellModel.image.subscribeOn(MainScheduler()).subscribe(onNext: { image in
            DispatchQueue.runOnMainQueueSafely {
                self.imageView.image = image
                self.contentView.hideProcessingAnimation()
            }
        }).disposed(by: self.reuseDisposeBag)
        
        switch cellModel.attachment.kind {
        case .video, .audio:
            self.titleLabel.text = "\(cellModel.attachment.durationString) \n \(cellModel.attachment.sizeString) \n \(cellModel.attachment.date.shortDateString)"
        default:
            self.titleLabel.text = "\(cellModel.attachment.sizeString) \n \(cellModel.attachment.date.shortDateString)"
        }
        
        
        if cellModel.image.value == nil {
            self.contentView.showProcessingAnimation()
        }
        
        cellModel.isChoosen.subscribe(onNext: { isSelected in
            self.checkmarkImageView.image = isSelected ? Asset.SFSymbols.checkmark.image.fill(color: InterfaceTheme.Color.spotlitTitle).resize(upto: CGSize(width: 15, height: 15)) : nil
            self.checkmarkImageView.backgroundColor = isSelected ? InterfaceTheme.Color.spotlight : InterfaceTheme.Color.background1
        }).disposed(by: self.reuseDisposeBag)
    }
    
    public override func prepareForReuse() {
        self.reuseDisposeBag = DisposeBag()
        self.checkmarkImageView.image = nil
    }
}
