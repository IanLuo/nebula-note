//
//  CatpureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import MapKit
import Interface
import RxSwift
import CHTCollectionViewWaterfallLayout

public protocol CaptureListViewControllerDelegate: class {
    func didChooseAttachment(_ attachment: Attachment, viewController: UIViewController)
}

public class CaptureListViewController: UIViewController {
    let viewModel: CaptureListViewModel
    
    public weak var delegate: CaptureListViewControllerDelegate?
    
    private lazy var filterSegmentedControl: UISegmentedControl = {
        let seg = UISegmentedControl(items: [
            L10n.Attachment.Kind.all,
            Asset.SFSymbols.docPlaintext.image.resize(upto: CGSize(width: 20, height: 20)),
            Asset.SFSymbols.link.image.resize(upto: CGSize(width: 20, height: 20)),
            Asset.SFSymbols.photoOnRectangle.image.resize(upto: CGSize(width: 20, height: 20)),
            Asset.SFSymbols.location.image.resize(upto: CGSize(width: 20, height: 20)),
            Asset.SFSymbols.mic.image.resize(upto: CGSize(width: 20, height: 20)),
            Asset.SFSymbols.video.image.resize(upto: CGSize(width: 20, height: 20)),
            Asset.SFSymbols.scribble.image.resize(upto: CGSize(width: 20, height: 20))
            ])
        
        seg.selectedSegmentIndex = 0
        seg.interface { (view, theme) in
            if #available(iOS 13.0, *) {
                seg.selectedSegmentTintColor = theme.color.spotlight
            } else {
                seg.tintColor = theme.color.spotlight
            }
            let seg = view as! UISegmentedControl
            seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.secondaryDescriptive], for: UIControl.State.normal)
            seg.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : theme.color.spotlitTitle], for: UIControl.State.selected)
        }
        
        seg.addTarget(self, action: #selector(filterIdeas), for: UIControl.Event.valueChanged)
        
        return seg
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = CHTCollectionViewWaterfallLayout()
        layout.minimumColumnSpacing = 10
        layout.minimumInteritemSpacing = 10
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CaptureTableCell.self, forCellWithReuseIdentifier: CaptureTableCell.reuseIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        
        collectionView.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        return collectionView
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.setImage(Asset.SFSymbols.xmark.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint), for: .normal)
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        return button
    }()
    
    public init(viewModel: CaptureListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        
        self.tabBarItem = UITabBarItem(title: L10n.CaptureList.title, image: Asset.SFSymbols.lightbulb.image, tag: 0)
        
        self.title = L10n.CaptureList.title
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private let disposeBag = DisposeBag()
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self._setupObservers()
        
        self.viewModel.loadAllCapturedData()
        
        self.view.showProcessingAnimation()
    }
    
    deinit {
        self.viewModel.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    private func _setupObservers() {
        self.viewModel.dependency.eventObserver.registerForEvent(on: self,
                                                                 eventType: NewCaptureAddedEvent.self,
                                                                 queue: OperationQueue.main,
                                                                 action: { [weak self] (event: NewCaptureAddedEvent) -> Void in
            self?.collectionView.reloadData()
        })
    }
    
    private func setupUI() {
        self.interface { (me, theme) in
            me.view.backgroundColor = InterfaceTheme.Color.background1
        }
        
        self.view.addSubview(self.filterSegmentedControl)
        self.view.addSubview(self.collectionView)
        
        self.filterSegmentedControl.sideAnchor(for: [.top], to: self.view, edgeInset: 30, considerSafeArea: true)
        self.filterSegmentedControl.columnAnchor(view: self.collectionView, space: 10, alignment: .centerX)
        self.collectionView.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0, considerSafeArea: true)
        
        if self.viewModel.context.coordinator?.isModal ?? false {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: Asset.SFSymbols.chevronDown.image, style: .plain, target: self, action: #selector(cancel))
        } else {
            let rightItem = UIBarButtonItem(title: L10n.General.help, style: .plain, target: nil, action: nil)
            rightItem.rx.tap.subscribe(onNext: {
                HelpPage.capture.open(from: self)
            }).disposed(by: self.disposeBag)
            self.navigationItem.rightBarButtonItem = rightItem
        }
        
        let refreshButton = UIButton()
        refreshButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.SFSymbols.arrowClockwise.image.fill(color: theme.color.interactive), for: .normal)
        }
        
        refreshButton.rx.tap.subscribe(onNext: { [unowned refreshButton] in
            refreshButton.showProcessingAnimation()
            
            self.viewModel.dependency.shareExtensionHandler
                .harvestSharedItems(attachmentManager: self.viewModel.dependency.attachmentManager,
                                    urlHandler: self.viewModel.dependency.urlHandlerManager,
                                    captureService: self.viewModel.dependency.captureService)
                .subscribe(onNext: { ideasCount in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        refreshButton.hideProcessingAnimation()
                    }
                    
                    if ideasCount > 0 {
                        self.viewModel.loadAllCapturedData()
                    }
                }, onError: { error in
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                        refreshButton.hideProcessingAnimation()
                    }
                }).disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
        
        let refreshItem = UIBarButtonItem(customView: refreshButton)
        self.navigationItem.leftBarButtonItem = refreshItem
        
        if self.viewModel.mode == .manage {
            self.title = L10n.CaptureList.title
        } else {
            self.title = L10n.CaptureList.Choose.title
        }
    }
    
    @objc private func cancel() {
        self.viewModel.context.coordinator?.stop()
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
        case 7: // sketch
            self.viewModel.currentFilteredAttachmentKind = .sketch
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
    
    public func didTapActions(attachment: Attachment, from: UIView) {
        guard let index = self._index(for: attachment) else { return }
        let cellModel = self.viewModel.currentFilterdCellModels[index]
        let actionsViewController = self.createActionsViewController(cellModel: cellModel)
        
        actionsViewController.present(from: self, at: self.view, location: self.collectionView.convert(from.center, to: self.view))
    }
    
    public func didTapActionsWithLink(attachment: Attachment, link: String?, from: UIView) {
        guard let index = self._index(for: attachment) else { return }
        let cellModel = self.viewModel.currentFilterdCellModels[index]
        let actionsViewController = self.createActionsViewController(cellModel: cellModel)
        
        actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.openLink, at: 0) { viewController in
            viewController.dismiss(animated: true, completion: {
                if let url = URL(string: link ?? "") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
        }
        
        actionsViewController.present(from: self, at: self.view, location: self.collectionView.convert(from.center, to: self.view))
    }
    
    public func didTapActionsWithLocation(attachment: Attachment, location: CLLocationCoordinate2D, from: UIView) {
        guard let index = self._index(for: attachment) else { return }
        let cellModel = self.viewModel.currentFilterdCellModels[index]
        let actionsViewController = self.createActionsViewController(cellModel: cellModel)
        
        actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.openLocation, at: 0) { viewController in
            viewController.dismiss(animated: true, completion: {
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location, addressDictionary:nil))
                mapItem.openInMaps(launchOptions: [:])
            })
        }
        
        
        actionsViewController.present(from: self, at: from)
    }
    
    // 创建菜单
    private func createActionsViewController(cellModel: CaptureTableCellModel) -> ActionsViewController {
        let actionsViewController = ActionsViewController()
        actionsViewController.title = L10n.CaptureList.title
        
        switch self.viewModel.mode {
            // 在 capture list 中显示的菜单，至少包含 refile 和 delete 操作
        case .manage:
            actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.refile) { viewController in
                viewController.dismiss(animated: true, completion: {
                    guard let index = self.viewModel.index(for: cellModel) else { return }
                    self.viewModel.chooseRefileLocation(index: index, completion: {
                    }, canceled: {})
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
                            guard let index = self.viewModel.index(for: cellModel) else { return }
                            self.viewModel.delete(index: index, alsoDeleteAttachment: true)
                        }
                    }
                    
                    guard let index = self.viewModel.index(for: cellModel) else { return }
                    confirmViewController.present(from: self, at: self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)))
                })
            }
        case .pick:
            actionsViewController.addAction(icon: nil, title: L10n.CaptureList.Action.moveToDocument) { viewController in
                viewController.dismiss(animated: true, completion: {
                    guard let index = self.viewModel.index(for: cellModel) else { return }
                    self.viewModel.selectAttachment(index: index)
                    let shouldDeleteAttachment = cellModel.attachmentView.attachment.kind.displayAsPureText
                    self.viewModel.delete(index: index, alsoDeleteAttachment: shouldDeleteAttachment)
                })
            }
        }
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.context.coordinator?.onCancelAction?()
        }
        
        return actionsViewController
    }
}

