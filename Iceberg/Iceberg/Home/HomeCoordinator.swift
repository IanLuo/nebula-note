
//
//  HomeCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import RxSwift

public enum TabIndex: Int {
    case agenda = 0
    case idea = 1
    case search = 2
    case browser = 3
    case kanban = 4
    case editor = 5
    
    var index: Int {
        return self.rawValue
    }
    
    public static var allCases: [TabIndex] {
        return [.agenda, .idea, .search, .browser, .kanban, editor]
    }
}

public class HomeCoordinator: Coordinator {
    private var _dashboardViewController: DashboardViewController!
    
    private var _viewModel: DashboardViewModel!
    
    private let disposeBag = DisposeBag()
    
    public private(set) var tabController: TabContainerViewController!
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        let viewModel = DashboardViewModel(coordinator: self)
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        
        self._viewModel = viewModel
        
        let navigationController = Coordinator.createDefaultNavigationControlller()
        navigationController.pushViewController(dashboardViewController, animated: false)
        
        self._dashboardViewController = dashboardViewController
        
        dashboardViewController.delegate = self
        
        let agendaCoordinator = AgendaCoordinator(stack: self.stack, dependency: self.dependency)
        agendaCoordinator.delegate = self
        self.addPersistentCoordinator(agendaCoordinator)
        
        let kanbanCoordinator = KanbanCoordinator(stack: self.stack, dependency: self.dependency)
        self.addPersistentCoordinator(kanbanCoordinator)
        
        let captureCoordinator = MaterialsCoordinator(stack: self.stack, dependency: self.dependency)
        self.addPersistentCoordinator(captureCoordinator)
        
        let searchCoordinator = SearchCoordinator(stack: self.stack, dependency: self.dependency)
        searchCoordinator.delegate = self
        self.addPersistentCoordinator(searchCoordinator)
        
        let browserCoordinator = BrowserCoordinator(stack: self.stack, dependency: self.dependency, usage: .browseDocument)
        browserCoordinator.delegate = self
        self.addPersistentCoordinator(browserCoordinator)
        
        let tabCoordinator = TabContainerCoordinator(stack: self.stack, dependency: self.dependency)
        tabController = (tabCoordinator.viewController as! TabContainerViewController)
        tabController.delegate = self
        self.addPersistentCoordinator(tabCoordinator)
        
        
        dashboardViewController.addTab(tabs: [DashboardViewController.TabType.agenda(Coordinator.createDefaultNavigationControlller(root: agendaCoordinator.viewController!), TabIndex.agenda.index),
                                              DashboardViewController.TabType.captureList(Coordinator.createDefaultNavigationControlller(root: captureCoordinator.viewController!, hiddenBydefault: true), TabIndex.idea.index),
                                              DashboardViewController.TabType.search(Coordinator.createDefaultNavigationControlller(root: searchCoordinator.viewController!), TabIndex.search.index),
                                              DashboardViewController.TabType.documents(Coordinator.createDefaultNavigationControlller(root: browserCoordinator.viewController!), TabIndex.browser.index),
                                              DashboardViewController.TabType.kanban(Coordinator.createDefaultNavigationControlller(root: kanbanCoordinator.viewController!), TabIndex.kanban.index),
                                              DashboardViewController.TabType.editor(Coordinator.createDefaultNavigationControlller(root: tabCoordinator.viewController!), TabIndex.editor.index),
        ])
        
        if isMacOrPad {
            self.viewController = DesktopHomeViewController(dashboardViewController: dashboardViewController, coordinator: self)
        } else {
            let homeViewController = HomeViewController(masterViewController: navigationController)
            self.viewController = homeViewController
            homeViewController.delegate = self
        }
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: OpenDocumentEvent.self, queue: .main, action: { [weak self] (event: OpenDocumentEvent) -> Void in
            self?.openDocumentFromEvent(event: event)
        })
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: SwitchTabEvent.self, queue: .main, action: { [weak self] (event: SwitchTabEvent) -> Void in
            if let tabIndex = TabIndex(rawValue: event.toTabIndex) {
                self?.selectTab(tabIndex)
            }
        })
    }
    
    deinit {
        self.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public override func didMoveIn() {
        self.dependency.appContext.isFileReadyToAccess.subscribe(onNext: { [weak self] in
            guard $0 else { return }
            
            self?.initializeDefaultTab()
            self?.initializedDefaultOpeningDocuments()
        }).disposed(by: self.disposeBag)
    }
    
    private var tempCoordinator: Coordinator?
    
    public func showTempCoordinator(_ coordinator: Coordinator) {
        // set temp coordinator as child of current coordinator
        coordinator.parent = self
        self.addChild(coordinator)
        self.tempCoordinator = coordinator
        
        if isMacOrPad {
            if let viewController = coordinator.viewController {
                (self.viewController as? DesktopHomeViewController)?.showInMiddlePart(viewController: viewController)
            }
        } else {
            if let homeViewController = self.viewController as? HomeViewController {
                homeViewController.showChildViewController(Coordinator.createDefaultNavigationControlller(root: coordinator.viewController!))
                homeViewController.showDetailView()
            }
        }
    }
    
    public func addPersistentCoordinator(_ coordinator: Coordinator) {
        self.addChild(coordinator)
    }
    
    public func showSettings() {
        let navigationController = Coordinator.createDefaultNavigationControlller(transparentBar: false)
        let settingsCoordinator = SettingsCoordinator(stack: navigationController, dependency: self.dependency)
        settingsCoordinator.start(from: self)
    }
    
    public func showTrash() {
        let navigationController = Coordinator.createDefaultNavigationControlller(transparentBar: false)
        let trashCoordinator = TrashCoordinator(stack: navigationController, dependency: self.dependency)
        trashCoordinator.start(from: self)
    }
    
    public func showMembershipView() {
        let navigationController = Coordinator.createDefaultNavigationControlller(transparentBar: false)
        let membershipCoordinator = MembershipCoordinator(stack: navigationController, dependency: self.dependency)
        membershipCoordinator.start(from: self)
    }
        
    @available(iOS 13.0, *)
    public func isCommandAvailable(command: UICommand) -> Bool {
        return tabController.isCommandAvailable(command: command)
    }
    
    // MARK: - private -
    
    private func initializedDefaultOpeningDocuments() {
        if let opendFiles = self.dependency.settingAccessor.openedDocuments?.filter({ FileManager.default.fileExists(atPath: $0.path) }) {
            for (index, url) in opendFiles.enumerated() {
                self.addOnDesktopContainerTabIfNeeded(url: url, shouldSelect: index == opendFiles.count - 1)
            }
        }
    }
    
    private func initializeDefaultTab() {
        let hasInitedLandingTab: PublishSubject<Void> = PublishSubject<Void>()
        hasInitedLandingTab.onNext(())
        let defaultTabIndex = SettingsAccessor.Item.landingTabIndex.get(Int.self) ?? 3
        
        self.dependency.eventObserver.emit(SwitchTabEvent(toTabIndex: defaultTabIndex))
    }
    
    public func openDocumentFromEvent(event: OpenDocumentEvent) {
        self.addOnDesktopContainerTabIfNeeded(url: event.url, shouldSelect: true)
        self.selectOnDesktopContainerTab(url: event.url, location: event.location)
        
        self.selectTab(TabIndex.editor)
    }
    
    public func selectTab(_ tab: TabIndex) {
        self._dashboardViewController.selectOnTab(index: tab.index)
    }
}

