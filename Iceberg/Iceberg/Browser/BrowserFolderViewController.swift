//
//  DocumentBrowserFolderViewController.swift
//  Iceberg
//
//  Created by ian luo on 2019/9/12.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Interface
import Core

fileprivate enum ViewMode {
    case listSmall, icon
    
    var title: String {
        switch self {
        case .listSmall: return L10n.Browser.Mode.list
        case .icon: return L10n.Browser.Mode.icon
        }
    }
}

public class BrowserFolderViewController: UIViewController {
    
    public struct Output {
        public let onSelectDocument: PublishSubject<URL> = PublishSubject()
    }
    
    public var viewModel: BrowserFolderViewModel!
    public let output: Output = Output()
    
    public convenience init(viewModel: BrowserFolderViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    private let collectionMode: BehaviorRelay<ViewMode> = BehaviorRelay(value: .icon)
    
    public lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.register(BrowserListCell.self, forCellWithReuseIdentifier: BrowserListCell.reuseIdentifier)
        collectionView.register(BrowserCellIcon.self, forCellWithReuseIdentifier: BrowserCellIcon.reuseIdentifier)
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        collectionView.delegate = self
        collectionView.interface { (view, theme) in
            view.backgroundColor = theme.color.background1
        }
        
        return collectionView
    }()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.definesPresentationContext = true
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        return searchController
    }()
    
    public let addDocumentButton: UIButton = {
        let button = UIButton()
        
        button.interface { (me, theme) in
            guard let button = me as? UIButton else { return }
            button.setImage(Asset.SFSymbols.plus.image.fill(color: theme.color.interactive), for: .normal)
        }
        
        return button
    }()
    
    var reuseIdentifier: String {
        switch self.collectionMode.value {
        case .listSmall:
            return BrowserListCell.reuseIdentifier
        case .icon:
            return BrowserCellIcon.reuseIdentifier
        }
    }
    
