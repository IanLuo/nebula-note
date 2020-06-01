//
//  MacDocumentTabContainerViewController.swift
//  Interface
//
//  Created by ian luo on 2020/5/2.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import Core
import RxSwift

public protocol MacDocumentTabContainerViewControllerDelegate: class {
    func didCloseDocument(url: URL, editorViewController: DocumentEditorViewController)
}

public class MacDocumentTabContainerViewController: UIViewController {
    
    public weak var delegate: MacDocumentTabContainerViewControllerDelegate?
    
    private var openingViewControllers: [URL: DocumentEditorViewController] = [:]
    
    private let tabBar: TabBar = TabBar()
    
    private let container: UIView = UIView()
    
    private let disposeBag = DisposeBag()
    
    private var viewModel: DashboardViewModel!
    
    public convenience init(viewModel: DashboardViewModel) {
        self.init()
        self.viewModel = viewModel
    }
    
    public override func viewDidLoad() {
        self.view.addSubview(self.tabBar)
        self.view.addSubview(self.container)
        
        self.tabBar.sideAnchor(for: [.leading, .top, .traling], to: self.view, edgeInset: 0)
        self.tabBar.sizeAnchor(height: 44)
        
        self.tabBar.columnAnchor(view: self.container, alignment: .none)
        self.container.sideAnchor(for: [.leading, .bottom, .traling], to: self.view, edgeInset: 0, considerSafeArea: true)
        
        self.tabBar.onCloseDocument
            .subscribe(onNext: { [weak self ] url in
                self?.closeDocument(url: url)
                
            }).disposed(by: self.disposeBag)
        
        self.tabBar.onSelectDocument.subscribe(onNext: { [weak self] url in
            if let viewController = self?.openingViewControllers[url], let strongSelf = self {
                strongSelf.container.subviews.forEach { $0.removeFromSuperview() }
                strongSelf.container.addSubview(viewController.view)
                viewController.view.allSidesAnchors(to: strongSelf.container, edgeInset: 0)
            }
        }).disposed(by: self.disposeBag)
    }
    
    public func showDocument(url: URL, viewController: DocumentEditorViewController) {
        self.openingViewControllers[url] = viewController
        self.addChild(viewController)
        
        self.container.addSubview(viewController.view)
        viewController.view.allSidesAnchors(to: self.container, edgeInset: 0)
        
        self.tabBar.openDocument.onNext(url)
    }
    
    public func closeDocument(url: URL) {
        if let viewController = self.openingViewControllers[url] {
            viewController.removeFromParent()
            viewController.view.removeFromSuperview()
            self.openingViewControllers[url] = nil
            
            self.viewModel.dependency.settingAccessor.logCloseDocument(url: url)
        }
    }
}

private class TabBar: UIView {
    let openDocument: PublishSubject<URL> = PublishSubject()
    let onCloseDocument: PublishSubject<URL> = PublishSubject()
    let onSelectDocument: PublishSubject<URL> = PublishSubject()
    
    private var opendDocuments: [URL] = []
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .firstBaseline
        stackView.spacing = 20
        return stackView
    }()
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    convenience init() {
        self.init(frame: .zero)
        self.setup()
    }
    
    private func setup() {
        self.addSubview(self.stackView)
        
        self.stackView.allSidesAnchors(to: self, edgeInset: 0)
        
        self.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        
        self.openDocument.subscribe(onNext: { url in
            let tab = Tab(url: url)
            self.stackView.addArrangedSubview(tab)
            
            tab.onCloseTapped.subscribe(onNext: { [weak tab] url in
                self.onCloseDocument.onNext(url)
                tab?.removeFromSuperview()
            }).disposed(by: self.disposeBag)
            
            tab.onSelect.subscribe(onNext: { url in
                self.onSelectDocument.onNext(url)
            }).disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
    }
}

private class Tab: UIView {
    var url: URL!
    
    let onCloseTapped: PublishSubject<URL> = PublishSubject()
    let onSelect: PublishSubject<URL> = PublishSubject()
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    convenience init(url: URL) {
        self.init(frame: .zero)
        self.url = url
        self.setup()
    }
    
    private func setup() {
        let label = UIButton()
        label.setTitle(self.url.packageName, for: .normal)
        
        let closeButton = UIButton()
        
        closeButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.Assets.cross.image.fill(color: theme.color.interactive), for: .normal)
            label.setTitleColor(theme.color.interactive, for: .normal)
            self.backgroundColor = theme.color.background1
        }
        
        self.addSubview(label)
        self.addSubview(closeButton)
        
        label.sideAnchor(for: [.left, .top, .bottom], to: self, edgeInset: 0)
        label.rowAnchor(view: closeButton, space: 5)
        closeButton.sideAnchor(for: [.top, .bottom, .right], to: self, edgeInset: 5)
        
        label.rx
            .tap
            .map { [unowned self] in self.url }
            .bind(to: onSelect)
            .disposed(by: self.disposeBag)
        
        closeButton.rx
            .tap
            .map { [unowned self] in self.url }
            .bind(to: self.onCloseTapped)
            .disposed(by: self.disposeBag)
    }
}
