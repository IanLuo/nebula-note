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
        collectionView.delegate = self
        
        collectionView.interface({ (me, theme) in
            let collectionView = me as! UICollectionView
            collectionView.backgroundColor = InterfaceTheme.Color.background1
        })
        
        collectionView.register(RecentFileCell.self, forCellWithReuseIdentifier: RecentFileCell.reuseIdentifier)
        collectionView.register(RecentDocumentsHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: Layout.edgeInsets.right)
        
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
        
        self.view.roundConer(radius: Layout.cornerRadius)
        
        self.interface { [weak self] me, theme in
            self?.view.border(color: theme.color.background2, width: 1)
        }
        
        let dataSource = RxCollectionViewSectionedReloadDataSource<RecentDocumentSection>(configureCell: { (dataSource, collectionView, indexPath, cellModel) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecentFileCell.reuseIdentifier, for: indexPath) as! RecentFileCell
            cell.configure(cellModel: cellModel)
            return cell
        }, configureSupplementaryView: { dataSource, collectionView, string, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: string, withReuseIdentifier: "header", for: indexPath) as! RecentDocumentsHeader
            header.titleLabel.text = "Recent Documents"
            return header
        })
        
        self.viewModel
            .output
            .recentDocuments
            .asDriver(onErrorJustReturn: [])
            .drive(self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: self.disposeBag)
        
        self.viewModel
            .output
            .recentDocuments
            .subscribe(onNext: { [weak self] sections in
                self?.showEmptyContentImage(sections.first?.items.count == 0)
            })
            .disposed(by: self.disposeBag)
        
        self.collectionView
            .rx
            .modelSelected(BrowserCellModel.self)
            .map { $0.url }
            .bind(to: self.output.choosenDocument)
            .disposed(by: self.disposeBag)
        
        self.viewModel.loadData()
        
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification).subscribe(onNext: { _ in
            NSFileCoordinator.removeFilePresenter(self.viewModel)
        }).disposed(by: self.disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).subscribe(onNext: { _ in
            self.viewModel.loadData()
            NSFileCoordinator.addFilePresenter(self.viewModel)
        }).disposed(by: self.disposeBag)
    }
}

class RecentDocumentsHeader: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.titleLabel)
        self.titleLabel.allSidesAnchors(to: self, edgeInset: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        
        label.interface { (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.body
        }
        
        return label
    }()
}

extension BrowserRecentViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height - 20
        let width = height * 2 / 3
        return CGSize(width: width, height: height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
}


// MARK: - cell -

private class RecentFileCell: UICollectionViewCell {
    static let reuseIdentifier: String = "RecentFileCell"
    
    let coverView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.shadowOffset = CGSize(width: 1, height: 1)
        
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.shadowColor = theme.color.background1.withAlphaComponent(0.6)
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
        
        self.roundConer(radius: Layout.cornerRadius)
        self.contentView.addSubview(self.coverView)
        self.contentView.addSubview(self.titleLabel)
        
        self.coverView.allSidesAnchors(to: self.contentView, edgeInset: 0)
        self.titleLabel.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 5)
        self.titleLabel.sideAnchor(for: [.top, .bottom], to: self.contentView, edgeInset: 2)
        
        self.enableHover(on: self.contentView)
    }
}

extension BrowserRecentViewController: EmptyContentPlaceHolderProtocol {
    public var image: UIImage {
        return Asset.Assets.smallIcon.image.fill(color: InterfaceTheme.Color.secondaryDescriptive).resize(upto: CGSize(width: 15, height: 15))
    }
    
    public var text: String {
        return L10n.Selector.empty
    }
    
    public var viewToShowImage: UIView {
        return self.collectionView
    }
}
