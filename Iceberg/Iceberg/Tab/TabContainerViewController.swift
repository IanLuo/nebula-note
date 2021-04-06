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
import RxCocoa

public protocol TabContainerViewControllerDelegate: class {
    func didCloseDocument(url: URL, editorViewController: DocumentEditorViewController)
    func didTapOnOpenDocument()
}

public class TabContainerViewController: UIViewController {
    
    public weak var delegate: TabContainerViewControllerDelegate?
    
    private var openingViewControllers: [(String, DocumentEditorViewController)] = []
    
    private let tabBar: TabBar = TabBar()
    
    private let barContainer: UIView = UIView()
    
    private let container: UIView = UIView()
    
    private let disposeBag = DisposeBag()
    
    private var viewModel: TabContainerViewModel!
    
    private let openDocumentButton: UIButton = UIButton()
    
    public var currentEditorViewController: DocumentEditorViewController?
    
    public convenience init(viewModel: TabContainerViewModel) {
        self.init()
        self.viewModel = viewModel
        self.title = TabIndex.editor.name
        self.tabBarItem.image = TabIndex.editor.icon
    }
    
    public override func viewDidLoad() {
        self.setupUI()
        self.setupObservers()
    }
    
    private func setupUI() {
        self.navigationController?.isNavigationBarHidden = true
        
        self.view.addSubview(self.barContainer)
        self.view.addSubview(self.container)
        
        self.barContainer.addSubview(self.tabBar)
        self.barContainer.addSubview(self.openDocumentButton)
        
        self.openDocumentButton.roundConer(radius: Layout.cornerRadius)
        self.openDocumentButton.sizeAnchor(width: 44, height: 44)
        self.openDocumentButton.sideAnchor(for: [.leading], to: self.barContainer, edgeInsets: UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: 0))
        self.openDocumentButton.rowAnchor(view: self.tabBar, space: 10, alignment: .top)
        self.tabBar.sideAnchor(for: [.top, .traling, .bottom], to: self.barContainer, edgeInset: 0)
        
        self.tabBar.sizeAnchor(height: 54)
        
        self.barContainer.sideAnchor(for: [.leading, .top, .traling], to: self.view, edgeInset: 0, considerSafeArea: true)
        self.barContainer.columnAnchor(view: self.container, space: 0, alignment: .none)
        self.container.sideAnchor(for: [.leading, .bottom, .traling], to: self.view, edgeInset: 0, considerSafeArea: true)
        
