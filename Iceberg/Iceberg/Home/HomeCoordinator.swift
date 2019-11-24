
//
//  HomeCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public class HomeCoordinator: Coordinator {
    private let homeViewController: HomeViewController
    
    private let _dashboardViewController: DashboardViewController
    
    private let _viewModel: DashboardViewModel
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        let viewModel = DashboardViewModel(documentSearchManager: dependency.documentSearchManager)
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        
        self._viewModel = viewModel
        
        let navigationController = Coordinator.createDefaultNavigationControlller()
        navigationController.pushViewController(dashboardViewController, animated: false)
        
        let homeViewController = HomeViewController(masterViewController: navigationController)
        self.homeViewController = homeViewController
        self._dashboardViewController = dashboardViewController
        super.init(stack: stack, dependency: dependency)
        
        viewModel.coordinator = self
        dashboardViewController.delegate = self
        homeViewController.delegate = self
        
        self.viewController = homeViewController
        
        let agendaCoordinator = AgendaCoordinator(stack: stack, dependency: dependency)
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
        
        dependency.documentManager.getFileLocationComplete { [weak self] _ in
            guard let s = self else { return }
            s.homeViewController.showChildViewController(tabs[SettingsAccessor.Item.landingTabIndex.get(Int.self) ?? 3])
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
        
        self.homeViewController.showChildViewController(Coordinator.createDefaultNavigationControlller(root: coordinator.viewController!))
        self.homeViewController.showDetailView()
    }
    
    public func addPersistentCoordinator(_ coordinator: Coordinator) {
        self.addChild(coordinator)
    }
    
    public func showSettings() {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        let settingsCoordinator = SettingsCoordinator(stack: navigationController, dependency: self.dependency)
        settingsCoordinator.start(from: self)
    }
    
    public func getAllTags() -> [String] {
        return self._viewModel.allTags
    }
}

extension HomeCoordinator: SearchCoordinatorDelegate {
    public func didSelectDocument(url: URL, location: Int, searchCoordinator: SearchCoordinator) {
        self.openDocument(url: url, location: location)
    }
    
    public func didCancelSearching() {
        
    }
}

extension HomeCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL, coordinator: BrowserCoordinator) {
        self.openDocument(url: url, location: 0)
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
    public func showHeadingsScheduled(headings: [DocumentHeadingSearchResult], from subTabType: DashboardViewController.SubtabType) {
        let agendaCoordinator = AgendaCoordinator(filterType: .scheduled(headings), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.viewController?.title = subTabType.title
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadingsOverdue(headings: [DocumentHeadingSearchResult], from subTabType: DashboardViewController.SubtabType) {
        let agendaCoordinator = AgendaCoordinator(filterType: .overdue(headings), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.viewController?.title = subTabType.title
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadingsScheduleSoon(headings: [DocumentHeadingSearchResult], from subTabType: DashboardViewController.SubtabType) {
        let agendaCoordinator = AgendaCoordinator(filterType: .startSoon(headings), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.viewController?.title = subTabType.title
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadingsOverdueSoon(headings: [DocumentHeadingSearchResult], from subTabType: DashboardViewController.SubtabType) {
        let agendaCoordinator = AgendaCoordinator(filterType: .dueSoon(headings), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.viewController?.title = subTabType.title
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadings(tag: String) {
        let agendaCoordinator = AgendaCoordinator(filterType: .tag(tag), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.viewController?.title = tag
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadings(planning: String) {
        let agendaCoordinator = AgendaCoordinator(filterType: .planning(planning), stack: self.stack, dependency: self.dependency)
        agendaCoordinator.viewController?.title = planning
        self.showTempCoordinator(agendaCoordinator)
    }
        
    public func didSelectTab(at index: Int, viewController: UIViewController) {
        // if last showing temp view controller, remove from children
        if let tempCoordinator = self.tempCoordinator {
            self.remove(tempCoordinator)
            self.tempCoordinator = nil
        }
        
        self.homeViewController.showChildViewController(viewController)
        self.homeViewController.showDetailView()
    }
}
