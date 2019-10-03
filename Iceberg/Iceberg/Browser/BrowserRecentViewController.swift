//
//  DocumentBrowserRecentViewController.swift
//  Iceberg
//
//  Created by ian luo on 2019/9/12.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import RxSwift
import RxCocoa
import RxDataSources

public class BrowserRecentViewController: UIViewController {
    
    public struct Output {
        public let choosenDocument: PublishSubject<URL> = PublishSubject()
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        
        collectionView.interface({ (me, theme) in
            let collectionView = me as! UICollectionView
            collectionView.backgroundColor = InterfaceTheme.Color.background1
        })
        
        collectionView.register(RecentFileCell.self, forCellWithReuseIdentifier: RecentFileCell.reuseIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right)
        
        return collectionView
    }()
    
    private var viewModel: BrowserRecentViewModel!
    
    private let disposeBag = DisposeBag()
    
    public let output: Output = Output()
    
    public convenience init(viewModel: BrowserRecentViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    public override func viewDidLoad() {
        self.view.addSubview(self.collectionView)
        self.collectionView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<RecentDocumentSection>(configureCell: { (dataSource, collectionView, indexPath, cellModel) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentFileCell.reuseIdentifier, for: indexPath) as! RecentFileCell
            cell.configure(cellModel: cellModel)
            return cell
        })
        
        self.viewModel
            .output
            .recentDocuments
            .asDriver(onErrorJustReturn: [])
            .drive(self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: self.disposeBag)
        
        self.collectionView
            .rx
            .modelSelected(BrowserCellModel.self)
            .map { $0.url }
            .bind(to: self.output.choosenDocument)
            .disposed(by: self.disposeBag)
        
        self.viewModel.loadData()
    }
}

extension BrowserRecentViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.height * 2 / 3, height: collectionView.bounds.height)
    }
}


// MARK: - cell -

private class RecentFileCell: UICollectionViewCell {
    static let reuseIdentifier: String = "RecentFileCell"
    
    let coverView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.textColor = theme.color.interactive
            label.font = theme.font.footnote
        })
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(cellModel: BrowserCellModel) {
        self.titleLabel.text = cellModel.url.packageName
        self.coverView.image = cellModel.cover
    }
    
    private func setupUI() {
        self.interface { [weak self] (me, theme) in
            self?.contentView.backgroundColor = InterfaceTheme.Color.background2
        }
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.masksToBounds = true
        self.contentView.addSubview(self.coverView)
        self.contentView.addSubview(self.titleLabel)
        
        self.coverView.allSidesAnchors(to: self.contentView, edgeInset: 0)
        self.titleLabel.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 5)
        self.titleLabel.centerAnchors(position: .centerY, to: self.contentView)
    }
}
