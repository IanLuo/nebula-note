//
//  AttachmentManagerViewController.swift
//  Icetea
//
//  Created by ian luo on 2020/2/6.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import Core
import RxDataSources
import Interface
import MapKit

public class AttachmentManagerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var viewModel: AttachmentManagerViewModel!
    private var isSelectMode: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private let disposeBag = DisposeBag()
    let onSelectingAttachment: PublishSubject<Attachment?> = PublishSubject()
    
    public convenience init(viewModel: AttachmentManagerViewModel) {
        self.init()
        self.viewModel = viewModel
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.register(AttachmentManagerCell.self, forCellWithReuseIdentifier: AttachmentManagerCell.reuseIdentifier)
        return collectionView
    }()
    
    public override func viewDidLoad() {
        self.setupUI()
        
        self.bind()
        
        self.viewModel.loadData()
    }
    
    private func setupUI() {
        self.view.addSubview(self.collectionView)
        
        self.collectionView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self.interface { [weak self] (me, theme) in
            me.view.backgroundColor = theme.color.background1
            self?.collectionView.backgroundColor = theme.color.background1
        }
        
        if self.viewModel.context.coordinator?.usage == .pick {
            let closeButton = UIBarButtonItem(image: Asset.Assets.down.image, style: .plain, target: nil, action: nil)
            closeButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            }).disposed(by: self.disposeBag)
            
            self.navigationItem.leftBarButtonItem = closeButton
        }
    }
    
    private func bind() {
        let datasource = RxCollectionViewSectionedAnimatedDataSource<AttachmentManagerSection>(configureCell: { (datasource, collectionView, indexPath, cellModel) -> UICollectionViewCell in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AttachmentManagerCell.reuseIdentifier, for: indexPath) as! AttachmentManagerCell
            
            cell.configure(cellModel: cellModel)
            
            cell.shouldShowSelection = self.isSelectMode.value
            
            return cell
        })
        
        self.viewModel
            .output
            .attachments
            .asDriver()
            .drive(self.collectionView.rx.items(dataSource: datasource))
            .disposed(by: self.disposeBag)
        
        self.isSelectMode.subscribe(onNext: { [weak self] isSelectMode in
            self?.updateRightBarButtonItems(isSelectMode: isSelectMode)
            self?.collectionView.allowsMultipleSelection = isSelectMode
            self?.clearSelection()
            self?.collectionView.reloadData()
        }).disposed(by: self.disposeBag)
    }
    
    private func clearSelection() {
        self.collectionView.indexPathsForSelectedItems?.forEach({ [unowned self] indexPath in
            self.collectionView.deselectItem(at: indexPath, animated: false)
        })
    }
    
    private func updateRightBarButtonItems(isSelectMode: Bool) {
        guard self.viewModel.context.coordinator?.usage == .manage else { return }
        
        if isSelectMode {
            let cancelButton = UIBarButtonItem(title: L10n.General.Button.Title.cancel, style: .plain, target: nil, action: nil)
            cancelButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.isSelectMode.accept(false)
            }).disposed(by: self.disposeBag)
            
            let deleteButton = UIBarButtonItem(title: L10n.General.Button.Title.delete, style: .plain, target: nil, action: nil)
            deleteButton.tintColor = InterfaceTheme.Color.warning
            deleteButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.deleteSelectedItems()
            }).disposed(by: self.disposeBag)
            
            self.navigationItem.rightBarButtonItems = [deleteButton, cancelButton]
        } else {
            let selectButton = UIBarButtonItem(title: L10n.General.Button.Title.select, style: .plain, target: nil, action: nil)
            selectButton.rx.tap.subscribe(onNext: { [weak self] in
                self?.isSelectMode.accept(true)
            }).disposed(by: self.disposeBag)
            
            self.navigationItem.rightBarButtonItems = [selectButton]
        }
    }
    
    private func deleteSelectedItems() {
        let indexs = self.collectionView.indexPathsForSelectedItems?.map {
            $0.row
        } ?? []
        
        let confirmController = ConfirmViewController(contentText: L10n.Setting.ManageAttachment.Delete.title, onConfirm: { [weak self] viewController in
            viewController.dismiss(animated: true) {
                self?.viewModel.delete(indexs: indexs)
                self?.isSelectMode.accept(false)
            }
        }) { viewController in
            viewController.dismiss(animated: true)
        }
        
        self.present(confirmController, animated: true)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.viewModel.context.coordinator?.usage == .manage {
            if !self.isSelectMode.value {
                collectionView.deselectItem(at: indexPath, animated: false)
                if let attachment = self.viewModel.attachment(at: indexPath.row) {
                    self._showAttachmentView(attachment: attachment, index: indexPath.row)
                }
            }
        } else {
            self.onSelectingAttachment.onNext(self.viewModel.attachment(at: indexPath.row))
        }
    }
        
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let side = (collectionView.bounds.width - Layout.edgeInsets.left - Layout.edgeInsets.right - 10 - 10) / 3
        return CGSize(width: side, height: side)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Layout.edgeInsets
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        self.viewModel.loadCellContent(at: indexPath.row)
    }
    
    private func _showAttachmentView(attachment: Attachment, index: Int) {
        let actionsView = ActionsViewController()

        let view = AttachmentViewFactory.create(attachment: attachment)
        view.sizeAnchor(width: self.view.bounds.width, height: view.size(for: self.view.bounds.width).height)
        
        actionsView.accessoryView = view
        actionsView.title = attachment.kind.rawValue
        
        actionsView.addAction(icon: nil, title: L10n.Attachment.share) { viewController in
            viewController.dismiss(animated: true, completion: {
                let exportManager = ExportManager(editorContext: self.viewModel.dependency.editorContext)
                exportManager.share(from: self, url: attachment.url)
                self.viewModel.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        if attachment.kind == .link {
            let linkInfo = attachment.linkInfo
            actionsView.addAction(icon: nil, title: L10n.Document.Link.open) { viewController in
                viewController.dismiss(animated: true, completion: {
                    if let url = URL(string: linkInfo?.0 ?? "") {
                        self.viewModel.dependency.globalCaptureEntryWindow?.show()
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                })
            }
        } else if attachment.kind == .location {
            actionsView.addAction(icon: nil, title: L10n.CaptureList.Action.openLocation) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let jsonDecoder = JSONDecoder()
                    do {
                        let coord = try jsonDecoder.decode(CLLocationCoordinate2D.self, from: try Data(contentsOf: attachment.url))
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord, addressDictionary:nil))
                        mapItem.openInMaps(launchOptions: [:])
                    } catch {
                        log.error("\(error)")
                    }
                })
            }
        }
                
        actionsView.addAction(icon: nil, title: L10n.General.Button.Title.close) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        actionsView.addAction(icon: nil, title: L10n.General.Button.Title.delete, style: .warning) { viewController in
            viewController.dismiss(animated: true, completion: {
                let confirm = ConfirmViewController(contentText: L10n.General.Button.Title.delete, onConfirm: { viewController in
                    viewController.dismiss(animated: true) {
                        self.viewModel.delete(indexs: [index])
                    }
                }) { viewController in
                    viewController.dismiss(animated: true)
                }
                
                self.present(confirm, animated: true)
            })
        }
        
        actionsView.setCancel { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        self.present(actionsView, animated: true, completion: nil)
        self.viewModel.dependency.globalCaptureEntryWindow?.hide()
    }
}
