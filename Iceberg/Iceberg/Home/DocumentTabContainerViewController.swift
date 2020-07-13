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

public protocol DesktopDocumentTabContainerViewControllerDelegate: class {
    func didCloseDocument(url: URL, editorViewController: DocumentEditorViewController)
}

public class DocumentTabContainerViewController: UIViewController {
    
    public weak var delegate: DesktopDocumentTabContainerViewControllerDelegate?
    
    private var openingViewControllers: [String: DocumentEditorViewController] = [:]
    
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
        
        self.tabBar.sizeAnchor(height: 54)
        
        self.tabBar.columnAnchor(view: self.container, alignment: .none)
        self.container.sideAnchor(for: [.leading, .bottom, .traling], to: self.view, edgeInset: 0, considerSafeArea: true)
        
        self.tabBar.onCloseDocument
            .subscribe(onNext: { [weak self ] tab in
                self?.closeDocument(url: tab.url)
                self?.viewModel.dependency.settingAccessor.logCloseDocument(url: tab.url)
                
                // if the closed document is currently openning, open another one
                if try! tab.isSelected.value() {
                    if let documentRelativePath = self?.openingViewControllers.keys.first {
                        self?.selectTab(url: URL(documentRelativePath: documentRelativePath), location: 0)
                    }
                }
            }).disposed(by: self.disposeBag)
        
        self.tabBar.onSelectDocument.subscribe(onNext: { [weak self] url in
            self?.selectTab(url: url, location: 0)
        }).disposed(by: self.disposeBag)
        
        self.interface { (me, theme) in
            me.view.backgroundColor = theme.color.background1
        }
    }
    
    public func isDocumentAdded(url: URL) -> Bool {
        return self.openingViewControllers[url.documentRelativePath] != nil
    }
    
    public func selectTab(url: URL, location: Int) {
        self.viewModel.dependency.settingAccessor.logOpenDocument(url: url)
        
        if let viewController = self.openingViewControllers[url.documentRelativePath] {
            
            if !self.container.subviews.contains(where: { $0 == viewController.view}) {
                self.container.subviews.forEach { $0.removeFromSuperview() }
                self.container.addSubview(viewController.view)
                viewController.view.allSidesAnchors(to: self.container, edgeInset: 0)
                
                self.tabBar.selectDocument.onNext(url)
                
                // load content
                viewController.start()
            }
            
            if location > 0 {
                viewController.scrollTo(location: location)
            }
        }
    }
    
    public func addTabs(editorCoordinator: EditorCoordinator, shouldSelected: Bool) {
        let documentRelativePath = editorCoordinator.url.documentRelativePath
        if self.openingViewControllers[documentRelativePath] == nil, let viewController = editorCoordinator.viewController as? DocumentEditorViewController {
            self.openingViewControllers[documentRelativePath] = viewController
            
            self.tabBar.addDocument.onNext((editorCoordinator.url, shouldSelected))
        }
        
        if shouldSelected {
            self.selectTab(url: editorCoordinator.url, location: 0)
        }
    }
    
    public func closeDocument(url: URL) {
        if let viewController = self.openingViewControllers[url.documentRelativePath] {
            viewController.removeFromParent()
            viewController.view.removeFromSuperview()
            self.openingViewControllers[url.documentRelativePath] = nil
            self.delegate?.didCloseDocument(url: url, editorViewController: viewController)
            self.viewModel.dependency.settingAccessor.logCloseDocument(url: url)
        }
    }
}

private class TabBar: UIScrollView {
    let addDocument: PublishSubject<(URL, Bool)> = PublishSubject()
    let selectDocument: PublishSubject<URL> = PublishSubject()
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
        
