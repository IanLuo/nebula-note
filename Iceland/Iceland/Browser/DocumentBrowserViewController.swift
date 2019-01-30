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
        tableView.contentInset = UIEdgeInsets(top: self.view.bounds.height / 4, left: 0, bottom: 130, right: 0)
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
        button.setImage(UIImage(named: "cross")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint),
                                  for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    private lazy var openningFilesView: OpenningFilesView = {
        let view = OpenningFilesView()
        view.delegate = self
        return view
    }()
    
    public weak var delegate: DocumentBrowserViewControllerDelegate?
    
    public init(viewModel: DocumentBrowserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        
        self.title = "Documents".localizable
        self.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "document"), tag: 0)
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
        self.view.addSubview(self.openningFilesView)
        self.view.addSubview(self.createNewDocumentButton)
        self.view.addSubview(self.cancelButton)
        
        self.openningFilesView.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInsets: .init(top: 80, left: 0, bottom: 0, right: 0))
        self.openningFilesView.sizeAnchor(height: self.view.bounds.height / 4 - 80)

        self.cancelButton.sideAnchor(for: [.right, .top], to: self.view, edgeInset: 20)
        self.cancelButton.sizeAnchor(width: 80, height: 80)

        self.cancelButton.columnAnchor(view: self.tableView)
        self.tableView.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0)
        
        self.createNewDocumentButton.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInsets: .zero)
        self.createNewDocumentButton.sizeAnchor(height: 60)
        self.createNewDocumentButton.isHidden = !self.viewModel.shouldShowActions
        self.cancelButton.isHidden = self.viewModel.shouldShowActions
    }
    
    @objc private func createNewDocumentAtRoot() {
        self.viewModel.createDocument(title: "untitled".localizable, below: nil)
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
    }
}

extension DocumentBrowserViewController: OpenningFilesViewDelegate {
    public func didSelectDocument(url: URL) {
        self.viewModel.coordinator?.openDocument(url: url, location: 0)
    }
    
    public func dataChanged(count: Int) {
        // TODO:
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
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
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
    public func didUpdateCell(index: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    public func didTapActions(url: URL) {
        if let index = self.viewModel.index(of: url) {
            let actionsViewController = ActionsViewController()
            
            actionsViewController.title = "Perform Actions".localizable
            // 创建新文档，使用默认的新文档名
            actionsViewController.addAction(icon: UIImage(named: "add"), title: "new document".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.createDocument(title: "untitled".localizable, below: self.viewModel.data[index].url)
                })
            }

            // 重命名
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
                    
                    // 显示给用户，是否可以使用这个文件名
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
            
            actionsViewController.addAction(icon: nil, title: "duplicate".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.duplicate(index: index)
                })
            }
            
            actionsViewController.addAction(icon: nil, title: "cover".localizable) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let coverPicker = CoverPickerViewController()
                    coverPicker.onSelecedCover = { [weak self] cover in
                        self?.viewModel.setCover(cover, index: index)
                    }
                    
                    self.present(coverPicker, animated: true, completion: nil)
                })
            }
            
            actionsViewController.addAction(icon: UIImage(named: "trash"), title: "delete".localizable, style: .warning) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.deleteDocument(index: index)
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
