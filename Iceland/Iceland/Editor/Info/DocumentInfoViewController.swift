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

public class DocumentInfoViewController: TransitionViewController {
    public var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background2
        return view
    }()
    
    private lazy var _backButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Assets.right.image.fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background3, size: .singlePoint), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
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
        
        self.setupUI()
    }
    
    private var _exportViewController: ExportSelectViewController?
    private let _exportViewContainer: UIView = UIView()
    
    private func setupUI() {
        self.view.addSubview(self.contentView)
        
        self.contentView.sideAnchor(for: [.top, .bottom, .right], to: self.view, edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        self.contentView.sizeAnchor(width: 240)
        
        self.contentView.addSubview(self._backButton)
        self._backButton.sideAnchor(for: [.right, .top], to: self.contentView, edgeInset: 30, considerSafeArea: true)
        self._backButton.sizeAnchor(width: 40, height: 40)
        
        let exportViewController = ExportSelectViewController(viewModel: self._viewModel)
        exportViewController.delegate = self
        self.contentView.addSubview(self._exportViewContainer)
        self._exportViewContainer.sideAnchor(for: [.left, .bottom, .right], to: self.contentView, edgeInset: 0)
        self._exportViewContainer.sizeAnchor(height: 120)
            
        self._exportViewContainer.addSubview(exportViewController.view)
        exportViewController.view.allSidesAnchors(to: self._exportViewContainer, edgeInset: 0)
        
        self.addChild(exportViewController)
        exportViewController.didMove(toParent: self)
        self._exportViewController = exportViewController
    }
    
    @objc func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension DocumentInfoViewController: ExportSelectViewControllerDelegate {
    public func didExport(url: URL, viewController: UIViewController) {
        
    }
}

extension DocumentInfoViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}
