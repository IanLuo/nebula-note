
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

public class HomeCoordinator: Coordinator {
    private var _dashboardViewController: DashboardViewController!
    
    private var _viewModel: DashboardViewModel!
    
    private let disposeBag = DisposeBag()
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        let viewModel = DashboardViewModel(coordinator: self)
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        
        self._viewModel = viewModel
        
        let navigationController = Coordinator.createDefaultNavigationControlller()
        navigationController.pushViewController(dashboardViewController, animated: false)
        
        self._dashboardViewController = dashboardViewController
        
        viewModel.coordinator = self
        dashboardViewController.delegate = self
        
        let agendaCoordinator = AgendaCoordinator(stack: self.stack, dependency: self.dependency)
        agendaCoordinator.delegate = self
        self.addPersistentCoordinator(agendaCoordinator)
        
        let captureCoordinator = CaptureListCoordinator(stack: self.stack, dependency: self.dependency, mode: CaptureListViewModel.Mode.manage)
        self.addPersistentCoordinator(captureCoordinator)
        
        let searchCoordinator = SearchCoordinator(stack: self.stack, dependency: self.dependency)
        searchCoordinator.delegate = self
        self.addPersistentCoordinator(searchCoordinator)
        
        let browserCoordinator = BrowserCoordinator(stack: self.stack, dependency: self.dependency, usage: .browseDocument)
        browserCoordinator.delegate = self
        self.addPersistentCoordinator(browserCoordinator)
        
        let tabs = [Coordinator.createDefaultNavigationControlller(root: agendaCoordinator.viewController!),
                    Coordinator.createDefaultNavigationControlller(root: captureCoordinator.viewController!),
                    Coordinator.createDefaultNavigationControlller(root: searchCoordinator.viewController!),
                    Coordinator.createDefaultNavigationControlller(root: browserCoordinator.viewController!)]
        
        dashboardViewController.addTab(tabs: [DashboardViewController.TabType.agenda(tabs[0], 0),
                                              DashboardViewController.TabType.captureList(tabs[1], 1),
                                              DashboardViewController.TabType.search(tabs[2], 2),
                                              DashboardViewController.TabType.documents(tabs[3], 3)])
        
        if isMacOrPad {
            self.viewController = DesktopHomeViewController(dashboardViewController: dashboardViewController, coordinator: self, documentTabsContainerViewController: DocumentTabContainerViewController(viewModel: viewModel))
        } else {
            let homeViewController = HomeViewController(masterViewController: navigationController)
            self.viewController = homeViewController
            homeViewController.delegate = self
        }
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: OpenDocumentEvent.self, queue: .main, action: { [weak self] (event: OpenDocumentEvent) -> Void in
            self?.openDocumentFromEvent(event: event)
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
    
    public func getAllTags() -> [String] {
        return self._viewModel.allTags
    }
    
    public func isCommandAvailable(command: UICommand) -> Bool {
        guard let desktopHome = self.viewController as? DesktopHomeViewController else { return false }
        
        return desktopHome.isCommandAvailable(command: command)
    }
    
    // MARK: - private -
    
    private func initializedDefaultOpeningDocuments() {
        if let opendFiles = self.dependency.settingAccessor.openedDocuments?.filter({ FileManager.default.fileExists(atPath: $0.path) }) {
            if isMacOrPad {
                for (index, url) in opendFiles.enumerated() {
                    self.addOnDesktopContainerTabIfNeeded(url: url, shouldSelect: index == opendFiles.count - 1)
                }
            } else {
                //                    if let first = opendFiles.first, FileManager.default.fileExists(atPath: first.path) {
                //                        self?.topCoordinator?.openDocument(url: first, location: 0)
                //                    }
            }
        }
    }
    
    private func initializeDefaultTab() {
        let hasInitedLandingTab: PublishSubject<Void> = PublishSubject<Void>()
        
        self.dependency.appContext.isFileReadyToAccess.takeUntil(hasInitedLandingTab).subscribe(onNext: { [weak self] in
            guard $0 else { return }
            
            hasInitedLandingTab.onNext(())
            
            let defaultTabIndex = SettingsAccessor.Item.landingTabIndex.get(Int.self) ?? 3
            self?.selectTab(at: defaultTabIndex)
        }).disposed(by: self.disposeBag)
    }
    
    public func openDocumentFromEvent(event: OpenDocumentEvent) {
        self.addOnDesktopContainerTabIfNeeded(url: event.url, shouldSelect: true)
        self.selectOnDesktopContainerTab(url: event.url, location: 0)
    }
    
    public func selectTab(at index: Int) {
        self._dashboardViewController.selectOnTab(index: index)
    }
}

extension HomeCoordinator: SearchCoordinatorDelegate {
    public func didSelectDocument(url: URL, location: Int, searchCoordinator: SearchCoordinator) {
        if isMacOrPad {
            self.addOnDesktopContainerTabIfNeeded(url: url, shouldSelect: true)
            self.selectOnDesktopContainerTab(url: url, location: location)
        } else {
            self.openDocument(url: url, location: location)
            
        }
    }
    