extension HomeCoordinator: SearchCoordinatorDelegate {
    public func didSelectDocument(url: URL, location: Int, searchCoordinator: SearchCoordinator) {
        self.openDocument(url: url, location: location)
    }
    
    public func didCancelSearching() {
        
    }
}

extension HomeCoordinator: AgendaCoordinatorDelegate {
    public func didSelectDocument(url: URL, location: Int) {
        self.openDocument(url: url, location: location)
    }
}

extension HomeCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL, coordinator: BrowserCoordinator) {
        self.openDocument(url: url, location: 0)
    }
    
    public func didSelectOutline(documentInfo: DocumentInfo, selection: OutlineLocation, coordinator: BrowserCoordinator) {}
    
    public func didCancel(coordinator: BrowserCoordinator) {}
}

extension HomeCoordinator: HomeViewControllerDelegate {
    public func didShowMasterView() {
        
    }
    
    public func didShowDetailView() {
    }
}

extension HomeCoordinator: DashboardViewControllerDelegate {
    public func toggleFullScreen() {
        let macHomeViewController = (self.viewController as? DesktopHomeViewController)
        
        let isFull = self.dependency.globalCaptureEntryWindow?.isInFullScreenEditor.value == true
        
        macHomeViewController?.toogleToolBar(visiable: !isFull)
        
        if macHomeViewController?.isLeftPartVisiable == true {
            macHomeViewController?.toggleLeftPartVisiability(visiable: false)
        }
    }
    
    public func toggleLeftPart() {
        if let desktopViewController = self.viewController as? DesktopHomeViewController {
            desktopViewController.toggleLeftPartVisiability(visiable: !desktopViewController.isLeftPartVisiable, animated: true)
        }
    }
    
    public func showHeadings(tag: String) {
    }
    
    public func showHeadings(planning: String) {
    }
        
    public func didSelectTab(at index: Int, viewController: UIViewController) {
        // if last showing temp view controller, remove from children
        if let tempCoordinator = self.tempCoordinator {
            self.remove(tempCoordinator)
            self.tempCoordinator = nil
        }
        
        if isMacOrPad {
            if let desktopHomeViewController = self.viewController as? DesktopHomeViewController {
                desktopHomeViewController.showInMiddlePart(viewController: viewController)
                desktopHomeViewController.updateSelectedTabIndex.onNext(index)
            }
        } else {
            if let homeViewController = self.viewController as? HomeViewController {
                homeViewController.showChildViewController(viewController)
                homeViewController.showDetailView()
            }
        }
    }
}

extension HomeCoordinator {
    public func selectOnDesktopContainerTab(url: URL, location: Int) {
        self.tabController.selectTab(url: url, location: location)
    }
    
    public func addOnDesktopContainerTabIfNeeded(url: URL, shouldSelect: Bool) {
        
        if self.tabController.isFileOpened(url: url) == false {
            let stack = Coordinator.createDefaultNavigationControlller()
            let editorCoordinator = EditorCoordinator(stack: stack, dependency: self.dependency, usage: .editor(url, 0))
            
            self.tabController.addTabs(editorCoordinator: editorCoordinator, shouldSelected: shouldSelect)
            self.addChild(editorCoordinator)
        } else {
            self.tabController.selectTab(url: url, location: 0)
        }
    }
}

extension HomeCoordinator: TabContainerViewControllerDelegate {
    public func didTapOnOpenDocument() {
        self.dependency.eventObserver.emit(SwitchTabEvent(toTabIndex: TabIndex.browser.index))
    }
    
    public func didCloseDocument(url: URL, editorViewController: DocumentEditorViewController) {
        self.children.forEach {
            if let editor = $0 as? EditorCoordinator {
                switch editor.usage {
                case .editor(let _url, _):
                    if url == _url {
                        self.remove(editor)
                    }
                default: break
                }
            }
        }
    }
}