        self.stackView.sideAnchor(for: [.left, .top, .bottom], to: self, edgeInsets: .init(top: 0, left: 0, bottom: -10, right: 0))
        self.stackView.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor).isActive = true
        
        self.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        
        self.selectDocument.subscribe(onNext: { [weak self] url in
            guard let strongSelf = self else { return }
            
            strongSelf.stackView.arrangedSubviews.forEach {
                if let tab = $0 as? Tab {
                    if (try? tab.isSelected.value()) == false, tab.url.isSameDocument(another: url) {
                        tab.isSelected.onNext(true)
                        strongSelf.srollToIfNeeded(tab: tab)
                    } else if (try? tab.isSelected.value()) == true, !tab.url.isSameDocument(another: url) {
                        tab.isSelected.onNext(false)
                    }
                }
            }
            
        }).disposed(by: self.disposeBag)
        
        self.addDocument.subscribe(onNext: { [weak self] url, shouldSelect in
            guard let strongSelf = self else { return }
            
            var tab: Tab?
            strongSelf.stackView.arrangedSubviews.forEach {
                if let _tab = $0 as? Tab, _tab.url.isSameDocument(another: url) {
                    tab = _tab
                    return
                }
            }

            guard (try? tab?.isSelected.value()) != true else { return }
            
            let newTab = Tab(url: url)
            newTab.isSelected.onNext(shouldSelect)
            strongSelf.stackView.insertArrangedSubview(newTab, at: 0)
            newTab.sizeAnchor(height: 44)
            
            newTab.onCloseTapped.subscribe(onNext: { [weak newTab] url in
                guard let newTab = newTab else { return }
                strongSelf.onCloseDocument.onNext(newTab)
                newTab.removeFromSuperview()
            }).disposed(by: strongSelf.disposeBag)
            
            newTab.onSelect.subscribe(onNext: { url in
                strongSelf.onSelectDocument.onNext(url)
                
                strongSelf.stackView.arrangedSubviews.forEach {
                    if let tab = $0 as? Tab {
                        if  tab.url.isSameDocument(another: url) {
                            tab.isSelected.onNext(true)
                        } else {
                            tab.isSelected.onNext(false)
                        }
                    }
                }
            }).disposed(by: strongSelf.disposeBag)
            
        }).disposed(by: self.disposeBag)
    }
    
    private func srollToIfNeeded(tab: Tab) {
        let frame = self.stackView.convert(tab.frame, to: self)
        self.scrollRectToVisibleIfneeded(frame, animated: true)
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
        self.roundConer(radius: 4)
        
        let titleButton = UIButton()
        titleButton.setTitle(self.url.packageName, for: .normal)
        
        titleButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setTitleColor(theme.color.interactive, for: .normal)
            button.titleLabel?.font = theme.font.footnote
        }
        
        let closeButton = UIButton()
        closeButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.Assets.cross.image.fill(color: theme.color.interactive).resize(upto: CGSize(width: 10, height: 10)), for: .normal)
            button.setTitleColor(theme.color.interactive, for: .normal)
            self.backgroundColor = theme.color.background2
        }
        
        self.addSubview(titleButton)
        self.addSubview(closeButton)
        
        titleButton.sideAnchor(for: [.left, .top, .bottom], to: self, edgeInsets: .init(top: 0, left: 15, bottom: 0, right: 0))
        titleButton.rowAnchor(view: closeButton, space: 16)
        closeButton.sideAnchor(for: [.top, .bottom, .right], to: self, edgeInsets: .init(top: 0, left: 25, bottom: 0, right: -5))
        closeButton.sizeAnchor(width: 30, height: 30)
        
        titleButton.rx
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
            titleButton.setTitleColor(isSelected ? InterfaceTheme.Color.spotlitTitle : InterfaceTheme.Color.interactive, for: .normal)
            closeButton.setImage(Asset.Assets.cross.image.fill(color: isSelected ? InterfaceTheme.Color.spotlitTitle : InterfaceTheme.Color.interactive).resize(upto: CGSize(width: 10, height: 10)), for: .normal)
        }).disposed(by: self.disposeBag)
    }
}
