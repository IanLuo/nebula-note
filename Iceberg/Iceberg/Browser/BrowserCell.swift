//
//  BrowserCell.swift
//  Iceberg
//
//  Created by ian luo on 2019/9/29.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import Core
import Interface

public protocol BrowserCellProtocol: class {
    func configure(cellModel: BrowserCellModel)
}

public class BrowserCell: UICollectionViewCell {
    public let onPresentingModalViewController: PublishSubject<(UIViewController, UIView)> = PublishSubject()
    public let onCreateSubDocument: PublishSubject<URL> = PublishSubject()
    public let onRenameDocument: PublishSubject<URL> = PublishSubject()
    public let onDuplicateDocument: PublishSubject<URL> = PublishSubject()
    public let onDeleteDocument: PublishSubject<URL> = PublishSubject()
    public let onMoveDocument: PublishSubject<(URL, URL)> = PublishSubject()
    public let onChangeCover: PublishSubject<URL> = PublishSubject()
    public let onEnter: PublishSubject<URL> = PublishSubject()
    
    public let container: UIView = {
        let view = UIView()
        view.roundConer(radius: Layout.cornerRadius)
        return view
    }()
    
    var cellModel: BrowserCellModel?
    
    let disposeBag = DisposeBag()
    
    public var reuseDisposeBag = DisposeBag()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.container)
        self.container.allSidesAnchors(to: self.contentView,
                                       edgeInsets: .init(top: Layout.edgeInsets.top,
                                                         left: Layout.edgeInsets.left,
                                                         bottom: 0,
                                                         right: -Layout.edgeInsets.right))
        
        self.contentView.insertSubview(self.subFolderIndicatorView, at: 0)
        
        self.subFolderIndicatorView.allSidesAnchors(to: self.contentView, edgeInsets: .init(top: Layout.edgeInsets.top + 5,
                                                                                            left: Layout.edgeInsets.left + 5,
                                                                                            bottom: 5,
                                                                                            right: -(Layout.edgeInsets.right)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showAsFolder(_ bool: Bool) {
        
        self.subFolderIndicatorView.isHidden = !bool
        
        if let rightConstraint = self.container.constraint(for: Position.right) {
            self.contentView.removeConstraint(rightConstraint)
            self.container.sideAnchor(for: Position.right, to: self.contentView, edgeInset: bool ? Layout.edgeInsets.right + 5 : Layout.edgeInsets.right)
        }
    }
    
    var actionViewController: ActionsViewController {
        let actionsViewController = ActionsViewController()
        actionsViewController.title = L10n.Browser.Actions.title
        
        self.createNewDocumentActionItem(for: actionsViewController)
        self.createRenameActionItem(for: actionsViewController)
        self.createMoveActionItem(for: actionsViewController)
        self.createDuplicateActionItem(for: actionsViewController)
        self.createEditCoverActionItem(for: actionsViewController)
        self.createExportActionItem(for: actionsViewController)
        self.createDeleteActionItem(for: actionsViewController)
        
        actionsViewController.setCancel { [weak self] viewController in
            viewController.dismiss(animated: true, completion: nil)
            self?.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        return actionsViewController
    }
    
    private let subFolderIndicatorView: UIView = {
       let view = UIView()
        view.roundConer(radius: 8)
        view.layer.borderWidth = 1
        view.interface { (me, interface) in
            me.layer.borderColor = interface.color.background2.cgColor
            me.backgroundColor = interface.color.background1
        }
        
        return view
    }()
    
    func createNewDocumentActionItem(for actionsViewController: ActionsViewController) {
        if (self.cellModel?.coordinator?.dependency.purchaseManager.isMember.value ?? true) || (self.cellModel?.url.levelsToRoot ?? 0) < 2 {
            actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.newSub) { [weak self] in
                guard let strongSelf = self else { return }
                guard let cellModel = strongSelf.cellModel else { return }
                cellModel.createChildDocument(title: L10n.Browser.Title.untitled)
                    .subscribe(onNext: { url in
                        strongSelf.onCreateSubDocument.onNext(url)
                    }).disposed(by: strongSelf.disposeBag)
                
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
        } else {
            actionsViewController.addActionAutoDismiss(icon: Asset.Assets.proLabel.image, title: L10n.Browser.Actions.newSub) { [weak self] in
                guard let cellModel = self?.cellModel else { return }
                cellModel.coordinator?.showMembership()
                
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
        }
    }
    
    func createDeleteActionItem(for actionsViewController: ActionsViewController) {
        actionsViewController.addAction(icon: nil, title: L10n.Browser.Actions.delete, style: .warning) { [weak self] (viewController: UIViewController, view: UIView) -> Void in
            guard let strongSelf = self else { return }
            guard let cellModel = strongSelf.cellModel else { return }
            
            let confirmViewController = ConfirmViewController()
            confirmViewController.contentText = L10n.Browser.Actions.Delete.confirm(cellModel.url.packageName)
            confirmViewController.confirmAction = {
                $0.dismiss(animated: true, completion: {
                    viewController.dismiss(animated: true, completion: {
                        cellModel
                            .deleteDocument()
                            .subscribe(onNext: { url in
                                strongSelf.onDeleteDocument.onNext(url)
                            }).disposed(by: strongSelf.disposeBag)
                    })
                    cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }
            
            confirmViewController.cancelAction = {
                $0.dismiss(animated: true, completion: nil)
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            confirmViewController.present(from: viewController, at: view)
        }
    }
    
    public func createDuplicateActionItem(for actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.duplicate) {
            cellModel.duplicate().subscribe(onNext: { [weak self] url in
                self?.onDuplicateDocument.onNext(url)
            }).disposed(by: self.disposeBag)
        }
    }
    
    public func createMoveActionItem(for actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addAction(icon: nil, title: L10n.Browser.Action.MoveTo.title) { viewController in
            
            cellModel.loadAllFiles(completion: { files in
                
                viewController.dismiss(animated: true, completion: {  [weak self] in
                    guard let strongSelf = self else { return }
                    
                    let selector = SelectorViewController(heightRatio: 0.8)
                    selector.title = L10n.Browser.Action.MoveTo.msg
                    selector.fromView = self
                    let root: String = "\\"
                    selector.addItem(title: root, enabled: cellModel.url.parentDocumentURL != URL.documentBaseURL)
                    
                    let isMember = self?.cellModel?.coordinator?.dependency.purchaseManager.isMember.value == true
                    
                    for file in files {
                        let shouldEnable = file.levelsToRoot <= 1 || isMember
                        let indent = Array(repeating: "   ", count: file.levelsToRoot - 1).reduce("") { $0 + $1 }
                        let title = indent + file.wrapperURL.packageName
                        selector.addItem(icon: shouldEnable ? nil : Asset.Assets.proLabel.image,
                                         title: title,
                                         description: nil,
                                         enabled: file.documentRelativePath != cellModel.url.documentRelativePath
                                            && file.documentRelativePath != cellModel.url.parentDocumentURL.documentRelativePath
                                            && shouldEnable)
                    }
                    
                    selector.onCancel = { viewController in
                        viewController.dismiss(animated: true, completion: {
                            cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                        })
                    }
                    
                    selector.onSelection = { index, viewController in
                        viewController.dismiss(animated: true, completion: {
                            
                            cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                            
                            if index == 0 {
                                cellModel.move(to: URL.documentBaseURL).subscribe(onNext: { fromURL, toURL in
                                    strongSelf.onMoveDocument.onNext((fromURL, toURL))
                                }).disposed(by: strongSelf.disposeBag)
                            } else {
                                let under = files[index - 1]
                                cellModel.move(to: under).subscribe(onNext: { fromURL, toURL in
                                    strongSelf.onMoveDocument.onNext((fromURL, toURL))
                                }).disposed(by: strongSelf.disposeBag)
                            }
                        })
                    }
                    
                    strongSelf.onPresentingModalViewController.onNext((selector, strongSelf))
                })
            })
        }
    }
    
    func createRenameActionItem(for actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.rename) {
            let renameFormViewController = ModalFormViewController()
            let title = L10n.Browser.Action.Rename.newName
            renameFormViewController.title = title
            renameFormViewController.addTextFied(title: title, placeHoder: "", defaultValue: cellModel.url.packageName) // 不需要显示 placeholder, default value 有值
            renameFormViewController.onSaveValueAutoDismissed = { [weak self] formValue in
                guard let strongSelf = self else { return }
                if let newName = formValue[title] as? String {
                    cellModel.rename(to: newName.escaped)
                        .subscribe(onNext: { fromURL, toURL in
                            strongSelf.onRenameDocument.onNext(toURL)
                        }).disposed(by: strongSelf.disposeBag)
                }
            }
            
            renameFormViewController.onCancel = { _ in
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            // 显示给用户，是否可以使用这个文件名
            renameFormViewController.onValidating = { formData in
                if let cellModel = self.cellModel {
                    if !cellModel.isNameAvailable(newName: formData[title] as! String) {
                        return [title: L10n.Browser.Action.Rename.Warning.nameIsTaken]
                    }
                }
                
                return [:]
            }
            
            renameFormViewController.onCancel = { [weak self] viewController in
                guard let strongSelf = self else { return }
                guard let cellModel = strongSelf.cellModel else { return }
                viewController.dismiss(animated: true, completion: nil)
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            self.onPresentingModalViewController.onNext((renameFormViewController, self))
        }
    }
    
    func createEditCoverActionItem(for  actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.cover) { [weak self] in
            guard let strongSelf = self else { return }
            let coverPicker = CoverPickerViewController()
            coverPicker.onSelecedCover = { cover in
                cellModel.updateCover(cover: cover)
                    .subscribe(onNext: { url in
                        strongSelf.onChangeCover.onNext(url)
                    }).disposed(by: strongSelf.disposeBag)
                
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            coverPicker.onCancel = {
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            self?.onPresentingModalViewController.onNext((coverPicker, strongSelf))
        }
    }
    
    func createExportActionItem(for actionsViewController: ActionsViewController) {
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Attachment.share) { [weak self] in
            
            guard let cellModel = self?.cellModel else { return }
            
            cellModel.coordinator?.showExportSelector(document: cellModel.url, at: self, complete: { [weak cellModel] in
                cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
    }
}

extension BrowserCell {
    public override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.container.backgroundColor = InterfaceTheme.Color.background3
            } else {
                self.container.backgroundColor = InterfaceTheme.Color.background2
            }
        }
    }
    
    public override var isSelected: Bool {
        didSet {
            if isSelected {
                self.container.backgroundColor = InterfaceTheme.Color.background3
            } else {
                self.container.backgroundColor = InterfaceTheme.Color.background2
            }
        }
    }
}
