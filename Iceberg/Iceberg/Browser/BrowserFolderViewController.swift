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
import Business

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
    
    public let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(BrowserCell.self, forCellReuseIdentifier: BrowserCell.reuseIdentifier)
        tableView.register(BrowserCellWithSubFolder.self, forCellReuseIdentifier: BrowserCellWithSubFolder.reuseIdentifierForBrowserCellWithSubFolder)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.contentInset = .init(top: 0, left: 0, bottom: 120, right: 0)
        tableView.interface { (me, theme) in
            let tableView = me as! UITableView
            tableView.backgroundColor = theme.color.background1
        }
        return tableView
    }()
    
    public let addDocumentButton: UIButton = {
        let button = UIButton()
        
        button.interface { (me, theme) in
            guard let button = me as? UIButton else { return }
            button.setImage(Asset.Assets.add.image.fill(color: theme.color.interactive), for: .normal)
        }
        
        return button
    }()
    
    private let present: PublishSubject<UIViewController> = PublishSubject()
    private let tableCellMoved: PublishSubject<(URL, URL)> = PublishSubject()
    private let tableCellUpdate: PublishSubject<URL> = PublishSubject()
    private let tableCellDeleted: PublishSubject<URL> = PublishSubject()
    private let tableCellInserted: PublishSubject<URL> = PublishSubject()
    private let enter: PublishSubject<URL> = PublishSubject()
    
    private let disposeBag = DisposeBag()
    
    public override func viewDidLoad() {
        self.view.addSubview(self.tableView)
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        // bind add document button
        let rightBarButtonItem = UIBarButtonItem(image: Asset.Assets.newDocument.image, style: .plain, target: nil, action: nil)
        rightBarButtonItem.rx
            .tap
            .map { _ in L10n.Browser.Title.untitled } // use default documentname
            .bind(to: self.viewModel.input.addDocument)
            .disposed(by: self.disposeBag)
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        
        self.interface { (me, theme) in
            rightBarButtonItem.tintColor = theme.color.spotlight
        }
                
        self._setupObserver()
        
        self.viewModel.reload()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // make sure it's refreshed
        self.viewModel.reload()
    }
        
    private func _setupObserver() {
        // bind title from foldler name
        self.viewModel.title.asDriver(onErrorJustReturn: "").drive(self.rx.title).disposed(by: self.disposeBag)

        //bind table view
        let dataSource = RxTableViewSectionedReloadDataSource<BrowserDocumentSection>(configureCell: { [unowned self] (dataSource, tableView, indexPath, cellModel) -> UITableViewCell in
            var cell = tableView.dequeueReusableCell(withIdentifier: BrowserCell.reuseIdentifier, for: indexPath) as! BrowserCell
            
            if cellModel.hasSubDocuments {
                cell = tableView.dequeueReusableCell(withIdentifier: BrowserCellWithSubFolder.reuseIdentifierForBrowserCellWithSubFolder, for: indexPath) as! BrowserCell
            }
            
            cell.configure(cellModel: cellModel)
            cell.onPresentingModalViewController
                .asObserver()
                .observeOn(MainScheduler())
                .bind(to: self.present)
                .disposed(by: cell.reuseDisposeBag)

            cell.onMoveDocument.bind(to: self.tableCellMoved).disposed(by: cell.reuseDisposeBag)
            cell.onCreateSubDocument.do(onNext: { _ in self.enterChild(url: cellModel.url)}).bind(to: self.tableCellInserted).disposed(by: cell.reuseDisposeBag)
            cell.onChangeCover.bind(to: self.tableCellUpdate).disposed(by: cell.reuseDisposeBag)
            cell.onDeleteDocument.bind(to: self.tableCellDeleted).disposed(by: cell.reuseDisposeBag)
            cell.onRenameDocument.bind(to: self.tableCellUpdate).disposed(by: cell.reuseDisposeBag)
            cell.onDuplicateDocument.bind(to: self.tableCellInserted).disposed(by: cell.reuseDisposeBag)
            cell.onEnter.bind(to: self.enter).disposed(by: cell.reuseDisposeBag)
            
            return cell
        })

        self.viewModel
            .output
            .documents
            .asDriver(onErrorJustReturn: [])
            .do(onNext: { [weak self] in
                self?.showEmptyContentImage($0.first?.items.count == 0)
            })
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: self.disposeBag)
        
        self.tableView
            .rx
            .modelSelected(BrowserCellModel.self)
            .subscribe(onNext: { [weak self] cellModel in
                self?.output.onSelectDocument.onNext(cellModel.url)
            })
            .disposed(by: self.disposeBag)
        
        self.tableView
            .rx
            .itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
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
            .createdDocument
            .subscribe(onNext: { [unowned self] url in
                if let indexPath = self.viewModel.indexPath(for: url) {
                    self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                }
            })
            .disposed(by: self.disposeBag)
                
        self.enter
            .subscribe(onNext: { [unowned self] url in
                self.enterChild(url: url)
            })
            .disposed(by: self.disposeBag)
        
        self.present.subscribe(onNext: { [weak self] viewController in
            self?.present(viewController, animated: true)
        }).disposed(by: self.disposeBag)
    }
    
    private func enterChild(url: URL) {
        let viewModel = BrowserFolderViewModel(url: url, mode: self.viewModel.mode, coordinator: self.viewModel.context.coordinator!)
        let viewController = BrowserFolderViewController(viewModel: viewModel)
        
        // pass selection to parent
        viewController.output.onSelectDocument.bind(to: self.output.onSelectDocument).disposed(by: viewController.disposeBag)
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}

extension BrowserFolderViewController: EmptyContentPlaceHolderProtocol {
    public var text: String {
        return L10n.Browser.empty
    }
    
    public var image: UIImage {
        return Asset.Assets.emptyCup.image.fill(color: InterfaceTheme.Color.secondaryDescriptive)
    }
    
    public var viewToShowImage: UIView {
        return self.tableView
    }
}
