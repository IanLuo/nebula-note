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
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        return tableView
    }()
    
    private let createNewDocumentButton: UIButton = {
        let button = UIButton()
        button.setTitle("browser_create_new".localizable, for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.descriptive, size: .singlePoint),
                                  for: .normal)
        button.addTarget(self, action: #selector(createNewDocumentAtRoot), for: .touchUpInside)
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
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.createNewDocumentButton)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.createNewDocumentButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.tableView.allSidesAnchors(to: self.view, edgeInsets: .zero)
        self.createNewDocumentButton.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInsets: .zero)
        self.createNewDocumentButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    
    @objc private func createNewDocumentAtRoot() {
        self.viewModel.createDocument(below: nil)
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
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
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
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "add new documnet", style: .default, handler: { _ in
                self.viewModel.createDocument(below: self.viewModel.data[index].url)
            }))
            
            actionSheet.addAction(UIAlertAction(title: "rename", style: .default, handler: { _ in
                self.viewModel.rename(index: index, to: "new name")
            }))
            
            actionSheet.addAction(UIAlertAction(title: "delete", style: .default, handler: { _ in
                self.viewModel.deleteDocument(index: index)
            }))
            
            actionSheet.addAction(UIAlertAction(title: "duplicate", style: .default, handler: { _ in
                self.viewModel.duplicate(index: index)
            }))
            
            actionSheet.addAction(UIAlertAction(title: "cancel", style: UIAlertAction.Style.cancel, handler: nil))
            
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    public func didTapUnfold(url: URL) {
        self.viewModel.unfold(url: url)
    }
    
    public func didTapFold(url: URL) {
        self.viewModel.fold(url: url)
    }
}
