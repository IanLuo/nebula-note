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
            .subscribe(onNext: { [weak self ] tab in
                self?.closeDocument(url: tab.url)
                self?.viewModel.dependency.settingAccessor.logCloseDocument(url: tab.url)
                
                // if the closed document is currently openning, open another one
                if try! tab.isSelected.value() {
                    if let nextUrl = self?.openingViewControllers.keys.first, let viewController = self?.openingViewControllers[nextUrl] {
                        self?.showDocument(url: nextUrl, viewController: viewController)
                    }
                }
            }).disposed(by: self.disposeBag)
        
        self.tabBar.onSelectDocument.subscribe(onNext: { [weak self] url in
            if let viewController = self?.openingViewControllers[url], let strongSelf = self {
                strongSelf.container.subviews.forEach { $0.removeFromSuperview() }
                strongSelf.container.addSubview(viewController.view)
                viewController.view.allSidesAnchors(to: strongSelf.container, edgeInset: 0)
            }
        }).disposed(by: self.disposeBag)
        
        self.interface { (me, theme) in
            me.view.backgroundColor = theme.color.background1
        }
    }
    
    public func isDocumentOpened(url: URL) -> Bool {
        return self.openingViewControllers[url] != nil
    }
    
    public func showDocument(url: URL, viewController: DocumentEditorViewController?, location: Int? = nil) {
        self.viewModel.dependency.settingAccessor.logOpenDocument(url: url)
        
        self.tabBar.openDocument.onNext(url)
        
        if let viewController = self.openingViewControllers[url] {
            self.container.subviews.forEach { $0.removeFromSuperview() }
            self.container.addSubview(viewController.view)
            viewController.view.allSidesAnchors(to: self.container, edgeInset: 0)
            if let location = location {
                viewController._scrollTo(location: location)
            }
        } else if let viewController = viewController {
            self.openingViewControllers[url] = viewController
            self.container.addSubview(viewController.view)
            viewController.view.allSidesAnchors(to: self.container, edgeInset: 0)
            self.addChild(viewController)
        }
    }
    
    public func closeDocument(url: URL) {
        if let viewController = self.openingViewControllers[url] {
            viewController.removeFromParent()
            viewController.view.removeFromSuperview()
            self.openingViewControllers[url] = nil
            self.delegate?.didCloseDocument(url: url, editorViewController: viewController)
            self.viewModel.dependency.settingAccessor.logCloseDocument(url: url)
        }
    }
}

private class TabBar: UIScrollView {
    let openDocument: PublishSubject<URL> = PublishSubject()
    let onCloseDocument: PublishSubject<Tab> = PublishSubject()
    let onSelectDocument: PublishSubject<URL> = PublishSubject()
    
    private var opendDocuments: [URL] = []
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 5
        return stackView
    }()
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    convenience init() {
        self.init(frame: .zero)
        self.setup()
    }
    
    private func setup() {
        self.addSubview(self.stackView)
        
        self.contentInset = UIEdgeInsets(top: 0, left: Layout.innerViewEdgeInsets.left, bottom: 0, right: Layout.innerViewEdgeInsets.right)
        
        self.stackView.sideAnchor(for: [.left, .top, .bottom], to: self, edgeInset: 0)
        self.stackView.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor).isActive = true
        
        self.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        
        self.openDocument.subscribe(onNext: { [weak self] url in
            guard let strongSelf = self else { return }
            
            var didFoundPresentingTab: Bool = false
            strongSelf.stackView.arrangedSubviews.forEach {
                if let tab = $0 as? Tab {
                    if  tab.url == url {
                        tab.isSelected.onNext(true)
                        didFoundPresentingTab = true
                    } else {
                        tab.isSelected.onNext(false)
                    }
                }
            }
            
            if !didFoundPresentingTab {
                let tab = Tab(url: url)
                tab.isSelected.onNext(true)
                strongSelf.stackView.addArrangedSubview(tab)
                tab.sizeAnchor(height: 44)
                
                tab.onCloseTapped.subscribe(onNext: { [weak tab] url in
                    guard let tab = tab else { return }
                    strongSelf.onCloseDocument.onNext(tab)
                    tab.removeFromSuperview()
                }).disposed(by: strongSelf.disposeBag)
                
                tab.onSelect.subscribe(onNext: { url in
                    strongSelf.onSelectDocument.onNext(url)
                    
                    strongSelf.stackView.arrangedSubviews.forEach {
                        if let tab = $0 as? Tab {
                            if  tab.url == url {
                                tab.isSelected.onNext(true)
                            } else {
                                tab.isSelected.onNext(false)
                            }
                        }
                    }
                }).disposed(by: strongSelf.disposeBag)
            }
            
        }).disposed(by: self.disposeBag)
    }
    
}

private class Tab: UIView {
    var url: URL!
    
    let onCloseTapped: PublishSubject<URL> = PublishSubject()
    let onSelect: PublishSubject<URL> = PublishSubject()
    let isSelected: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    
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
            button.setImage(Asset.Assets.cross.image.fill(color: theme.color.interactive).resize(upto: CGSize(width: 10, height: 10)), for: .normal)
            label.setTitleColor(theme.color.interactive, for: .normal)
            label.titleLabel?.font = theme.font.footnote
            self.backgroundColor = theme.color.background2
        }
        
        self.addSubview(label)
        self.addSubview(closeButton)
        
        label.sideAnchor(for: [.left, .top, .bottom], to: self, edgeInsets: .init(top: 0, left: 15, bottom: 0, right: 0))
        label.rowAnchor(view: closeButton, space: 5)
        closeButton.sideAnchor(for: [.top, .bottom, .right], to: self, edgeInsets: .init(top: 0, left: 25, bottom: 0, right: -15))
        
        label.rx
            .tap
            .map { self.url }
            .bind(to: onSelect)
            .disposed(by: self.disposeBag)
        
        closeButton.rx
            .tap
            .map { [unowned self] in self.url }
            .bind(to: self.onCloseTapped)
            .disposed(by: self.disposeBag)
        
        isSelected.subscribe(onNext: { [weak self] isSelected in
            self?.backgroundColor = isSelected ? InterfaceTheme.Color.spotlight : InterfaceTheme.Color.background2
            label.setTitleColor(isSelected ? InterfaceTheme.Color.spotlitTitle : InterfaceTheme.Color.interactive, for: .normal)
        }).disposed(by: self.disposeBag)
    }
}
