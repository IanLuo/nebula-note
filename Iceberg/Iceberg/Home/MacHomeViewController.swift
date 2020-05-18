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
    
    private var dashboardViewController: DashboardViewController!
    private var documentTabsContainerViewController: MacDocumentTabContainerViewController!
    
    convenience init(dashboardViewController: DashboardViewController, documentTabsContainerViewController: MacDocumentTabContainerViewController) {
        self.init()
        self.dashboardViewController = dashboardViewController
        self.documentTabsContainerViewController = documentTabsContainerViewController
    }
    
    public override func viewDidLoad() {
        self.view.addSubview(self.toolBar)
        self.view.addSubview(self.leftPart)
        self.view.addSubview(self.middlePart)
        self.view.addSubview(self.rightPart)
        
        self.setupUI()
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
        self.middlePart.topAnchor.constraint(equalTo: self.toolBar.bottomAnchor).isActive = true
        self.middlePart.leftAnchor.constraint(equalTo: self.leftPart.rightAnchor).isActive = true
        
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
        ideasButton.rx.tap.subscribe().disposed(by: self.disposeBag)
        
        let toggleLeftPartButton = UIButton()
        toggleLeftPartButton.setImage(Asset.Assets.leftPart.image, for: .normal)
        toggleLeftPartButton.rx.tap.subscribe(onNext: { [weak self, unowned toggleLeftPartButton] in
            self?.toggleLeftPartVisiability(visiable: !toggleLeftPartButton.isSelected)
            toggleLeftPartButton.isSelected = !toggleLeftPartButton.isSelected
        }).disposed(by: self.disposeBag)
        
        let toggleMiddlePartButton = UIButton()
        toggleMiddlePartButton.setImage(Asset.Assets.middlePart.image, for: .normal)
        toggleMiddlePartButton.rx.tap.subscribe(onNext: { [weak self, unowned toggleMiddlePartButton] in
            self?.toggleMiddlePartVisiability(visiable: !toggleMiddlePartButton.isSelected)
            toggleMiddlePartButton.isSelected = !toggleMiddlePartButton.isSelected
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
    
    public func chooseTab(index: Int, subTab: Int?) {
        if let subTab = subTab {
            self.dashboardViewController.selectOnSubtab(tab: index, subtab: subTab)
        } else {
            self.dashboardViewController.selectOnTab(index: index)
        }
    }
    
    private func toggleLeftPartVisiability(visiable: Bool) {
        if visiable {
            self.leftPart.constraint(for: .width)?.constant = 0
        } else {
            self.leftPart.constraint(for: .width)?.constant = Constants.leftWidth
        }
        UIView.animate(withDuration: 0.2) {
            self.leftPart.setNeedsLayout()
        }
    }
    
    private func toggleMiddlePartVisiability(visiable: Bool) {
        if visiable {
            self.middlePart.constraint(for: .width)?.constant = 0
        } else {
            self.middlePart.constraint(for: .width)?.constant = Constants.middleWidth
        }
        UIView.animate(withDuration: 0.2) {
            self.middlePart.setNeedsLayout()
        }
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
    }
}

var lastChildViewController: UIViewController?
