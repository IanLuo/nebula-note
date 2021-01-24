//
//  DocumentInfoViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import Core
import RxSwift

public class DocumentInfoViewController: TransitionViewController {
    public var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background1
        return view
    }()
    
    public var didCloseAction: (() -> Void)?
    
    private let disposeBag = DisposeBag()
    
    private lazy var favoriteButton: RoundButton = {
        let button = RoundButton()
        button.setIcon(Asset.SFSymbols.star.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setIcon(Asset.SFSymbols.starFill.image.fill(color: InterfaceTheme.Color.spotlight), for: .selected)
        button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
        return button
    }()
    
    private lazy var helpButton: RoundButton = {
        let button = RoundButton()
        button.setIcon(Asset.SFSymbols.info.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
        return button
    }()
    
    private lazy var publishButton: UIButton = {
        let button = UIButton()
        button.interface { (view, theme) in
            let button = view as! UIButton
            button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            button.setTitleColor(theme.color.interactive, for: .normal)
        }
        button.setTitle(L10n.Publish.title, for: .normal)
        button.roundConer(radius: 8)
        return button
    }()
    
    public var fromView: UIView?
    
    private let transitionDelegate: UIViewControllerTransitioningDelegate = FadeBackgroundTransition(animator: MoveInAnimtor(from: MoveInAnimtor.From.right))
    
    private var viewModel: DocumentEditorViewModel!
    
    public convenience init(viewModel: DocumentEditorViewModel) {
        self.init(nibName: nil, bundle: nil)
        
        self.viewModel = viewModel
        self.modalPresentationStyle = .overCurrentContext
        self.transitioningDelegate = self.transitionDelegate
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.favoriteButton.tapped { [weak self] button in
            button.showProcessingAnimation()
            button.isEnabled = false
            self?.viewModel.setIsFavorite(self?.viewModel.isFavorite.value != true)
        }
        
        self.helpButton.tapped { [weak self] view in
            self?.showHelpTopics(view: view)
        }
        
        self.publishButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let strongSelf = self else { return }
            self?.viewModel.context.coordinator?.showPublish(from: strongSelf, url: strongSelf.viewModel.url)
        }).disposed(by: self.disposeBag)
        
        self.setupUI()
        
        self.viewModel.isFavorite.asDriver().drive(onNext: { [weak self] isFavorite in
            self?.favoriteButton.isSelected = isFavorite
            self?.favoriteButton.isEnabled = true
            self?.favoriteButton.hideProcessingAnimation()
        }).disposed(by: self.disposeBag)
    }
    
    private func setupUI() {
        self.view.addSubview(self.contentView)
        
        self.contentView.sideAnchor(for: [.top, .bottom, .right], to: self.view, edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        self.contentView.sizeAnchor(width: 240)
        
        self.contentView.addSubview(self.favoriteButton)
        self.favoriteButton.sideAnchor(for: [.traling, .top], to: self.contentView, edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        self.favoriteButton.sizeAnchor(width: 44)
        
        self.contentView.addSubview(self.helpButton)
        self.helpButton.sideAnchor(for: [.leading, .top], to: self.contentView, edgeInsets: UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: 0), considerSafeArea: true)
        self.helpButton.sizeAnchor(width: 44)
        
        let exportViewController = ExportSelectViewController(exporterManager: self.viewModel.dependency.exportManager)
        exportViewController.delegate = self
                
        let basicInfoViewController = BasicInfoViewController(viewModel: self.viewModel)

        self.contentView.addSubview(exportViewController.view)
        self.contentView.addSubview(self.publishButton)
        self.contentView.addSubview(basicInfoViewController.view)
        
        self.favoriteButton.columnAnchor(view: basicInfoViewController.view, space: 30, alignment: [])
        
        basicInfoViewController.view.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        
        basicInfoViewController.view.columnAnchor(view: self.publishButton, space: 10)
        
        self.publishButton.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: Layout.edgeInsets.left)
        self.publishButton.sizeAnchor(height: 60)
        self.publishButton.columnAnchor(view: exportViewController.view, space: 10)
        
        exportViewController.view.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        exportViewController.view.sideAnchor(for: .bottom, to: self.contentView, edgeInset: 10, considerSafeArea: true)
        exportViewController.view.sizeAnchor(height: 120)
                
        self.addChild(exportViewController)
        exportViewController.didMove(toParent: self)
        
        self.addChild(basicInfoViewController)
        basicInfoViewController.didMove(toParent: self)
    }
    
    @objc func cancel() {
        self.dismiss(animated: true, completion: nil)
        self.didCloseAction?()
    }
    
    @objc func showHelpTopics(view: UIView) {
        let actionsViewController = ActionsViewController()
        
        actionsViewController.title = L10n.General.help
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.Help.textEditor) { viewController in
            viewController.dismiss(animated: true) {
                HelpPage.editor.open(from: self)
            }
        }
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.Help.markSyntax) { viewController in
            viewController.dismiss(animated: true) {
                HelpPage.syntax.open(from: self)
            }
        }
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.Help.entrance) { viewController in
            viewController.dismiss(animated: true) {
                HelpPage.entrance.open(from: self)
            }
        }
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.Help.more) { viewController in
            viewController.dismiss(animated: true) {
                HelpPage.allUserGuide.open(from: self)
            }
        }
        
        actionsViewController.present(from: self, at: view)
    }
}

extension DocumentInfoViewController: ExportSelectViewControllerDelegate {
    public func didSelectExportType(_ type: ExportType, exportManager: ExportManager) {
        exportManager.export(isMember: self.viewModel.isMember, url: self.viewModel.url, type: type, useDefaultStyle: true, completion: { [weak self] url in
            guard let strongSelf = self else { return }
            exportManager.preview(from: strongSelf, url: url)
        }) { error in
            // TODO:
        }
    }
}

extension DocumentInfoViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}