extension CaptureListViewController: UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.currentFilterdCellModels.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CaptureTableCell.reuseIdentifier, for: indexPath) as! CaptureTableCell
        cell.cellModel = self.viewModel.currentFilterdCellModels[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, columnCountForSection section: Int) -> Int {
        return self.viewModel.mode.columnCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.viewModel.currentFilterdCellModels[indexPath.row]
            .attachmentView.size(for: (collectionView.bounds.width - Layout.edgeInsets.left - Layout.edgeInsets.right - (isPhone ? 10 : 40)) / CGFloat(self.viewModel.mode.columnCount))
            .heigher(by: Layout.edgeInsets.top + Layout.edgeInsets.bottom + 60)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if isPhone {
            return .zero
        } else {
            return Layout.edgeInsets
        }
    }
}

extension CaptureListViewController: EmptyContentPlaceHolderProtocol {
    public var text: String {
        return L10n.CaptureList.empty
    }
    
    public var image: UIImage {
        return Asset.Assets.smallIcon.image.fill(color: InterfaceTheme.Color.secondaryDescriptive)
    }
    
    public var viewToShowImage: UIView {
        return self.collectionView
    }
}

extension CaptureListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let attachment = self.viewModel.currentFilteredData[indexPath.row]
        
        let fromView = collectionView.cellForItem(at: indexPath) ?? collectionView
        
        switch attachment.kind {
        case .link:
            if let link = attachment.linkValue {
                self.didTapActionsWithLink(attachment: attachment, link: link, from: fromView)
            } else {
                self.didTapActions(attachment: attachment, from: fromView)
            }
        case .location:
            if let coor = attachment.coordinator {
                self.didTapActionsWithLocation(attachment: attachment, location: coor, from: fromView)
            } else {
                self.didTapActions(attachment: attachment, from: fromView)
            }
        default:
            self.didTapActions(attachment: attachment, from: fromView)
        }
    }
}

extension CaptureListViewController: CaptureListViewModelDelegate {
    public func didStartRefile(at index: Int) {
        if let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.showProcessingAnimation()
        }
    }
    
    public func didDeleteCapture(index: Int) {
        self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        self.showEmptyContentImage(self.viewModel.currentFilterdCellModels.count == 0)
    }
    
    public func didFail(error: String) {
        
    }
        
    public func didCompleteRefile(index: Int, attachment: Attachment) {
        if let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.hideProcessingAnimation()
        }
        
        self.showEmptyContentImage(self.viewModel.currentFilterdCellModels.count == 0)
        
        // remove attachment from capture list
        let shouldDeleteAttachment = attachment.kind.displayAsPureText
        self.viewModel.delete(index: index, alsoDeleteAttachment: shouldDeleteAttachment)
    }
    
    public func didLoadData() {
        self.view.hideProcessingAnimation()
        self.collectionView.reloadData()
        self.showEmptyContentImage(self.viewModel.currentFilterdCellModels.count == 0)
    }
}