    public func didCancelSearching() {
        
    }
}

extension HomeCoordinator: AgendaCoordinatorDelegate {
    public func didSelectDocument(url: URL, location: Int) {
        if isMacOrPad {
            self.addOnDesktopContainerTabIfNeeded(url: url, shouldSelect: true)
            self.selectOnDesktopContainerTab(url: url, location: location)
        } else {
            self.openDocument(url: url, location: location)
        }
    }
}

extension HomeCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL, coordinator: BrowserCoordinator) {
        if isMacOrPad {
            self.addOnDesktopContainerTabIfNeeded(url: url, shouldSelect: true)
            self.selectOnDesktopContainerTab(url: url, location: 0)
        } else {
            self.openDocument(url: url, location: 0)
        }
    }
    
    public func didSelectOutline(url: URL, selection: OutlineLocation, coordinator: BrowserCoordinator) {}
    
    public func didCancel(coordinator: BrowserCoordinator) {}
}

extension HomeCoordinator: HomeViewControllerDelegate {
    public func didShowMasterView() {
        self._dashboardViewController.reloadDataIfNeeded()
    }
    
    public func didShowDetailView() {
    }
}

extension HomeCoordinator: DashboardViewControllerDelegate {
    public func showHeadings(subTabType: DashboardViewModel.DahsboardItemData) {
        var filterType: AgendaCoordinator.FilterType?
        
        switch subTabType {
        case .scheduled(let headings):
            filterType = .scheduled(headings)
        case .overdue(let headings):
            filterType = .overdue(headings)
        case .startSoon(let headings):
            filterType = .startSoon(headings)
        case .overdueSoon(let headings):
            filterType = .overdue(headings)
        case .today(let headings):
            filterType = .today(headings)
        default: break
        }
        
        if let filterType = filterType {
            let agendaCoordinator = AgendaCoordinator(filterType: filterType, stack: self.stack, dependency: self.dependency)
            agendaCoordinator.delegate = self
            agendaCoordinator.viewController?.title = subTabType.title
            self.showTempCoordinator(agendaCoordinator)
        }
    }
    
    public func toggleFullScreen() {
        let macHomeViewController = (self.viewController as? DesktopHomeViewController)
        
        if macHomeViewController?.isLeftPartVisiable == true || macHomeViewController?.isMiddlePartVisiable == true {
            macHomeViewController?.hideLeftAndMiddlePart()
        } else {
            showAllParts()
        }
    }
    
    public func showAllParts() {
        (self.viewController as? DesktopHomeViewController)?.toggleLeftPartVisiability(visiable: true)
        (self.viewController as? DesktopHomeViewController)?.toggleMiddlePartVisiability(visiable: true)
    }
    
    public func toggleLeftPart() {
        if let desktopViewController = self.viewController as? DesktopHomeViewController {
            desktopViewController.toggleLeftPartVisiability(visiable: !desktopViewController.isLeftPartVisiable, animated: true)
        }
    }
    
    public func toggleMiddlePart() {
        if let desktopViewController = self.viewController as? DesktopHomeViewController {
            desktopViewController.toggleMiddlePartVisiability(visiable: !desktopViewController.isMiddlePartVisiable, animated: true)
        }
    }
    
    public func showHeadings(tag: String) {
        let agendaCoordinator = AgendaCoordinator(filterType: .tag(tag), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.delegate = self
        agendaCoordinator.viewController?.title = tag
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadings(planning: String) {
        let agendaCoordinator = AgendaCoordinator(filterType: .planning(planning), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.delegate = self
        agendaCoordinator.viewController?.title = planning
        self.showTempCoordinator(agendaCoordinator)
    }
        
    public func didSelectTab(at index: Int, viewController: UIViewController) {
        // if last showing temp view controller, remove from children
        if let tempCoordinator = self.tempCoordinator {
            self.remove(tempCoordinator)
            self.tempCoordinator = nil
        }
        
        if isMacOrPad {
            (self.viewController as? DesktopHomeViewController)?.showInMiddlePart(viewController: viewController)
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
        (self.viewController as? DesktopHomeViewController)?.selectDocument(url: url, location: location)
    }
    
    public func addOnDesktopContainerTabIfNeeded(url: URL, shouldSelect: Bool) {
        if let macHomeViewController = self.viewController as? DesktopHomeViewController, !macHomeViewController.isDocumentAdded(url: url) {
            let stack = Coordinator.createDefaultNavigationControlller()
            let editorCoordinator = EditorCoordinator(stack: stack, dependency: self.dependency, usage: .editor(url, 0))
            
            macHomeViewController.addDocuments(editorCoordinator: editorCoordinator, souldSelect: shouldSelect)
            self.addChild(editorCoordinator)
        }
    }
}

extension HomeCoordinator: DesktopDocumentTabContainerViewControllerDelegate {
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
