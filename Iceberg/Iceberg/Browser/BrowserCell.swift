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

public class BrowserCell: UITableViewCell {
    public static let reuseIdentifier: String = "BrowserCell"
    
    public let onPresentingModalViewController: PublishSubject<(UIViewController, UIView)> = PublishSubject()
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
        
        imageView.clipsToBounds = true
        imageView.contentMode = .center
        return imageView
    }()
    
    public let titleLabel: UILabel = {
        let label = LabelStyle.title.create()
        label.numberOfLines = 0
        return label
    }()
    
    public let lastModifiedDateLabel: UILabel = {
        let label = LabelStyle.description.create()
        return label
    }()
    
    public var actionButton: RoundButton = RoundButton()
//    public let enterChildButton: RoundButton = RoundButton()
    public let actionsContainerView: UIView = UIView()
    public let container: UIView = {
        let view = UIView()
        view.roundConer(radius: Layout.cornerRadius)
        return view
    }()
    
    private var cellModel: BrowserCellModel?
    
    private let disposeBag = DisposeBag()
    
    public var reuseDisposeBag = DisposeBag()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self._setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _setupUI() {
        self.contentView.addSubview(self.container)
        
        self.container.allSidesAnchors(to: self.contentView, edgeInsets: .init(top: Layout.edgeInsets.top, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        
        self.container.addSubview(self.iconView)
        self.container.addSubview(self.titleLabel)
        self.container.addSubview(self.actionsContainerView)
        self.container.addSubview(self.lastModifiedDateLabel)
        
        self.interface { [weak self] (me, theme) in
            let cell = me as! BrowserCell
            cell.backgroundColor = theme.color.background1
            cell.titleLabel.textColor = theme.color.interactive
            cell.titleLabel.font = theme.font.title
            cell.contentView.backgroundColor = theme.color.background1
            self?.container.backgroundColor = theme.color.background2
            self?.lastModifiedDateLabel.textColor = theme.color.descriptive
            self?.lastModifiedDateLabel.font = theme.font.footnote
        }
        
        self.iconView.sideAnchor(for: [.left, .top, .bottom],
                                 to: self.container,
                                 edgeInsets: .init(top: 10, left: 10, bottom: -10, right: 0))
        self.iconView.ratioAnchor(2.0 / 3)
        self.iconView.sizeAnchor(height: 100)
        
        self.iconView.rowAnchor(view: self.titleLabel, space: 10, alignment: .top)
        self.titleLabel.sideAnchor(for: [.top],
                                   to: self.container,
                                   edgeInsets: .init(top: 10, left: 0, bottom: -10, right: 0))
        
        self.titleLabel.rowAnchor(view: self.actionsContainerView, space: 10, alignment: .top)
        self.actionsContainerView.sideAnchor(for: [.top, .bottom, .right],
                                             to: self.container,
                                             edgeInsets: .init(top: 10, left: 0, bottom: 0, right: 0))
        
        self.iconView.rowAnchor(view: self.lastModifiedDateLabel, space: 10, alignment: .bottom)
        self.titleLabel.columnAnchor(view: self.lastModifiedDateLabel, space: 8, alignment: .leading)
        self.lastModifiedDateLabel.sizeAnchor(height: 14)
        

        self.container.roundConer(radius: Layout.cornerRadius)
        self.enableHover(on: self.container)
    }
    
    public func configure(cellModel: BrowserCellModel) {
        self.reuseDisposeBag = DisposeBag() // this line is important, if missed, the cell might bind multiple times
        
        self.cellModel = cellModel
        
        self.titleLabel.text = cellModel.url.packageName
        self.iconView.image = cellModel.cover ?? Asset.Assets.smallIcon.image
        self.lastModifiedDateLabel.text = cellModel.updateDate.format(DateFormatter.Style.short, timeStyle: DateFormatter.Style.short)
        
        self._loadActionsView()
        
        if self.cellModel?.shouldShowChooseHeadingIndicator == true {
            self.accessoryType = .disclosureIndicator
        } else {
            self.accessoryType = .none
        }
        
        if cellModel.downloadingProcess < 100 {
            self.iconView.showProcessingAnimation()
        } else {
            self.iconView.hideProcessingAnimation()
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
                button.setIcon(Asset.Assets.more.image.fill(color: theme.color.descriptive), for: .normal)
                button.setBackgroundColor(theme.color.background2, for: .normal)
            }
        }
        actionButton.tapped { [weak self] view in
            guard let strongSelf = self else { return }
            strongSelf.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.hide()
            strongSelf.onPresentingModalViewController.onNext((strongSelf.actionViewController, view))
        }
        
        self.actionButton = actionButton
        
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
        actionButton.tapped { [weak self] view in
           guard let strongSelf = self else { return }
            strongSelf.onPresentingModalViewController.onNext((strongSelf.actionViewController, view))
            strongSelf.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.hide()
        }
        
        self.actionButton = actionButton

        let enterButton = UIButton()
        enterButton.interface { (me, theme) in
            if let button = me as? UIButton {
                button.setBackgroundImage(UIImage.create(with: theme.color.background3, size: .singlePoint), for: .normal)
                button.setImage(Asset.Assets.next.image.fill(color: theme.color.interactive), for: .normal)
            }
        }
        
        enterButton.roundConer(radius: 10)
        
        enterButton.rx.tap.subscribe(onNext: { [weak self] in
            if let cellModel = self?.cellModel {
                self?.onEnter.onNext(cellModel.url)
            }
        }).disposed(by: self.disposeBag)
        
        view.addSubview(actionButton)
        view.addSubview(enterButton)
        actionButton.sideAnchor(for: [.left, .top, .right], to: view, edgeInset: 0)
        actionButton.sizeAnchor(width: 49)
        actionButton.columnAnchor(view: enterButton)
        enterButton.sideAnchor(for: [.left, .bottom, .right], to: view, edgeInsets: .init(top: 0, left: 0, bottom: -5, right: -5))
        enterButton.sizeAnchor(width: 44, height: 44)
        return view
    }()
    
    private var actionViewController: UIViewController {
        let actionsViewController = ActionsViewController()
        actionsViewController.title = L10n.Browser.Actions.title
        actionsViewController.fromView = self.actionButton
        
        self._createNewDocumentActionItem(for: actionsViewController)
        self._createRenameActionItem(for: actionsViewController)
        self._createMoveActionItem(for: actionsViewController)
        self._createDuplicateActionItem(for: actionsViewController)
        self._createEditCoverActionItem(for: actionsViewController)
        self._createExportActionItem(for: actionsViewController)
        self._createDeleteActionItem(for: actionsViewController)
        
        actionsViewController.setCancel { [weak self] viewController in
            viewController.dismiss(animated: true, completion: nil)
            self?.cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        return actionsViewController
    }
    
    private func _createNewDocumentActionItem(for actionsViewController: ActionsViewController) {
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
    
    private func _createDeleteActionItem(for actionsViewController: ActionsViewController) {
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
    
    public func _createDuplicateActionItem(for actionsViewController: ActionsViewController) {
        guard let cellModel = self.cellModel else { return }
        
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Browser.Actions.duplicate) {
            cellModel.duplicate().subscribe(onNext: { [weak self] url in
                self?.onDuplicateDocument.onNext(url)
            }).disposed(by: self.disposeBag)
        }
    }
    
    public func _createMoveActionItem(for actionsViewController: ActionsViewController) {
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
    
    private func _createRenameActionItem(for actionsViewController: ActionsViewController) {
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
    
    private func _createEditCoverActionItem(for  actionsViewController: ActionsViewController) {
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
    
    private func _createExportActionItem(for actionsViewController: ActionsViewController) {
        actionsViewController.addActionAutoDismiss(icon: nil, title: L10n.Attachment.share) { [weak self] in
            
            guard let cellModel = self?.cellModel else { return }
            
            cellModel.coordinator?.showExportSelector(document: cellModel.url, at: self, complete: { [weak cellModel] in
                cellModel?.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
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


public class BrowserCellWithSubFolder: BrowserCell {
    public  static let reuseIdentifierForBrowserCellWithSubFolder = "BrowserCellWithSubFolder"
    
    private let _subFolderIndicatorView: UIView = {
       let view = UIView()
        view.roundConer(radius: 8)
        view.layer.borderWidth = 1
        view.interface { (me, interface) in
            me.layer.borderColor = interface.color.background2.cgColor
            me.backgroundColor = interface.color.background1
        }
        
        return view
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.insertSubview(self._subFolderIndicatorView, at: 0)
        
        self._subFolderIndicatorView.allSidesAnchors(to: self.contentView, edgeInsets: .init(top: Layout.edgeInsets.top + 5,
                                                                                             left: Layout.edgeInsets.left + 5,
                                                                                             bottom: 5,
                                                                                             right: -(Layout.edgeInsets.right)))
        
        if let rightConstraint = self.container.constraint(for: Position.right) {
            self.contentView.removeConstraint(rightConstraint)
            self.container.sideAnchor(for: Position.right, to: self.contentView, edgeInset: Layout.edgeInsets.right + 5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