//    private let present: PublishSubject<UIViewController> = PublishSubject()
    private let tableCellMoved: PublishSubject<(URL, URL)> = PublishSubject()
    private let tableCellUpdate: PublishSubject<URL> = PublishSubject()
    private let tableCellDeleted: PublishSubject<URL> = PublishSubject()
    private let tableCellInserted: PublishSubject<URL> = PublishSubject()
    private let enter: PublishSubject<URL> = PublishSubject()
    
    private let disposeBag = DisposeBag()
    
    public override func viewDidLoad() {
        self.view.addSubview(self.collectionView)
        self.collectionView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self.navigationItem.searchController = self.searchController
        
        switch viewModel.mode {
        case .browser, .chooser:
        // bind add document button
        let createDocumentBarButtonItem = UIBarButtonItem(image: Asset.SFSymbols.docBadgePlus.image, style: .plain, target: nil, action: nil)
        createDocumentBarButtonItem.rx
            .tap
            .map { _ in L10n.Browser.Title.untitled } // use default documentname
            .bind(to: self.viewModel.input.addDocument)
            .disposed(by: self.disposeBag)
            
            let actionsBarButton = UIButton().interface { (me, theme) in
                let button = me as! UIButton
                button.image(Asset.SFSymbols.ellipsis.image.fill(color: theme.color.spotlight), for: .normal)
            }
            let actionsBarButtonItem = UIBarButtonItem(customView: actionsBarButton)
            actionsBarButton.rx.tap.subscribe(onNext: { [unowned actionsBarButton] in
                self.showActions(from: actionsBarButton)
            }).disposed(by: self.disposeBag)
            
            
            switch self.viewModel.dataMode! {
            case .browser:
                self.navigationItem.rightBarButtonItems = [actionsBarButtonItem, createDocumentBarButtonItem]
            case .recent:
                self.navigationItem.rightBarButtonItems = [actionsBarButtonItem]
            }
        
        self.interface { (me, theme) in
            createDocumentBarButtonItem.tintColor = theme.color.spotlight
        }
        case .favorite: break
        }
                
        self._setupObserver()
        
        self.viewModel.reload()
    }
    
    private func _setupObserver() {
        switch self.viewModel.dataMode! {
        case .browser:
            // bind title from foldler name
            self.viewModel.title.asDriver(onErrorJustReturn: "").drive(self.rx.title).disposed(by: self.disposeBag)
        case .recent:
            break
        }

        let configureCell: RxCollectionViewSectionedAnimatedDataSource<BrowserDocumentSection>.ConfigureCell = { (datasource, collectionView, indexPath, cellModel) -> UICollectionViewCell in
            var cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) as! BrowserCell
            
            if cellModel.hasSubDocuments {
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) as! BrowserCell
            }
            
            cell.cellModel = cellModel
            
            if let cell = cell as? BrowserCellProtocol {
                cell.configure(cellModel: cellModel)
            }
                        
            cell.onPresentingModalViewController
                .asObserver()
                .observeOn(MainScheduler())
                .subscribe(onNext: { [weak self] (viewController, view) in
                    guard let strongSelf = self else { return }
                    if let transitionController = viewController as? TransitionViewController {
                        transitionController.present(from: strongSelf, at: view)
                    } else {
                        self?.present(viewController, animated: true)
                    }
                })
                .disposed(by: cell.reuseDisposeBag)

            cell.onMoveDocument.bind(to: self.tableCellMoved).disposed(by: cell.reuseDisposeBag)
            cell.onCreateSubDocument.do(onNext: { _ in self.enterChild(url: cellModel.url)}).bind(to: self.tableCellInserted).disposed(by: cell.reuseDisposeBag)
            cell.onChangeCover.bind(to: self.tableCellUpdate).disposed(by: cell.reuseDisposeBag)
            cell.onDeleteDocument.bind(to: self.tableCellDeleted).disposed(by: cell.reuseDisposeBag)
            cell.onRenameDocument.bind(to: self.tableCellUpdate).disposed(by: cell.reuseDisposeBag)
            cell.onDuplicateDocument.bind(to: self.tableCellInserted).disposed(by: cell.reuseDisposeBag)
            cell.onEnter.bind(to: self.enter).disposed(by: cell.reuseDisposeBag)
            
            return cell
        }
        
        let datasource = RxCollectionViewSectionedAnimatedDataSource<BrowserDocumentSection>(configureCell: configureCell)
        
        self.viewModel
            .output
            .documents
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { [weak self] in
                self?.showEmptyContentImage($0.first?.items.count == 0)
            })
            .drive(self.collectionView.rx.items(dataSource: datasource))
            .disposed(by: self.disposeBag)
        
        self.collectionView
            .rx
            .modelSelected(BrowserCellModel.self)
            .subscribe(onNext: { [weak self] cellModel in
                self?.output.onSelectDocument.onNext(cellModel.url)
            })
            .disposed(by: self.disposeBag)
        
        self.collectionView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.collectionView.deselectItem(at: indexPath, animated: true)
            }).disposed(by: self.disposeBag)
        
        self.tableCellUpdate
            .subscribe(onNext: { [weak self] _ in self?.viewModel.reload() })
            .disposed(by: self.disposeBag)
        
        self.tableCellDeleted
            .subscribe(onNext: { [weak self] _ in self?.viewModel.reload() })
            .disposed(by: self.disposeBag)
        
        self.tableCellInserted
            .subscribe(onNext: { [unowned self] _ in self.viewModel.reload() })
            .disposed(by: self.disposeBag)
        
        self.tableCellMoved
            .subscribe(onNext: { [unowned self] _ in self.viewModel.reload() })
            .disposed(by: self.disposeBag)
        
        self.viewModel
            .output
            .onCreatededDocument
            .subscribe(onNext: { [weak self] url in
                if let indexPath = self?.viewModel.indexPath(for: url) {
                    self?.collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
                
        self.enter
            .subscribe(onNext: { [weak self] url in
                self?.enterChild(url: url)
            })
            .disposed(by: self.disposeBag)
        
//        self.present.subscribe(onNext: { [weak self] viewController in
//            guard let strongSelf = self else { return }
//            if let transitionController = viewController as? TransitionViewController {
//                transitionController.present(from: strongSelf)
//            } else {
//                self?.present(viewController, animated: true)
//            }
//        }).disposed(by: self.disposeBag)
    }
    
    private func showActions(from: UIView) {
        let selector = SelectorViewController()
        
        selector.addItem(title: ViewMode.listSmall.title)
        selector.addItem(title: ViewMode.icon.title)
        selector.currentTitle = self.collectionMode.value.title
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true) {
                switch index {
                case 0: self.collectionMode.accept(.listSmall)
                case 1: self.collectionMode.accept(.icon)
                default: break
                }
                
                self.collectionView.reloadData()
                self.viewModel.showGlobalCaptureEntry()
            }
        }
                    
        self.viewModel.hideGlobalCaptureEntry()
        
        selector.present(from: self, at: from)
    }
    
    private func enterChild(url: URL) {
        let viewModel = BrowserFolderViewModel(url: url, mode: self.viewModel.mode, coordinator: self.viewModel.context.coordinator!, dataMode: .browser)
        let viewController = BrowserFolderViewController(viewModel: viewModel)
        
        viewController.collectionMode.accept(self.collectionMode.value)
        
        // pass selection to parent
        viewController.output.onSelectDocument.bind(to: self.output.onSelectDocument).disposed(by: viewController.disposeBag)
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension BrowserFolderViewController: UISearchResultsUpdating, UISearchBarDelegate {
    public func updateSearchResults(for searchController: UISearchController) {
        if searchController.searchBar.isFirstResponder {
            self.viewModel.udpateSearchString(searchController.searchBar.text ?? "")
        }
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.viewModel.reload()
    }
}

extension BrowserFolderViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch self.collectionMode.value {
        case .listSmall:
            return CGSize(width: collectionView.frame.width, height: 130)
        case .icon:
            return CGSize(width: 100, height: 130)
        }
    }
        
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 150, right: Layout.edgeInsets.right)
    }
}

extension BrowserFolderViewController: EmptyContentPlaceHolderProtocol {
    public var text: String {
        return L10n.Browser.empty
    }
    
    public var image: UIImage {
        return Asset.Assets.smallIcon.image.fill(color: InterfaceTheme.Color.secondaryDescriptive)
    }
    
    public var viewToShowImage: UIView {
        return self.collectionView
    }
}
