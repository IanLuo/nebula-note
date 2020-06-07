//
//  MacHomeViewController.swift
//  x3Note
//
//  Created by ian luo on 2020/4/25.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import Core
import Interface

public class MacHomeViewController: UIViewController {
    struct Constants {
        static let leftWidth: CGFloat = 300
        static let middleWidth: CGFloat = 375
    }
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    private var toolBar: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background1
        return view
    }()
    private var leftPart: UIView = UIView()
    private var middlePart: UIView = UIView()
    private var rightPart: UIView = UIView()
    
    private let toggleLeftPartButton = UIButton()
    private let toggleMiddlePartButton = UIButton()
    
    private var dashboardViewController: DashboardViewController!
    private var documentTabsContainerViewController: MacDocumentTabContainerViewController!
    
    private weak var coordinator: HomeCoordinator?
    
    convenience init(dashboardViewController: DashboardViewController, coordinator: HomeCoordinator, documentTabsContainerViewController: MacDocumentTabContainerViewController) {
        self.init()
        self.dashboardViewController = dashboardViewController
        self.documentTabsContainerViewController = documentTabsContainerViewController
        self.coordinator = coordinator
    }
    
    public override func viewDidLoad() {
        self.navigationController?.navigationBar.isHidden = true
        self.view.addSubview(self.toolBar)
        self.view.addSubview(self.middlePart)
        self.view.addSubview(self.leftPart)
        self.view.addSubview(self.rightPart)
        
        self.setupUI()
        
        self.toggleLeftPartVisiability(visiable: true, animated: false)
        self.toggleMiddlePartVisiability(visiable: true, animated: false)
    }
    
    public func showDocument(url: URL, editorViewController: DocumentEditorViewController) {
        self.documentTabsContainerViewController.showDocument(url: url, viewController: editorViewController)
    }
    
    public func closeDocument(url: URL) {
        self.documentTabsContainerViewController.closeDocument(url: url)
    }
    
    private func setupUI() {
        self.toolBar.sizeAnchor(height: 80)
        self.toolBar.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInset: 0, considerSafeArea: true)
        
        self.leftPart.sideAnchor(for: [.left, .bottom], to: self.view, edgeInset: 0)
        self.leftPart.sizeAnchor(width: Constants.leftWidth)
        self.leftPart.topAnchor.constraint(equalTo: self.toolBar.bottomAnchor).isActive = true
        
        self.middlePart.sideAnchor(for: .bottom, to: self.view, edgeInset: 0)
        self.middlePart.sizeAnchor(width: Constants.middleWidth)
        
        self.toolBar.columnAnchor(view: self.middlePart, alignment: .none)
        self.leftPart.rowAnchor(view: self.middlePart)
        
        self.rightPart.sideAnchor(for: [.bottom, .right], to: self.view, edgeInset: 0)
        self.rightPart.topAnchor.constraint(equalTo: self.toolBar.bottomAnchor).isActive = true
        self.rightPart.leftAnchor.constraint(equalTo: self.middlePart.rightAnchor).isActive = true
        
        self.setupToolBar()
        self.setupLeftPart()
        self.setupRightPart()
    }
    
    private func setupToolBar() {
        let stackView = UIStackView()
        stackView.distribution = .equalSpacing
        
        let ideasButton = UIButton()
        ideasButton.setImage(Asset.Assets.inspiration.image, for: .normal)
        ideasButton.rx.tap.subscribe(onNext: {
            self.coordinator?.showCaptureEntrance()
        }).disposed(by: self.disposeBag)
        
        self.toggleLeftPartButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.Assets.leftPart.image.fill(color: theme.color.interactive), for: .normal)
            button.setImage(Asset.Assets.leftPart.image.fill(color: theme.color.descriptive), for: .selected)
        }

        self.toggleLeftPartButton.rx.tap.subscribe(onNext: { [weak self, unowned toggleLeftPartButton] in
            self?.toggleLeftPartVisiability(visiable: !toggleLeftPartButton.isSelected)
        }).disposed(by: self.disposeBag)
                
        self.toggleMiddlePartButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.Assets.middlePart.image.fill(color: theme.color.interactive), for: .normal)
            button.setImage(Asset.Assets.middlePart.image.fill(color: theme.color.descriptive), for: .selected)
        }
        
        self.toggleMiddlePartButton.rx.tap.subscribe(onNext: { [weak self, unowned toggleMiddlePartButton] in
            self?.toggleMiddlePartVisiability(visiable: !toggleMiddlePartButton.isSelected)
        }).disposed(by: self.disposeBag)
        
        let actionsStack = UIStackView()
        actionsStack.spacing = 20
        actionsStack.addArrangedSubview(toggleLeftPartButton)
        actionsStack.addArrangedSubview(toggleMiddlePartButton)
        
        stackView.addArrangedSubview(actionsStack)
        stackView.addArrangedSubview(ideasButton)
        
        self.toolBar.addSubview(stackView)
        stackView.sideAnchor(for: [.left, .right], to: self.toolBar, edgeInset: 30)
        stackView.centerAnchors(position: .centerY, to: self.toolBar)
        stackView.sizeAnchor(height: 80)
    }
    
    public func hideLeftAndMiddlePart() {
        self.toggleLeftPartVisiability(visiable: false)
        self.toggleMiddlePartVisiability(visiable: false)
    }
    
    private func setupLeftPart() {
        let nav = Application.createDefaultNavigationControlller(root: self.dashboardViewController, transparentBar: true)
        self.addChildViewController(nav)
        self.leftPart.addSubview(nav.view)
        nav.view.allSidesAnchors(to: self.leftPart, edgeInset: 0)
    }
    
    private func setupRightPart() {
        self.addChild(self.documentTabsContainerViewController)
        
        self.rightPart.addSubview(self.documentTabsContainerViewController.view)
        self.documentTabsContainerViewController.view.allSidesAnchors(to: self.rightPart, edgeInset: 0)
    }
    
    internal func toggleLeftPartVisiability(visiable: Bool, animated: Bool = true) {
        guard visiable != self.isLeftPartVisiable else { return }
        
        if visiable {
            self.leftPart.constraint(for: .left)?.constant = 0
        } else {
            self.leftPart.constraint(for: .left)?.constant = -Constants.leftWidth
        }
        
        self.toggleLeftPartButton.isSelected = visiable
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    }
    
    internal var isLeftPartVisiable: Bool {
        return self.leftPart.constraint(for: .left)?.constant == 0
    }
    
    internal func toggleMiddlePartVisiability(visiable: Bool, animated: Bool = true) {
        guard visiable != self.isMiddlePartVisiable else { return }
        
        if visiable {
            self.leftPart.constraint(for: .right)?.constant = 0
        } else {
            self.leftPart.constraint(for: .right)?.constant = Constants.middleWidth
        }
        
        self.toggleMiddlePartButton.isSelected = visiable
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    }
    
    internal var isMiddlePartVisiable: Bool {
        return self.leftPart.constraint(for: .right)?.constant == 0
    }
    
    public func showInMiddlePart(viewController: UIViewController) {
        if let lastChildViewController = lastChildViewController {
            lastChildViewController.removeFromParent()
            lastChildViewController.view.removeFromSuperview()
        }
        
        self.addChildViewController(viewController)
        self.middlePart.addSubview(viewController.view)
        viewController.view.allSidesAnchors(to: self.middlePart, edgeInset: 0)
        lastChildViewController = viewController
        
        if !self.isMiddlePartVisiable {
            self.toggleMiddlePartVisiability(visiable: true)
        }
    }
}

var lastChildViewController: UIViewController?
