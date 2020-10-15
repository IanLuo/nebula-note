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
    
    private lazy var _backButton: RoundButton = {
        let button = RoundButton()
        button.setIcon(Asset.Assets.right.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
        return button
    }()
    
    private lazy var _helpButton: RoundButton = {
        let button = RoundButton()
        button.setIcon(Asset.Assets.infomation.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
        return button
    }()
    
    public var fromView: UIView?
    
    private let transitionDelegate: UIViewControllerTransitioningDelegate = FadeBackgroundTransition(animator: MoveInAnimtor(from: MoveInAnimtor.From.right))
    
    private var _viewModel: DocumentEditViewModel!
    
    public convenience init(viewModel: DocumentEditViewModel) {
        self.init(nibName: nil, bundle: nil)
        
        self._viewModel = viewModel
        self.modalPresentationStyle = .overCurrentContext
        self.transitioningDelegate = self.transitionDelegate
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self._backButton.tapped { [weak self] _ in
            self?.cancel()
        }
        
        self._helpButton.tapped { [weak self] _ in
            self?.showHelpTopics()
        }
        
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.addSubview(self.contentView)
        
        self.contentView.sideAnchor(for: [.top, .bottom, .right], to: self.view, edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        self.contentView.sizeAnchor(width: 240)
        
        self.contentView.addSubview(self._backButton)
        self._backButton.sideAnchor(for: [.traling, .top], to: self.contentView, edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -Layout.edgeInsets.right), considerSafeArea: true)
        self._backButton.sizeAnchor(width: 44)
        
        self.contentView.addSubview(self._helpButton)
        self._helpButton.sideAnchor(for: [.leading, .top], to: self.contentView, edgeInsets: UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: 0), considerSafeArea: true)
        self._helpButton.sizeAnchor(width: 44)
        
        let exportViewController = ExportSelectViewController(exporterManager: self._viewModel.dependency.exportManager)
        exportViewController.delegate = self
        
        let publishController = PublishSelectViewController(exporterManager: self._viewModel.dependency.exportManager, publishFactory: self._viewModel.dependency.publishFactory)
        publishController.delegate = self
        
        let basicInfoViewController = BasicInfoViewController(viewModel: self._viewModel)

        self.contentView.addSubview(exportViewController.view)
        self.contentView.addSubview(publishController.view)
        self.contentView.addSubview(basicInfoViewController.view)
        
        self._backButton.columnAnchor(view: basicInfoViewController.view, space: 30, alignment: [])
        
        basicInfoViewController.view.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        
        basicInfoViewController.view.columnAnchor(view: publishController.view, space: 10)
        
        publishController.view.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        publishController.view.sizeAnchor(height: 120)
        
        publishController.view.columnAnchor(view: exportViewController.view, space: 10)
        
        exportViewController.view.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        exportViewController.view.sideAnchor(for: .bottom, to: self.contentView, edgeInset: 10, considerSafeArea: true)
        exportViewController.view.sizeAnchor(height: 120)
        
        self.addChild(publishController)
        publishController.didMove(toParent: self)
        
        self.addChild(exportViewController)
        exportViewController.didMove(toParent: self)
        
        self.addChild(basicInfoViewController)
        basicInfoViewController.didMove(toParent: self)
    }
    
    @objc func cancel() {
        self.dismiss(animated: true, completion: nil)
        self.didCloseAction?()
    }
    
    @objc func showHelpTopics() {
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
        
        actionsViewController.present(from: self, at: self.view)
    }
}

extension DocumentInfoViewController: ExportSelectViewControllerDelegate {
    public func didSelectExportType(_ type: ExportType, exportManager: ExportManager) {
        exportManager.export(isMember: self._viewModel.isMember, url: self._viewModel.url, type: type, completion: { [weak self] url in
            guard let strongSelf = self else { return }
            exportManager.preview(from: strongSelf, url: url)
        }) { error in
            // TODO:
        }
    }
}

extension DocumentInfoViewController: PublishSelectViewControllerDelegate {
    public func didSelectPublisher(_ type: @escaping (UIViewController) -> Publishable) {
        self.view.showProcessingAnimation()
        
        self._viewModel.dependency.exportManager.export(isMember: true, url: self._viewModel.url, type: .markdown) { [unowned self] url in
            do {
                let attachments = self._viewModel.attachments
                
                let publishable = self._viewModel
                    .dependency
                    .publishFactory
                    .createPublishBuilder(publisher: .medium,
                                          uploader: .oneDrive,
                                          from: self)
                
                publishable(url.packageName, try String(contentsOf: url), attachments)
                    .do(onError: { error in
                        self.showAlert(title: "fail", message: "\(error)")
                        self.view.hideProcessingAnimation()
                    })
                    .subscribe(onNext: {
                        self.view.hideProcessingAnimation()
                        self.showAlert(title: "Success", message: "\"\(self._viewModel.url.packageName)\" is published successfully")
                    })
                    .disposed(by: self.disposeBag)
            } catch {
                self.showAlert(title: "fail", message: "\(error)")
                self.view.hideProcessingAnimation()
            }
        } failure: { error in
            self.showAlert(title: "fail", message: "\(error)")
            self.view.hideProcessingAnimation()
        }
    }
}

extension DocumentInfoViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}
