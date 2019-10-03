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
import Interface

public class BrowserCell: UITableViewCell {
    public static let reuseIdentifier: String = "BrowserCell"
    
    public let onPresentingModalViewController: PublishSubject<UIViewController> = PublishSubject()
    public let onCreateSubDocument: PublishSubject<URL> = PublishSubject()
    public let onRenameDocument: PublishSubject<URL> = PublishSubject()
    public let onDuplicateDocument: PublishSubject<URL> = PublishSubject()
    public let onDeleteDocument: PublishSubject<URL> = PublishSubject()
    public let onMoveDocument: PublishSubject<(URL, URL)> = PublishSubject()
    public let onChangeCover: PublishSubject<URL> = PublishSubject()
    public let onEnter: PublishSubject<URL> = PublishSubject()
    
    public let iconView: UIImageView = {
        let imageView = UIImageView()

        imageView.interface { (me, theme) in
            me.backgroundColor = theme.color.background3
        }
        
        imageView.roundConer(radius: Layout.cornerRadius)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    public let titleLabel: UILabel = {
        let label = LabelStyle.title.create()
        label.numberOfLines = 0
        return label
    }()
    public let actionButton: RoundButton = RoundButton()
    public let enterChildButton: RoundButton = RoundButton()
    public let actionsContainerView: UIView = UIView()
    public let container: UIView = {
        let view = UIView()
        view.roundConer(radius: Layout.cornerRadius)
        return view
    }()
    
    private var cellModel: BrowserCellModel?
    
    public var disposeBag = DisposeBag()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self._setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _setupUI() {
        self.contentView.addSubview(self.container)
        
        self.container.allSidesAnchors(to: self.contentView, edgeInsets: .init(top: Layout.edgeInsets.top,
                                                                               left: Layout.edgeInsets.left,
                                                                               bottom: 0,
                                                                               right: -Layout.edgeInsets.right))
        
        self.container.addSubview(self.iconView)
        self.container.addSubview(self.titleLabel)
        self.container.addSubview(self.actionsContainerView)
        
        self.interface { (me, theme) in
            let cell = me as! BrowserCell
            cell.backgroundColor = theme.color.background1
            cell.titleLabel.textColor = theme.color.interactive
            cell.titleLabel.font = theme.font.title
            cell.contentView.backgroundColor = theme.color.background1
            self.container.backgroundColor = theme.color.background2
        }
        
        self.iconView.sideAnchor(for: [.left, .top, .bottom],
                                 to: self.container,
                                 edgeInsets: .init(top: 10,
                                                   left: 10,
                                                   bottom: -10,
                                                   right: 0))
        self.iconView.ratioAnchor(2.0 / 3)
        self.iconView.sizeAnchor(width: 70)
        
        self.iconView.rowAnchor(view: self.titleLabel, space: 10)
        self.titleLabel.sideAnchor(for: [.top, .bottom],
                                   to: self.container,
                                   edgeInsets: .init(top: 10,
                                                     left: 0,
                                                     bottom: -10,
                                                     right: 0))
        
        self.titleLabel.rowAnchor(view: self.actionsContainerView, space: 10)
        self.actionsContainerView.sideAnchor(for: [.top, .bottom, .right],
                                             to: self.container,
                                             edgeInsets: .init(top: 10,
                                                               left: 0,
                                                               bottom: -10,
                                                               right: -10))
    }
    
    public func configure(cellModel: BrowserCellModel) {
        self.disposeBag = DisposeBag() // this line is important, if missed, the cell might bind multiple times
        
        self.cellModel = cellModel
        
        self.titleLabel.text = cellModel.url.packageName
        self.iconView.image = cellModel.cover
        
        self._loadActionsView()
        
        if self.cellModel?.shouldShowChooseHeadingIndicator == true {
            self.accessoryType = .disclosureIndicator
        } else {
            self.accessoryType = .none
        }
    }
    
    private func _loadActionsView() {
        self.actionsContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        if self.cellModel?.hasSubDocuments == true {
            self.actionsContainerView.addSubview(self._actionsViewWithTwoButtons)
            self._actionsViewWithTwoButtons.allSidesAnchors(to: self.actionsContainerView, edgeInset: 0)
        } else {
            self.actionsContainerView.addSubview(self._actionsViewWithOneButton)
            self._actionsViewWithOneButton.allSidesAnchors(to: self.actionsContainerView, edgeInset: 0)
        }
    }
    
    private lazy var _actionsViewWithOneButton: UIView = {
        let view = UIView()
        
        let actionButton = RoundButton()
        actionButton.isHidden = self.cellModel?.shouldShowActions == false
        actionButton.interface { (me, theme) in
            if let button = me as? RoundButton {
                actionButton.setIcon(Asset.Assets.more.image.fill(color: theme.color.descriptive), for: .normal)
                actionButton.setBackgroundColor(theme.color.background2, for: .normal)
            }
        }
        actionButton.tapped { _ in
            self.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.hide()
            self.onPresentingModalViewController.onNext(self.actionViewController)
        }
        
        view.addSubview(actionButton)
        actionButton.sizeAnchor(width: 44)
        view.sizeAnchor(width: 44)
        actionButton.centerAnchors(position: [.centerX, .centerY], to: view)
        
        return view
    }()
    
    private lazy var _actionsViewWithTwoButtons: UIView = {
        let view = UIView()
        
        let actionButton = RoundButton()
        actionButton.isHidden = self.cellModel?.shouldShowActions == false
        actionButton.interface { (me, theme) in
            if let button = me as? RoundButton {
                actionButton.setIcon(Asset.Assets.more.image.fill(color: theme.color.descriptive), for: .normal)
                actionButton.setBackgroundColor(theme.color.background2, for: .normal)
            }
        }
        actionButton.tapped { _ in
            self.onPresentingModalViewController.onNext(self.actionViewController)
            self.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.hide()
        }
        
        let enterButton = RoundButton()
        enterButton.interface { (me, theme) in
            if let button = me as? RoundButton {
                enterButton.setBackgroundColor(theme.color.background2, for: .normal)
                enterButton.setIcon(Asset.Assets.next.image.fill(color: theme.color.spotlight), for: .normal)
            }
        }
        
        enterButton.tapped { _ in
            if let cellModel = self.cellModel {
                self.onEnter.onNext(cellModel.url)
            }
        }
        
        view.addSubview(actionButton)
        view.addSubview(enterButton)
        actionButton.sideAnchor(for: [.left, .top, .right], to: view, edgeInset: 0)
        actionButton.sizeAnchor(width: 44)
        actionButton.columnAnchor(view: enterButton)
        enterButton.sideAnchor(for: [.left, .bottom, .right], to: view, edgeInset: 0)
        enterButton.sizeAnchor(width: 44)
        
        return view
    }()
    
    private var actionViewController: UIViewController {
        let actionsViewController = ActionsViewController()
        actionsViewController.title = L10n.Browser.Actions.title
        
        self._createNewDocumentActionItem(for: actionsViewController)
        self._createRenameActionItem(for: actionsViewController)
        self._createMoveActionItem(for: actionsViewController)
        self._createDuplicateActionItem(for: actionsViewController)
        self._createEditCoverActionItem(for: actionsViewController)
        self._createExportActionItem(for: actionsViewController)
        self._createDeleteActionItem(for: actionsViewController)
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        return actionsViewController
    }
    
    private func _createNewDocumentActionItem(for actionsViewController: ActionsViewController) {
        actionsViewController.addActionAutoDismiss(icon: Asset.Assets.add.image, title: L10n.Browser.Action.new) {
            guard let cellModel = self.cellModel else { return }
            cellModel.createChildDocument(title: L10n.Browser.Title.untitled)
                .subscribe(onNext: { url in
                    self.onCreateSubDocument.onNext(url)
                }).disposed(by: self.disposeBag)
            
            cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
    }
    
    private func _createDeleteActionItem(for actionsViewController: ActionsViewController) {
        actionsViewController.addAction(icon: Asset.Assets.trash.image, title: L10n.Browser.Actions.delete, style: .warning) { viewController in
            guard let cellModel = self.cellModel else { return }
            
            let confirmViewController = ConfirmViewController()
            confirmViewController.contentText = L10n.Browser.Actions.Delete.confirm
            confirmViewController.confirmAction = {
                $0.dismiss(animated: true, completion: {
                    viewController.dismiss(animated: true, completion: {
                        cellModel
                            .deleteDocument()
                            .subscribe(onNext: { url in
                                self.onDeleteDocument.onNext(url)
                            }).disposed(by: self.disposeBag)
                    })
                    cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            }
            
            confirmViewController.cancelAction = {
                $0.dismiss(animated: true, completion: nil)
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            viewController.present(confirmViewController, animated: true, completion: nil)
        }
    }
    
    public func _createDuplicateActionItem(for actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.duplicate) {
            cellModel.duplicate().subscribe(onNext: { url in
                self.onDuplicateDocument.onNext(url)
            }).disposed(by: self.disposeBag)
        }
    }
    
    public func _createMoveActionItem(for  actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addAction(icon: nil, title: L10n.Browser.Action.MoveTo.title) { viewController in
            
            cellModel.loadAllFiles(completion: { [unowned self] files in
                
                viewController.dismiss(animated: true, completion: {
                    let selector = SelectorViewController()
                    selector.title = L10n.Browser.Action.MoveTo.msg
                    selector.fromView = self
                    let root: String = "\\"
                    selector.addItem(title: root, enabled: cellModel.url.parentDocumentURL != nil)
                    
                    for file in files {
                        let indent = Array(repeating: "   ", count: file.levelsToRoot - 1).reduce("") { $0 + $1 }
                        let title = indent + file.wrapperURL.packageName
                        selector.addItem(icon: nil,
                                         title: title,
                                         description: nil,
                                         enabled: file.documentRelativePath != cellModel.url.documentRelativePath
                                            && file.documentRelativePath != cellModel.url.parentDocumentURL?.documentRelativePath)
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
                                    self.onMoveDocument.onNext((fromURL, toURL))
                                }).disposed(by: self.disposeBag)
                            } else {
                                let under = files[index - 1]
                                cellModel.move(to: under).subscribe(onNext: { fromURL, toURL in
                                    self.onMoveDocument.onNext((fromURL, toURL))
                                }).disposed(by: self.disposeBag)
                            }
                        })
                    }
                    
                    self.onPresentingModalViewController.onNext(selector)
                })
            })
        }
    }
    
    private func _createRenameActionItem(for actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.rename) {
            let renameFormViewController = ModalFormViewController()
            let title = L10n.Browser.Action.Rename.newName
            renameFormViewController.title = title
            renameFormViewController.addTextFied(title: title, placeHoder: "", defaultValue: cellModel.url.packageName) // 不需要显示 placeholder, default value 有值
            renameFormViewController.onSaveValueAutoDismissed = { formValue in
                if let newName = formValue[title] as? String {
                    cellModel.rename(to: newName)
                        .subscribe(onNext: { fromURL, toURL in
                            self.onRenameDocument.onNext(toURL)
                        }).disposed(by: self.disposeBag)
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
            
            renameFormViewController.onCancel = { viewController in
                guard let cellModel = self.cellModel else { return }
                viewController.dismiss(animated: true, completion: nil)
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            self.onPresentingModalViewController.onNext(renameFormViewController)
        }
    }
    
    private func _createEditCoverActionItem(for  actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.cover) {
            let coverPicker = CoverPickerViewController()
            coverPicker.onSelecedCover = { cover in
                cellModel
                    .updateCover(cover: cover)
                    .subscribe(onNext: { url in
                        self.onChangeCover.onNext(url)
                    }).disposed(by: self.disposeBag)
                
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            coverPicker.onCancel = {
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            self.onPresentingModalViewController.onNext(coverPicker)
        }
    }
    
    private func _createExportActionItem(for actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Document.Export.title) {
            guard let exportManager = cellModel.coordinator?.dependency.exportManager else { return }
            
            let selector = SelectorViewController()
            selector.title = L10n.Document.Export.msg
            for item in exportManager.exportMethods {
                selector.addItem(title: item.title)
            }
            
            selector.onSelection = { index, viewController in
                viewController.dismiss(animated: true, completion: {
                    cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    exportManager.export(url: cellModel.url, type:exportManager.exportMethods[index], completion: { url in
                        
                        let shareViewController = exportManager.createShareViewController(url: url)
                        self.onPresentingModalViewController.onNext(shareViewController)
                    }, failure: { error in
                        // TODO: show error
                    })
                })
            }
            
            selector.onCancel = { viewController in
                viewController.dismiss(animated: true, completion: nil)
                cellModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
            
            self.onPresentingModalViewController.onNext(selector)
        }
    }
}

extension BrowserCell {
    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = InterfaceTheme.Color.background2
        } else {
            self.backgroundColor = InterfaceTheme.Color.background1
        }
    }
    
    override public func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.backgroundColor = InterfaceTheme.Color.background2
        } else {
            self.backgroundColor = InterfaceTheme.Color.background1
        }
    }
}
