//
//  AttachmentManagerCell.swift
//  Icetea
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
        self.checkmarkImageView.backgroundColor = UIColor.white
        self.checkmarkImageView.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var isSelected: Bool {
        didSet {
            self.checkmarkImageView.image = isSelected ? Asset.Assets.checkMark.image.fill(color: InterfaceTheme.Color.spotlitTitle).resize(upto: CGSize(width: 15, height: 15)) : nil
            self.checkmarkImageView.backgroundColor = isSelected ? InterfaceTheme.Color.spotlight : InterfaceTheme.Color.background1
        }
    }
    
    public func configure(cellModel: AttachmentManagerCellModel) {
        cellModel.image.subscribe(onNext: { image in
            self.imageView.image = image
            self.contentView.hideProcessingAnimation()
        }).disposed(by: self.reuseDisposeBag)
        
        cellModel.attachment
            .skipWhile { $0 == nil }
            .subscribe(onNext: { attachment in
                let attachment = attachment!
                switch attachment.kind {
                case .video, .audio:
                    self.titleLabel.text = "\(attachment.durationString) \n \(attachment.sizeString) \n \(attachment.date.shortDateString)"
                default:
                    self.titleLabel.text = "\(attachment.sizeString) \n \(attachment.date.shortDateString)"
                }
        }).disposed(by: self.disposeBag)
        
        if cellModel.attachment.value == nil {
            self.contentView.showProcessingAnimation()
        }
    }
    
    public override func prepareForReuse() {
        self.reuseDisposeBag = DisposeBag()
        self.checkmarkImageView.image = nil
    }
}