        self.interface { [weak self] (me, theme) in
            self?.openDocumentButton.setImage(Asset.SFSymbols.plus.image.fill(color: theme.color.spotlight), for: .normal)
            self?.openDocumentButton.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            me.view.backgroundColor = theme.color.background1
        }
    }
    
    private func setupObservers() {
        self.openDocumentButton.rx.tap.subscribe(onNext: { [weak self] _ in self?.delegate?.didTapOnOpenDocument() }).disposed(by: self.disposeBag)
        
        self.tabBar.onCloseDocument
            .subscribe(onNext: { [weak self ] tab in
                let index = self?.index(for: tab.url) ?? 0
                self?.closeDocument(url: tab.url)
                
                // if the closed document is currently openning, open another one
                if tab.isSelected.value {
                    if self?.openingViewControllers.count == 1 || index == 0 {
                        if let documentRelativePath = self?.openingViewControllers.first?.0 {
                            self?.selectTab(url: URL(documentRelativePath: documentRelativePath), location: 0)
                        }
                    } else if index - 1 > 0 {
                        if let documentRelativePath = self?.openingViewControllers[index - 1].0 {
                            self?.selectTab(url: URL(documentRelativePath: documentRelativePath), location: 0)
                        }
                    }
                    
                }
            }).disposed(by: self.disposeBag)
        
        self.tabBar.onSelectDocument.subscribe(onNext: { [weak self] url in
            self?.selectTab(url: url, location: 0)
        }).disposed(by: self.disposeBag)
        
        self.viewModel.context.dependency.eventObserver.registerForEvent(on: self, eventType: RenameDocumentEvent.self, queue: .main) { (event: RenameDocumentEvent) -> Void in
            if let controller = self.viewController(for: event.oldUrl) {
                self.tabBar.renameTab(with: event.oldUrl, to: event.newUrl)
                self.addPair(for: event.newUrl, viewController: controller)
                self.removePair(for: event.oldUrl)
                self.viewModel.context.dependency.settingAccessor.logCloseDocument(url: event.oldUrl)
                self.viewModel.context.dependency.settingAccessor.logOpenDocument(url: event.newUrl)
            }
        }
        
        self.viewModel.context.dependency.eventObserver.registerForEvent(on: self, eventType: DeleteDocumentEvent.self, queue: .main) { (event: DeleteDocumentEvent) -> Void in
            self.closeDocument(url: event.url)
            self.tabBar.removeTab(with: event.url)
        }
    }
    
    deinit {
        self.viewModel.context.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public func isDocumentAdded(url: URL) -> Bool {
        return self.viewController(for: url) != nil
    }
    
    public var isTabbarHidden: Bool {
        return self.barContainer.constraint(for: .top)?.constant != 0
    }
    
    public func hideTabbar(_ isHidden: Bool) {
        self.barContainer.constraint(for: .top)?.constant = isHidden ? -54 : 0
        
        UIView.animate(withDuration: 0.25) {
            self.barContainer.alpha = isHidden ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }
    
    @available(iOS 13.0, *)
    public func isCommandAvailable(command: UICommand) -> Bool {
        guard let properties = command.propertyList as? [String: Any] else { return false }
        
        if (properties["is-global"] as? Bool) == true {
            return true
        }
        
        guard let currentEditor = self.currentEditorViewController else { return false }
        guard currentEditor.textView.isFirstResponder == true else { return false }
        
        return currentEditor.inputbar.isActionAvailable(commandTitle: properties["title"] as? String ?? "")
    }
    
    public func selectTab(url: URL, location: Int) {
        self.viewModel.dependency.settingAccessor.logOpenDocument(url: url)
        
        if let viewController = self.viewController(for: url) {
            
            if !self.container.subviews.contains(where: { $0 == viewController.view}) {
                self.container.subviews.forEach { $0.removeFromSuperview() }
                self.container.addSubview(viewController.view)
                self.addChild(viewController)
                viewController.tabContainer = self
                viewController.view.allSidesAnchors(to: self.container, edgeInset: 0)
                
                // load content
                viewController.start(location)
                
                self.currentEditorViewController = viewController                
            } else {
                if location > 0 {
                    viewController.scrollTo(location: location)
                }
            }
            
            self.tabBar.selectDocument.onNext(url)
        }
    }
    
    public func addTabs(editorCoordinator: EditorCoordinator, shouldSelected: Bool) {
        if self.viewController(for: editorCoordinator.url) == nil, let viewController = editorCoordinator.viewController as? DocumentEditorViewController {
            self.addPair(for: editorCoordinator.url, viewController: viewController)
            
            self.tabBar.addDocument.onNext((editorCoordinator.url, shouldSelected))
        }
        
        if shouldSelected {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                self.selectTab(url: editorCoordinator.url, location: 0)
            }
        }
    }
    
    public func closeDocument(url: URL) {
        if let viewController = self.viewController(for: url) {
            viewController.removeFromParent()
            viewController.view.removeFromSuperview()
            self.removePair(for: url)
            self.delegate?.didCloseDocument(url: url, editorViewController: viewController)
            self.viewModel.dependency.settingAccessor.logCloseDocument(url: url)
        }
    }
    
    private func index(for url: URL) -> Int? {
        for (index, pair) in self.openingViewControllers.enumerated() {
            if pair.0 == url.documentRelativePath {
                return index
            }
        }
        return nil
    }
    
    private func viewController(for url: URL) -> DocumentEditorViewController? {
        for pair in self.openingViewControllers {
            if pair.0 == url.documentRelativePath {
                return pair.1
            }
        }
        return nil
    }
    
    private func removePair(for url: URL) {
        for (index, pair) in self.openingViewControllers.enumerated() {
            if pair.0 == url.documentRelativePath {
                self.openingViewControllers.remove(at: index)
            }
        }
    }
    
    private func addPair(for url: URL, viewController: DocumentEditorViewController) {
        self.openingViewControllers.insert((url.documentRelativePath, viewController), at: 0)
    }
    
    public override func resignFirstResponder() -> Bool {
        return self.currentEditorViewController?.resignFirstResponder() ?? false
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
    
    func renameTab(with url: URL, to anotherUrl: URL) {
        self.stackView.arrangedSubviews.forEach { tab in
            if let tab = tab as? Tab, tab.url.documentRelativePath == url.documentRelativePath {
                tab.replaceUrl(to: anotherUrl)
            }
        }
    }
    
    func removeTab(with url: URL) {
        self.stackView.arrangedSubviews.forEach { tab in
            if let tab = tab as? Tab, tab.url.documentRelativePath == url.documentRelativePath {
                tab.removeFromSuperview()
            }
        }
    }
    
    private func setup() {
        self.addSubview(self.stackView)
        
        self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: Layout.innerViewEdgeInsets.right)
        
        self.stackView.sideAnchor(for: [.left, .top, .bottom], to: self, edgeInsets: .init(top: 0, left: 0, bottom: -10, right: 0))
        self.stackView.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor).isActive = true
        
        self.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        
        self.selectDocument.subscribe(onNext: { [weak self] url in
            guard let strongSelf = self else { return }
            
            strongSelf.stackView.arrangedSubviews.forEach {
                if let tab = $0 as? Tab {
                    if tab.isSelected.value == false, tab.url.isSameDocument(another: url) {
                        tab.isSelected.accept(true)
                        strongSelf.srollToIfNeeded(tab: tab)
                    } else if tab.isSelected.value == true, !tab.url.isSameDocument(another: url) {
                        tab.isSelected.accept(false)
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

            guard tab?.isSelected.value != true else { return }
            
            let newTab = Tab(url: url)
            newTab.isSelected.accept(shouldSelect)
            strongSelf.stackView.insertArrangedSubview(newTab, at: 0)
            newTab.sizeAnchor(height: 44)
            newTab.widthAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true
        
            strongSelf.setContentOffset(.zero, animated: false)
            
            newTab.onCloseTapped.subscribe(onNext: { [weak newTab] url in
                guard let newTab = newTab else { return }
                strongSelf.onCloseDocument.onNext(newTab)
                newTab.removeFromSuperview()
            }).disposed(by: strongSelf.disposeBag)
            
            newTab.onCloseOthersTapped.subscribe(onNext: { [weak newTab] url in
                guard let newTab = newTab else { return }
                
                self?.stackView.arrangedSubviews.forEach({ view in
                    if let tab = view as? Tab, tab.url.documentRelativePath != newTab.url.documentRelativePath {
                        self?.onCloseDocument.onNext(tab)
                        tab.removeFromSuperview()
                    }
                })
                
                self?.onSelectDocument.onNext(newTab.url)
            }).disposed(by: strongSelf.disposeBag)
            
            newTab.onSelect.subscribe(onNext: { url in
                strongSelf.onSelectDocument.onNext(url)
                
                strongSelf.stackView.arrangedSubviews.forEach {
                    if let tab = $0 as? Tab {
                        if  tab.url.isSameDocument(another: url) {
                            tab.isSelected.accept(true)
                        } else {
                            tab.isSelected.accept(false)
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
    let isSelected: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    let titleButton = UIButton()
    
    let onCloseOthersTapped: PublishSubject<URL> = PublishSubject()
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    convenience init(url: URL) {
        self.init(frame: .zero)
        self.url = url
        self.setup()
        
        self.enableHover(on: self, hoverColor: InterfaceTheme.Color.spotlight.withAlphaComponent(0.7))
    }
    
    func replaceUrl(to newUrl: URL) {
        self.url = newUrl
        titleButton.setTitle(self.url.packageName, for: .normal)
    }
    
    private func setup() {
        self.roundConer(radius: 4, corners: [CACornerMask.layerMinXMinYCorner, CACornerMask.layerMaxXMinYCorner])
        
        
        titleButton.setTitle(self.url.packageName, for: .normal)
        
        titleButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setTitleColor(theme.color.interactive, for: .normal)
            button.titleLabel?.font = theme.font.footnote
        }
        
        let closeButton = UIButton()
        closeButton.interface { (me, theme) in
            let button = me as! UIButton
            button.setImage(Asset.SFSymbols.xmark.image.fill(color: theme.color.interactive).resize(upto: CGSize(width: 10, height: 10)), for: .normal)
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
            self?.titleButton.setTitleColor(isSelected ? InterfaceTheme.Color.spotlitTitle : InterfaceTheme.Color.interactive, for: .normal)
            closeButton.setImage(Asset.SFSymbols.xmark.image.fill(color: isSelected ? InterfaceTheme.Color.spotlitTitle : InterfaceTheme.Color.interactive).resize(upto: CGSize(width: 10, height: 10)), for: .normal)
        }).disposed(by: self.disposeBag)
        
        
        if #available(iOS 13, *) {
            self.addContextualMenu()
        }
    }
    
    @available(iOS 13, *)
    private func addContextualMenu() {
        let interaction = UIContextMenuInteraction(delegate: self)
        self.addInteraction(interaction)
    }
}

@available(iOS 13, *)
extension Tab: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: { sugestedAction in
                                            let closeTab = UIAction(title: L10n.Browser.Tab.close, image: nil,
                                                                    identifier: nil) { action in
                                                if let url = self.url {
                                                    self.onCloseTapped.onNext(url)
                                                }
                                            }
                                            
                                            let closeOtherTabs = UIAction(title: L10n.Browser.Tab.closeOthers) { action in
                                                if let url = self.url {
                                                    self.onCloseOthersTapped.onNext(url)
                                                }
                                            }
                                            
                                            return UIMenu(title: "", children: [closeTab, closeOtherTabs])
                                          })
    }
}
