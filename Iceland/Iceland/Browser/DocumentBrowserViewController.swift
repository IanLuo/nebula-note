//
//  DocumentBrowserViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol DocumentBrowserViewControllerDelegate: class {
    func didSelectDocument(url: URL)
}

public class DocumentBrowserViewController: UIViewController {
    let viewModel: DocumentBrowserViewModel
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DocumentBrowserCell.self, forCellReuseIdentifier: DocumentBrowserCell.reuseIdentifier)
        tableView.backgroundColor = InterfaceTheme.Color.background1
        tableView.tableFooterView = UIView()
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.separatorInset = .zero
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 130, right: 0)
        return tableView
    }()
    
    private let createNewDocumentButton: UIButton = {
        let button = UIButton()
        button.setTitle("browser_create_new".localizable, for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint),
                                  for: .normal)
        button.addTarget(self, action: #selector(createNewDocumentAtRoot), for: .touchUpInside)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("✕".localizable, for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint),
                                  for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    public weak var delegate: DocumentBrowserViewControllerDelegate?
    
    public init(viewModel: DocumentBrowserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.viewModel.loadData()
    }
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.createNewDocumentButton)
        self.view.addSubview(self.cancelButton)

        self.cancelButton.sideAnchor(for: [.right, .top], to: self.view, edgeInset: 20)
        self.cancelButton.sizeAnchor(width: 60, height: 60)

        self.cancelButton.columnAnchor(view: self.tableView)
        self.tableView.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0)
        
        self.createNewDocumentButton.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInsets: .zero)
        self.createNewDocumentButton.sizeAnchor(height: 60)
        self.createNewDocumentButton.isHidden = !self.viewModel.shouldShowActions
    }
    
    @objc private func createNewDocumentAtRoot() {
        self.viewModel.createDocument(below: nil)
    }
    
    @objc private func cancel() {
        self.viewModel.dependency?.stop()
    }
}

extension DocumentBrowserViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DocumentBrowserCell.reuseIdentifier, for: indexPath) as! DocumentBrowserCell
        cell.delegate = self
        cell.cellModel = self.viewModel.data[indexPath.row]
        return cell
    }
}

extension DocumentBrowserViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectDocument(url: self.viewModel.data[indexPath.row].url)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension DocumentBrowserViewController: DocumentBrowserViewModelDelegate {
    public func didLoadData() {
        self.tableView.reloadData()
    }
    
    public func didAddDocument(index: Int, count: Int) {
        var indexPaths: [IndexPath] = []
        for index in index..<index + count {
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        self.tableView.insertRows(at: indexPaths, with: .fade)
    }
    
    public func didRemoveDocument(index: Int, count: Int) {
        var indexPaths: [IndexPath] = []
        for index in index..<index + count {
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        self.tableView.deleteRows(at: indexPaths, with: .fade)
    }
    
    public func didRenameDocument(index: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
}

extension DocumentBrowserViewController: DocumentBrowserCellDelegate {
    public func didUpdate(index: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    public func didTapActions(url: URL) {
        if let index = self.viewModel.index(of: url) {
            let actionsViewController = ActionsViewController()
            actionsViewController.addAction(icon: nil, title: "new document".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.createDocument(below: self.viewModel.data[index].url)
                })
            }

            actionsViewController.addAction(icon: nil, title: "rename".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let renameFormViewController = ModalFormViewController()
                    let title = "new name".localizable
                    renameFormViewController.addTextFied(title: title, placeHoder: "", defaultValue: url.fileName) // 不需要显示 placeholder, default value 有值
                    renameFormViewController.onSaveValue = { formValue, viewController in
                        if let newName = formValue[title] as? String {
                            viewController.dismiss(animated: true, completion: {
                                self.viewModel.rename(index: index, to: newName)
                            })
                        }
                    }
                    
                    renameFormViewController.onValidating = { formData in
                        if !self.viewModel.isNameAvailable(newName: formData[title] as! String, index: index) {
                            return [title: "name is taken".localizable]
                        }
                        
                        return [:]
                    }
                    
                    renameFormViewController.onCancel = { viewController in
                        viewController.dismiss(animated: true, completion: nil)
                    }
                    
                    self.present(renameFormViewController, animated: true, completion: nil)
                })
            }
            
            actionsViewController.addAction(icon: nil, title: "delete".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.deleteDocument(index: index)
                })
            }
            
            actionsViewController.addAction(icon: nil, title: "duplicate".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.duplicate(index: index)
                })
            }
            
            actionsViewController.setCancel { viewController in
                viewController.dismiss(animated: true, completion: nil)
            }
            
            self.present(actionsViewController, animated: true, completion: nil)
        }
    }
    
    public func didTapUnfold(url: URL) {
        self.viewModel.unfold(url: url)
    }
    
    public func didTapFold(url: URL) {
        self.viewModel.fold(url: url)
    }
}
