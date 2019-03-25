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
import Interface

public protocol DocumentBrowserViewControllerDelegate: class {
    func didSelectDocument(url: URL)
}

public class DocumentBrowserViewController: UIViewController {
    public struct Constants {
        public static let recentViewsHeight: CGFloat = 120
    }
    
    let viewModel: DocumentBrowserViewModel
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DocumentBrowserCell.self, forCellReuseIdentifier: DocumentBrowserCell.reuseIdentifier)
        tableView.backgroundColor = InterfaceTheme.Color.background1
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
//        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.contentInset = UIEdgeInsets(top: Constants.recentViewsHeight, left: 0, bottom: Layout.edgeInsets.bottom, right: 0)
        return tableView
    }()
    
    private let createNewDocumentButton: SquareButton = {
        let button = SquareButton()
        button.title.text = L10n.Document.Action.new
        button.icon.image = Asset.Assets.add.image.withRenderingMode(.alwaysTemplate)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint),
                                  for: .normal)
        button.addTarget(self, action: #selector(createNewDocumentAtRoot), for: .touchUpInside)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Assets.cross.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint),
                                  for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    private lazy var openningFilesView: OpenningFilesView = {
        let view = OpenningFilesView(eventObserver: self.viewModel.coordinator?.dependency.eventObserver)
        view.delegate = self
        return view
    }()
    
    public weak var delegate: DocumentBrowserViewControllerDelegate?
    
    public init(viewModel: DocumentBrowserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        
        self.title = "Documents".localizable
        self.tabBarItem = UITabBarItem(title: "", image: Asset.Assets.document.image, tag: 0)
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
        
        self.openningFilesView.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInsets: .init(top: Layout.edgeInsets.top, left: 0, bottom: 0, right: 0), considerSafeArea: true)
        self.openningFilesView.sizeAnchor(height: Constants.recentViewsHeight)

        self.cancelButton.sideAnchor(for: [.right, .top], to: self.view, edgeInset: 20)
        self.cancelButton.sizeAnchor(width: 80, height: 80)

        self.cancelButton.columnAnchor(view: self.tableView, space: Constants.recentViewsHeight)
        self.tableView.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0)
        
        self.createNewDocumentButton.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInsets: .zero, considerSafeArea: true)
        self.createNewDocumentButton.sizeAnchor(height: 60)
        self.createNewDocumentButton.isHidden = !self.viewModel.shouldShowActions
        self.cancelButton.isHidden = self.viewModel.shouldShowActions
    }
    
    @objc private func createNewDocumentAtRoot() {
        self.viewModel.createDocument(title: L10n.Document.Title.untitled, below: nil)
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
    }
}

extension DocumentBrowserViewController: RecentFilesViewDelegate {
    public func recentFilesData() -> [RecentDocumentInfo] {
        return self.viewModel.coordinator?.dependency.editorContext.recentFilesManager.recentFiles ?? []
    }
    
    public func didSelectDocument(url: URL) {
        self.delegate?.didSelectDocument(url: url)
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
    
    /// 当向上滚动时，同时滚动日期选择和日期显示 view，往下则不动
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.contentInset.top > 0 {
            self.openningFilesView.constraint(for: Position.top)?.constant = Layout.edgeInsets.top - scrollView.contentOffset.y  - scrollView.contentInset.top
            self.view.layoutIfNeeded()
        } else {
            self.openningFilesView.constraint(for: Position.top)?.constant = Layout.edgeInsets.top
            self.view.layoutIfNeeded()
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
        self.tableView.insertRows(at: indexPaths, with: .top)
    }
    
    public func didRemoveDocument(index: Int, count: Int) {
        var indexPaths: [IndexPath] = []
        for index in index..<index + count {
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        self.tableView.deleteRows(at: indexPaths, with: .top)
    }
    
    public func didRenameDocument(index: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
}

extension DocumentBrowserViewController: DocumentBrowserCellDelegate {
    public func didUpdateCell(index: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    
    public func didTapActions(url: URL) {
        if let index = self.viewModel.index(of: url) {
            let actionsViewController = ActionsViewController()
            
            actionsViewController.title = L10n.Document.Actions.title
            // 创建新文档，使用默认的新文档名
            actionsViewController.addAction(icon: Asset.Assets.add.image, title: L10n.Document.Action.new) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.createDocument(title: L10n.Document.Title.untitled, below: self.viewModel.data[index].url)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }

            // 重命名
            actionsViewController.addAction(icon: nil, title: L10n.Document.Actions.rename) { viewController in
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
                        
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    }
                    
                    renameFormViewController.onCancel = { _ in
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
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
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    }
                    
                    self.present(renameFormViewController, animated: true, completion: nil)
                })
            }
            
            actionsViewController.addAction(icon: nil, title: L10n.Document.Actions.duplicate) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.duplicate(index: index)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }
            
            actionsViewController.addAction(icon: nil, title: L10n.Document.Actions.cover) { viewController in
                viewController.dismiss(animated: true, completion: {
                    
                    let coverPicker = CoverPickerViewController()
                    coverPicker.onSelecedCover = { cover in
                        self.viewModel.setCover(cover, index: index)
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    }
                    
                    coverPicker.onCancel = {
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    }
                    
                    self.present(coverPicker, animated: true, completion: nil)
                })

            }
            
            actionsViewController.addAction(icon: Asset.Assets.trash.image, title: L10n.Document.Actions.delete, style: .warning) { viewController in
                let confirmViewController = ConfirmViewController()
                
                confirmViewController.confirmAction = {
                    $0.dismiss(animated: true, completion: {
                        viewController.dismiss(animated: true, completion: {
                            self.viewModel.deleteDocument(index: index)
                        })
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    })
                }
                
                confirmViewController.cancelAction = {
                    $0.dismiss(animated: true, completion: nil)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                }
                
                viewController.present(confirmViewController, animated: true, completion: nil)
            }
            
            actionsViewController.setCancel { viewController in
                viewController.dismiss(animated: true, completion: nil)
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            self.present(actionsViewController, animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
        }
    }
    
    public func didTapUnfold(url: URL) {
        self.viewModel.unfold(url: url)
    }
    
    public func didTapFold(url: URL) {
        self.viewModel.fold(url: url)
    }
}
