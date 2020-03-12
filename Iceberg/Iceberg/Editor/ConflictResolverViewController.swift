//
//  ConflictResolverViewController.swift
//  x3Note
//
//  Created by ian luo on 2020/3/12.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Interface

public class ConflictResolverViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var viewModel: DocumentEditViewModel!
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(VersionCell.self, forCellReuseIdentifier: VersionCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private let versions: BehaviorRelay<[NSFileVersion]> = BehaviorRelay(value: [])
    
    private let disposeBag = DisposeBag()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.interactive
        label.textAlignment = .center
        return label
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.spotlight, size: .singlePoint), for: .normal)
        button.setTitleColor(InterfaceTheme.Color.spotlitTitle, for: .normal)
        button.roundConer(radius: 8)
        return button
    }()
    
    public convenience init(viewModel: DocumentEditViewModel) {
        self.init()
        self.viewModel = viewModel
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
    }
    
    public override func viewDidLoad() {
        
        if let conflictVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: self.viewModel.url), let currentVersion = NSFileVersion.currentVersionOfItem(at: self.viewModel.url) {
            var versions = conflictVersions
            versions.append(currentVersion)
            self.versions.accept(versions)
        }
        
        self.title = L10n.Document.Edit.Conflict.found
        
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.descriptionLabel)
        self.view.addSubview(self.confirmButton)
        
        self.descriptionLabel.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInset: 20, considerSafeArea: true)
        
        self.descriptionLabel.columnAnchor(view: self.tableView, space: 20)
        
        self.tableView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.tableView.columnAnchor(view: self.confirmButton, space: 20, alignment: .centerX)
        
        self.confirmButton.sideAnchor(for: .bottom, to: self.view, edgeInset: 20, considerSafeArea: true)
        self.confirmButton.sizeAnchor(width: 200, height: 50)
        
        self.descriptionLabel.text = L10n.Document.Edit.Conflict.description
        self.confirmButton.setTitle(L10n.General.Button.ok, for: .normal)
        self.confirmButton.isEnabled = false
        
        self.bind()
    }
    
    private func bind() {
        self.confirmButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.resolveConflict()
        }).disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected.subscribe(onNext: { [weak self] _ in
            self?.confirmButton.isEnabled = true
        }).disposed(by: self.disposeBag)
        
        self.tableView.rx.itemDeselected.subscribe(onNext: { [weak self] _ in
            self?.confirmButton.isEnabled = false
        }).disposed(by: self.disposeBag)
    }
    
    private func resolveConflict() {
        if let index = self.tableView.indexPathForSelectedRow?.row {
            let conformViewController = ConfirmViewController(contentText: L10n.Document.Edit.Conflict.warning, onConfirm: { [unowned self] viewController in
                viewController.dismiss(animated: true) {
                    do {
                        try self.viewModel.handleConflict(url: self.versions.value[index].url) {
                            self.dismiss(animated: true)
                        }
                    } catch {
                        log.error(error)
                    }
                }
            }) { viewController in
                viewController.dismiss(animated: true)
            }
            
            self.present(conformViewController, animated: true)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.versions.value.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VersionCell.reuseIdentifier, for: indexPath) as! VersionCell
        
        let fileVersion = self.versions.value[indexPath.row]
        
        if fileVersion.url == self.viewModel.url {
            cell.textLabel?.text = L10n.Document.Edit.Conflict.current
        } else {
            let text = (fileVersion.modificationDate?.shotDateAndTimeString ?? "") + " " + (fileVersion.localizedNameOfSavingComputer ?? "")
            cell.textLabel?.text = text
        }
        
        
        cell.accessoryType = .detailDisclosureButton
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let url = self.versions.value[indexPath.row].url
        
        self.viewModel.context.coordinator?.showTempDocument(url: url, from: self)
    }
}

private class VersionCell: UITableViewCell {
    static let reuseIdentifier: String = "VersionCell"
    
    
}
