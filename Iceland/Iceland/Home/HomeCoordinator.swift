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

public class HomeCoordinator: Coordinator {
    private let homeViewController: HomeViewController
    
    private let _dashboardViewController: DashboardViewController
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        let viewModel = DashboardViewModel(documentSearchManager: dependency.documentSearchManager)
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        
        let navigationController = UINavigationController(rootViewController: dashboardViewController)
        navigationController.navigationBar.barTintColor = InterfaceTheme.Color.background1
        navigationController.navigationBar.tintColor = InterfaceTheme.Color.interactive
        
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
        
        let captureCoordinator = CaptureListCoordinator(stack: stack, dependency: dependency)
        self.addPersistentCoordinator(captureCoordinator)
        
        let searchCoordinator = SearchCoordinator(stack: stack, dependency: dependency)
        searchCoordinator.delegate = self
        self.addPersistentCoordinator(searchCoordinator)
        
        let browserCoordinator = BrowserCoordinator(stack: stack, dependency: dependency, usage: .chooseDocument)
        browserCoordinator.delegate = self
        self.addPersistentCoordinator(browserCoordinator)
        
        dashboardViewController.addTab(tabs: [DashboardViewController.TabType.agenda(agendaCoordinator.viewController!, 0),
                                              DashboardViewController.TabType.captureList(captureCoordinator.viewController!, 1),
                                              DashboardViewController.TabType.search(searchCoordinator.viewController!, 2),
                                              DashboardViewController.TabType.documents(browserCoordinator.viewController!, 3)])
        
        self.homeViewController.showChildViewController(agendaCoordinator.viewController!)
    }
    
    
    private var tempCoordinator: Coordinator?
    public func showTempCoordinator(_ coordinator: Coordinator) {
        self.tempCoordinator = nil
        self.tempCoordinator = coordinator
        self.homeViewController.showChildViewController(coordinator.viewController!)
        self.homeViewController.showDetailView()
    }
    
    public func addPersistentCoordinator(_ coordinator: Coordinator) {
        self.addChild(coordinator)
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
    public func didSelectDocument(url: URL) {
        self.openDocument(url: url, location: 0)
    }
    
    public func didSelectHeading(url: URL, heading: HeadingToken) {
        // ignore
    }
}

extension HomeCoordinator: HomeViewControllerDelegate {
    public func didShowMasterView() {
        self._dashboardViewController.reloadDataIfNeeded()
    }
    
    public func didShowDetailView() {
    }
}

extension HomeCoordinator: DashboardViewControllerDelegate {
    public func showHeadingsWithoutDate() {
        let agendaCoordinator = AgendaCoordinator(filterType: .withoutDate, stack: self.stack, dependency: self.dependency)
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadingsScheduled() {
        let agendaCoordinator = AgendaCoordinator(filterType: .scheduled, stack: self.stack, dependency: self.dependency)
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadingsOverdue() {
        let agendaCoordinator = AgendaCoordinator(filterType: .overdue, stack: self.stack, dependency: self.dependency)
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadingsScheduleSoon() {
        let agendaCoordinator = AgendaCoordinator(filterType: .scheduledSoon, stack: self.stack, dependency: self.dependency)
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadingsOverdueSoon() {
        let agendaCoordinator = AgendaCoordinator(filterType: .dueSoon, stack: self.stack, dependency: self.dependency)
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func showHeadings(with tag: String) {
        let agendaCoordinator = AgendaCoordinator(filterType: .tag(tag), stack: self.stack, dependency: self.dependency)
        self.showTempCoordinator(agendaCoordinator)
    }
    
    public func didSelectTab(at index: Int, viewController: UIViewController) {
        self.homeViewController.showChildViewController(viewController)
        self.homeViewController.showDetailView()
    }
}
