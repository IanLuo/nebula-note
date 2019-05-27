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
    func didCancel()
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
        
        tableView.interface({ (me, theme) in
            me.backgroundColor = theme.color.background1
        })
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: Constants.recentViewsHeight + Layout.edgeInsets.top, left: 0, bottom: Layout.edgeInsets.bottom + 80, right: 0)
        return tableView
    }()
    
    private lazy var createNewDocumentButton: RoundButton = {
        let button = RoundButton()
        
        button.interface({ (me, theme) in
            let button = me as! RoundButton
            button.setIcon(Asset.Assets.newDocument.image.fill(color: theme.color.interactive), for: .normal)
            button.setBackgroundColor(theme.color.background2, for: .normal)
        })
        
        button.tapped { [weak self] _ in
            self?.createNewDocumentAtRoot()
        }
        return button
    }()
    
    private lazy var openningFilesView: RecentFilesView = {
        let view = RecentFilesView(eventObserver: self.viewModel.coordinator?.dependency.eventObserver, viewModel: viewModel)
        view.delegate = self
        return view
    }()
    
    public weak var delegate: DocumentBrowserViewControllerDelegate?
    
    public init(viewModel: DocumentBrowserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        
        self.title = L10n.Browser.title
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
        self.interface { (me, theme) in
            me.view.backgroundColor = InterfaceTheme.Color.background1
        }
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.openningFilesView)
        self.view.addSubview(self.createNewDocumentButton)
        
        self.openningFilesView.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInsets: .init(top: Layout.edgeInsets.top, left: 0, bottom: 0, right: 0), considerSafeArea: true)
        self.openningFilesView.sizeAnchor(height: Constants.recentViewsHeight)

        self.tableView.sideAnchor(for: [.left, .top, .bottom, .right], to: self.view, edgeInset: 0)
        
        self.createNewDocumentButton.sideAnchor(for: [.left, .bottom], to: self.view, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: -Layout.edgeInsets.bottom, right: 0), considerSafeArea: true)
        self.createNewDocumentButton.sizeAnchor(width: 60)
        self.createNewDocumentButton.isHidden = !self.viewModel.shouldShowActions
        
        if self.viewModel.coordinator?.isModal ?? false {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Assets.cross.image, style: .plain, target: self, action: #selector(cancel))
        }
    }
    
    @objc private func createNewDocumentAtRoot() {
        self.viewModel.createDocument(title: L10n.Browser.Title.untitled, below: nil)
    }
    
    @objc private func cancel() {
        self.delegate?.didCancel()
    }
}

extension DocumentBrowserViewController: RecentFilesViewDelegate {
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
        if scrollView.contentOffset.y > -scrollView.contentInset.top - self.navigationBarBottomToStatusBarTop {
            self.openningFilesView.constraint(for: Position.top)?.constant = -scrollView.contentOffset.y - Constants.recentViewsHeight - self.navigationBarBottomToStatusBarTop
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

// MARK: - DocumentBrowserCellDelegate
extension DocumentBrowserViewController: DocumentBrowserCellDelegate {
    public func didUpdateCell(index: Int) {
        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    
    public func didTapActions(url: URL) {
        if let index = self.viewModel.index(of: url) {
            let actionsViewController = ActionsViewController()
            
            actionsViewController.title = L10n.Browser.Actions.title
            // 创建新文档，使用默认的新文档名
            actionsViewController.addAction(icon: Asset.Assets.add.image, title: L10n.Browser.Action.new) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.createDocument(title: L10n.Browser.Title.untitled, below: self.viewModel.data[index].url)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }
            
            // 移动文件
            actionsViewController.addAction(icon: nil, title: L10n.Browser.Action.MoveTo.title) { viewController in
                
                self.viewModel.loadAllFiles(completion: { [unowned self] files in
                    
                    viewController.dismiss(animated: true, completion: {
                        let selector = SelectorViewController()
                        selector.title = L10n.Browser.Action.MoveTo.msg
                        selector.fromView = self.tableView.cellForRow(at: IndexPath(row: index, section: 0))
                        let root: String = "\\"
                        selector.addItem(title: root)
                        for file in files {
                            let indent = Array(repeating: "   ", count: file.levelFromRoot - 1).reduce("") { $0 + $1 }
                            let title = indent + file.url.wrapperURL.packageName
                            selector.addItem(icon: nil,
                                             title: title,
                                             description: nil,
                                             enabled: file.url.documentRelativePath != url.documentRelativePath
                                                && file.url.documentRelativePath != url.parentDocumentURL?.documentRelativePath)
                        }
                        
                        selector.onCancel = { viewController in
                            viewController.dismiss(animated: true, completion: {
                                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                            })
                        }
                        
                        selector.onSelection = { index, viewController in
                            viewController.dismiss(animated: true, completion: {
                                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                                
                                if index == 0 {
                                    self.viewModel.move(url: url, to: URL.documentBaseURL)
                                } else {
                                    let under = files[index - 1]
                                    self.viewModel.move(url: url, to: under.url)
                                }
                            })
                        }
                        
                        self.present(selector, animated: true, completion: nil)
                    })
                })
            }

            // 重命名
            actionsViewController.addAction(icon: nil, title: L10n.Browser.Actions.rename) { viewController in
                viewController.dismiss(animated: true, completion: {
                    
                    let renameFormViewController = ModalFormViewController()
                    let title = L10n.Browser.Action.Rename.newName
                    renameFormViewController.addTextFied(title: title, placeHoder: "", defaultValue: url.packageName) // 不需要显示 placeholder, default value 有值
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
                            return [title: L10n.Browser.Action.Rename.Warning.nameIsTaken]
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
            
            // 复制
            actionsViewController.addAction(icon: nil, title: L10n.Browser.Actions.duplicate) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.duplicate(index: index, copyExt: L10n.Browser.Title.copyExt)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }
            
            // 编辑封面
            actionsViewController.addAction(icon: nil, title: L10n.Browser.Actions.cover) { viewController in
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
            
            // 导出
            actionsViewController.addAction(icon: nil, title: L10n.Document.Export.title) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let exportManager = ExportManager()
                    let selector = SelectorViewController()
                    selector.title = L10n.Document.Export.msg
                    for item in exportManager.exportMethods {
                        selector.addItem(title: item.title)
                    }
                    
                    selector.onSelection = { index, viewController in
                        viewController.dismiss(animated: true, completion: {
                            exportManager.export(url: url, type:.org, completion: { url in
                                exportManager.share(from: self, url: url)
                            }, failure: { error in
                                // TODO: show error
                            })
                        })
                    }
                    
                    selector.onCancel = { viewController in
                        viewController.dismiss(animated: true, completion: nil)
                    }
                    
                    self.present(selector, animated: true, completion: nil)
                })
            }
            
            // 删除
            actionsViewController.addAction(icon: Asset.Assets.trash.image, title: L10n.Browser.Actions.delete, style: .warning) { viewController in
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
