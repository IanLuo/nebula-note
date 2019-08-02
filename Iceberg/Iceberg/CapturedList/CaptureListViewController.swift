//
//  CatpureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import MapKit
import Interface

public protocol CaptureListViewControllerDelegate: class {
    func didChooseAttachment(_ attachment: Attachment, viewController: UIViewController)
}

public class CaptureListViewController: UIViewController {
    let viewModel: CaptureListViewModel
    
    public weak var delegate: CaptureListViewControllerDelegate?
    
    private let filterSegmentedControl: UISegmentedControl = {
        let seg = UISegmentedControl(items: [
            L10n.Attachment.Kind.all,
            Asset.Assets.text.image,
            Asset.Assets.link.image,
            Asset.Assets.imageLibrary.image,
            Asset.Assets.location.image,
            Asset.Assets.audio.image,
            Asset.Assets.video.image
            ])
        
        seg.selectedSegmentIndex = 0

        seg.interface { (view, theme) in
            view.tintColor = theme.color.interactive
        }
        
        seg.addTarget(self, action: #selector(filterIdeas), for: UIControl.Event.valueChanged)
        
        return seg
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CaptureTableCell.self, forCellReuseIdentifier: CaptureTableCell.reuseIdentifier)
        
        tableView.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.setImage(Asset.Assets.cross.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint), for: .normal)
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        return button
    }()
    
    public init(viewModel: CaptureListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        self.title = L10n.CaptureList.title
        self.tabBarItem = UITabBarItem(title: "", image: Asset.Assets.inspiration.image, tag: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.viewModel.loadAllCapturedData()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self._setupObservers()
        
        self.viewModel.loadAllCapturedData()
        
        self.view.showProcessingAnimation()
    }
    
    deinit {
        self.viewModel.coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    private func _setupObservers() {
        self.viewModel.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                              eventType: NewCaptureAddedEvent.self,
                                                                              queue: OperationQueue.main,
                                                                              action: { [weak self] (event: NewCaptureAddedEvent) -> Void in
            self?.tableView.reloadData()
        })
    }
    
    private func setupUI() {
        self.interface { (me, theme) in
            me.view.backgroundColor = InterfaceTheme.Color.background1
        }
        
        self.view.addSubview(self.filterSegmentedControl)
        self.view.addSubview(self.tableView)
        
        self.filterSegmentedControl.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInset: 30, considerSafeArea: true)
        self.filterSegmentedControl.columnAnchor(view: self.tableView, space: 10)
        self.tableView.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0, considerSafeArea: true)
        
        if self.viewModel.coordinator?.isModal ?? false {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.Assets.cross.image, style: .plain, target: self, action: #selector(cancel))
        }
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
    }
    
    @objc private func filterIdeas() {
        let index = self.filterSegmentedControl.selectedSegmentIndex
        
        switch index {
        case 0: //all
            self.viewModel.currentFilteredAttachmentKind = nil
        case 1: // text
            self.viewModel.currentFilteredAttachmentKind = .text
        case 2: // link
            self.viewModel.currentFilteredAttachmentKind = .link
        case 3: // image
            self.viewModel.currentFilteredAttachmentKind = .image
        case 4: // location
            self.viewModel.currentFilteredAttachmentKind = .location
        case 5: // voice
            self.viewModel.currentFilteredAttachmentKind = .audio
        case 6: // video
            self.viewModel.currentFilteredAttachmentKind = .video
        default: return // ignore
        }
        
        self.viewModel.loadFilterdData(kind: self.viewModel.currentFilteredAttachmentKind)
    }
}

extension CaptureListViewController: CaptureTableCellDelegate {
    private func _index(for attachment: Attachment) -> Int? {
        for (index, t) in self.viewModel.currentFilteredData.enumerated() {
            if attachment.key == t.key {
                return index
            }
        }
        return nil
    }
    
    public func didTapActions(attachment: Attachment) {
        guard let index = self._index(for: attachment) else { return }
        
        let actionsViewController = self.createActionsViewController(index: index)
        
        self.present(actionsViewController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    public func didTapActionsWithLink(attachment: Attachment, link: String?) {
        guard let index = self._index(for: attachment) else { return }
        
        let actionsViewController = self.createActionsViewController(index: index)
        
        actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.openLink, at: 0) { viewController in
            viewController.dismiss(animated: true, completion: {
                if let url = URL(string: link ?? "") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    public func didTapActionsWithLocation(attachment: Attachment, location: CLLocationCoordinate2D) {
        guard let index = self._index(for: attachment) else { return }

        let actionsViewController = self.createActionsViewController(index: index)
        
        actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.openLocation, at: 0) { viewController in
            viewController.dismiss(animated: true, completion: {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location, addressDictionary:nil))
                mapItem.openInMaps(launchOptions: [:])
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        
        self.present(actionsViewController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    // 创建菜单
    private func createActionsViewController(index: Int) -> ActionsViewController {
        let actionsViewController = ActionsViewController()
        actionsViewController.title = L10n.CaptureList.title
        
        switch self.viewModel.mode {
            // 在 capture list 中显示的菜单，至少包含 refile 和 delete 操作
        case .manage:
            actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.refile) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.chooseRefileLocation(index: index, completion: {
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    }, canceled: {
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    })
                })
            }
            
            actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.delete, style: .warning) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let confirmViewController = ConfirmViewController()
                    confirmViewController.contentText = L10n.CaptureList.Action.deleteConfirm
                    confirmViewController.cancelAction = { vc in
                        vc.dismiss(animated: true)
                    }
                    
                    confirmViewController.confirmAction = { vc in
                        vc.dismiss(animated: true) {
                            self.viewModel.delete(index: index)
                            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                        }
                    }
                    
                    self.present(confirmViewController, animated: true)
                })
            }
        case .pick:
            actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.copyToDocument) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.selectAttachment(index: index)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }
            
            actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.moveToDocument) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.selectAttachment(index: index)
                    self.viewModel.delete(index: index)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }
        }
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.onCancelAction?()
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        return actionsViewController
    }
}

extension CaptureListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.currentFilterdCellModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CaptureTableCell.reuseIdentifier, for: indexPath) as! CaptureTableCell
        cell.cellModel = self.viewModel.currentFilterdCellModels[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.viewModel.currentFilterdCellModels[indexPath.row].attachmentView.size(for: tableView.bounds.width - 60).height + 120
    }
}

extension CaptureListViewController: UITableViewDelegate {
    // nothing to do yet
}

extension CaptureListViewController: CaptureListViewModelDelegate {
    public func didStartRefile(at index: Int) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.showProcessingAnimation()
        }
    }
    
    public func didDeleteCapture(index: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
    }
    
    public func didFail(error: String) {
        
    }
        
    public func didCompleteRefile(index: Int) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.hideProcessingAnimation()
        }
    }
    
    public func didLoadData() {
        self.view.hideProcessingAnimation()
        self.tableView.reloadData()
    }
}