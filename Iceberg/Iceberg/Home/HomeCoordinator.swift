
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
        
        if isMacOrPad {
            self.viewController = MacHomeViewController(dashboardViewController: dashboardViewController, documentTabsContainerViewController: MacDocumentTabContainerViewController(viewModel: viewModel))
        } else {
            let homeViewController = HomeViewController(masterViewController: navigationController)
            self.viewController = homeViewController
            homeViewController.delegate = self
        }
        
        let agendaCoordinator = AgendaCoordinator(stack: stack, dependency: dependency)
        agendaCoordinator.delegate = self
        self.addPersistentCoordinator(agendaCoordinator)
        
        let captureCoordinator = CaptureListCoordinator(stack: stack, dependency: dependency, mode: CaptureListViewModel.Mode.manage)
        self.addPersistentCoordinator(captureCoordinator)
        
        let searchCoordinator = SearchCoordinator(stack: stack, dependency: dependency)
        searchCoordinator.delegate = self
        self.addPersistentCoordinator(searchCoordinator)
        
        let browserCoordinator = BrowserCoordinator(stack: stack, dependency: dependency, usage: .browseDocument)
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
        
        let hasInitedLandingTab: PublishSubject<Void> = PublishSubject<Void>()
        
        if !isMacOrPad {
            self.dependency.appContext.isFileReadyToAccess.takeUntil(hasInitedLandingTab).subscribe(onNext: { _ in
                hasInitedLandingTab.onNext(())
                (self.viewController as? HomeViewController)?.showChildViewController(tabs[SettingsAccessor.Item.landingTabIndex.get(Int.self) ?? 3])
            }).disposed(by: self.disposeBag)
        }
        
    }
    
    public override func didMoveIn() {
        if let opendFiles = dependency.settingAccessor.openedDocuments {
            if isMacOrPad {
                opendFiles.forEach {
                    self.openDocumentInHomeViewRightPart(url: $0, location: 0)
                }
            } else {
                if let first = opendFiles.first {
                    self.topCoordinator?.openDocument(url: first, location: 0)
                }
            }
        }
    }
    
    private var tempCoordinator: Coordinator?
    
    public func selectOnDashboardTab(at index: Int) {
        self._dashboardViewController.selectOnTab(index: index)
    }
    
    public func showTempCoordinator(_ coordinator: Coordinator) {
        // set temp coordinator as child of current coordinator
        coordinator.parent = self
        self.addChild(coordinator)
        self.tempCoordinator = coordinator
        
        if isMacOrPad {
            if let viewController = coordinator.viewController {
                (self.viewController as? MacHomeViewController)?.showInMiddlePart(viewController: viewController)
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
}

extension HomeCoordinator: SearchCoordinatorDelegate {
    public func didSelectDocument(url: URL, location: Int, searchCoordinator: SearchCoordinator) {
        if isMacOrPad {
            self.openDocumentInHomeViewRightPart(url: url, location: location)
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
            self.openDocumentInHomeViewRightPart(url: url, location: location)
        } else {
            self.openDocument(url: url, location: location)
        }
    }
}

extension HomeCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL, coordinator: BrowserCoordinator) {
        if isMacOrPad {
            self.openDocumentInHomeViewRightPart(url: url, location: 0)
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
        let macHomeViewController = (self.viewController as? MacHomeViewController)
        
        if macHomeViewController?.isLeftPartVisiable == true || macHomeViewController?.isMiddlePartVisiable == true {
            macHomeViewController?.hideLeftAndMiddlePart()
        } else {
            showAllParts()
        }
    }
    
    public func showAllParts() {
        (self.viewController as? MacHomeViewController)?.toggleLeftPartVisiability(visiable: true)
        (self.viewController as? MacHomeViewController)?.toggleMiddlePartVisiability(visiable: true)
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
            (self.viewController as? MacHomeViewController)?.showInMiddlePart(viewController: viewController)
        } else {
            if let homeViewController = self.viewController as? HomeViewController {
                homeViewController.showChildViewController(viewController)
                homeViewController.showDetailView()
            }
        }
    }
}

extension HomeCoordinator {
    public func openDocumentInHomeViewRightPart(url: URL, location: Int) {
        let stack = Coordinator.createDefaultNavigationControlller()
        let editorCoordinator = EditorCoordinator(stack: stack, dependency: self.dependency, usage: .editor(url, location))
        self.addChild(editorCoordinator)
        
        if let viewController = editorCoordinator.viewController as? DocumentEditorViewController {
            (self.viewController as? MacHomeViewController)?.showDocument(url: url, editorViewController: viewController)
        }
    }
    
    public func closeDocment(url: URL) {
        self.children.forEach {
            if let editor = $0 as? EditorCoordinator {
                switch editor.usage {
                case .editor(let _url, _):
                    if url == _url {
                        self.remove(editor)
                        (self.viewController as? MacHomeViewController)?.closeDocument(url: url)
                    }
                default: break
                }
            }
        }
    }
}
