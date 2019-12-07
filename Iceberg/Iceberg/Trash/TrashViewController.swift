//
//  TrashViewController.swift
//  Iceberg
//
//  Created by ian luo on 2019/12/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Interface

public class TrashViewController: UIViewController, UITableViewDelegate {
    private var viewModel: TrashViewModel!
    
    private let disposeBag = DisposeBag()
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.register(TrashCell.self, forCellReuseIdentifier: TrashCell.reuseIdentifier)
        tableView.contentInset = .init(top: 0, left: 0, bottom: 120, right: 0)
        tableView.interface { (me, theme) in
            let tableView = me as! UITableView
            tableView.backgroundColor = theme.color.background1
        }
        tableView.delegate = self
        return tableView
    }()
    
    public convenience init(viewModel: TrashViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    public override func viewDidLoad() {
        self.view.addSubview(tableView)
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self.title = L10n.Trash.title
        
        let removeAllButtonItem = UIBarButtonItem(title: L10n.Trash.removeAll, style: .plain, target: nil, action: nil)
        removeAllButtonItem.rx.tap.subscribe(onNext: { [unowned self] _ in
            let confirmController = ConfirmViewController(contentText: L10n.Trash.Delete.warning, onConfirm: { viewControler in
                viewControler.dismiss(animated: true) {
                    self.viewModel.deleteAll()
                }
            }) { viewController in
                viewController.dismiss(animated: true)
            }
            
            confirmController.title = L10n.Trash.removeAll
            
            self.present(confirmController, animated: true)
        }).disposed(by: self.disposeBag)
        
        self.navigationItem.rightBarButtonItem = removeAllButtonItem
        
        let cancelButtonItem = UIBarButtonItem(image: Asset.Assets.down.image, style: .plain, target: nil, action: nil)
        cancelButtonItem.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewModel.context.coordinator?.stop()
        }).disposed(by: self.disposeBag)
        
        self.navigationItem.leftBarButtonItem = cancelButtonItem
        
        self.interface { (me, interface) in
            me.view.backgroundColor = interface.color.background1
        }
        
        let dataSource = RxTableViewSectionedReloadDataSource<TrashSection> (configureCell: {(dataSource, tableView, indexPath, cellModel) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: TrashCell.reuseIdentifier, for: indexPath) as! TrashCell
            cell.accessoryType = .disclosureIndicator
            cell.configureCell(cellModel: cellModel)
            
            return cell
        })
        
        self.viewModel
            .output
            .documents
            .asDriver()
            .do(onNext: { [weak self] _ in
                self?.view.hideProcessingAnimation()
            })
            .drive(self.tableView.rx.items(dataSource: dataSource))
            .disposed(by: self.disposeBag)
        
        self.viewModel.loadData()
    }
    
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.delete(index: indexPath.row)
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actions = ActionsViewController()
        
        actions.title = viewModel.fileName(at: indexPath.row)
        
        actions.addAction(icon: nil, title: L10n.Trash.recover) { [unowned self] viewController in
            viewController.dismiss(animated: true) {
                self.viewModel.showGlobalCaptureEntry()
                self.viewModel.recover(index: indexPath.row)
            }
        }
        
        actions.addAction(icon: nil, title: L10n.General.Button.Title.open) { [unowned self] viewController in
            viewController.dismiss(animated: true) {
                self.viewModel.showGlobalCaptureEntry()
                if let url = self.viewModel.url(at: indexPath.row) {
                    self.viewModel.openDocument(url: url, location: 0)
                }
            }
        }
        
        actions.addAction(icon: nil, title: L10n.Trash.delete, style: .warning) { [unowned self] viewController in
            viewController.dismiss(animated: true) {
                self.viewModel.showGlobalCaptureEntry()
                self.delete(index: indexPath.row)
            }
        }
        
        actions.setCancel { viewController in
            self.viewModel.showGlobalCaptureEntry()
            viewController.dismiss(animated: true)
        }
        
        self.present(actions, animated: true)
        self.viewModel.hideGlobalCaptureEntry()
    }
    
    private func delete(index: Int) {
        let confirmController = ConfirmViewController(contentText: L10n.Trash.Delete.warning, onConfirm: { viewControler in
            viewControler.dismiss(animated: true) {
                self.viewModel.delete(index: index)
            }
        }) { viewController in
            viewController.dismiss(animated: true)
        }
        
        confirmController.title = viewModel.fileName(at: index)
        
        self.present(confirmController, animated: true)
    }
}
