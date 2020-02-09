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

public class AttachmentManagerCell: UICollectionViewCell {
    public static let reuseIdentifier: String = "AttachmentManagerCell"
    
    var cellModel: AttachmentManagerCellModel?
    
    private let disposeBag = DisposeBag()
    
    public private(set) var reuseDisposeBag = DisposeBag()
    
    public let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.imageView)
        
        self.imageView.allSidesAnchors(to: self.contentView, edgeInset: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(cellModel: AttachmentManagerCellModel) {
        cellModel.attachment.subscribe(onNext: { attachment in
            self.contentView.hideProcessingAnimation()
            
            
        }).disposed(by: self.disposeBag)
        
        if cellModel.attachment.value == nil {
            self.contentView.showProcessingAnimation()
        }
    }
    
    public override func prepareForReuse() {
        self.reuseDisposeBag = DisposeBag()
    }
}
