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
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        let viewController = HomeViewController()
        self.homeViewController = viewController
        
        super.init(stack: stack, dependency: dependency)
        self.viewController = viewController
        
        self.addSubCoordinator(coordinator: AgendaCoordinator(stack: stack, dependency: dependency))
        self.addSubCoordinator(coordinator: CaptureListCoordinator(stack: stack, dependency: dependency))
        
        let searchCoordinator = SearchCoordinator(stack: stack, dependency: dependency)
        searchCoordinator.delegate = self
        self.addSubCoordinator(coordinator: searchCoordinator)
        
        let browserCoordinator = BrowserCoordinator(stack: stack, dependency: dependency, usage: .chooseDocument)
        browserCoordinator.delegate = self
        self.addSubCoordinator(coordinator: browserCoordinator)
        
        let viewModel = DashboardViewModel(documentSearchManager: dependency.documentSearchManager)
        viewModel.coordinator = self
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        viewController.masterNavigationController.pushViewController(dashboardViewController, animated: false)
        dashboardViewController.delegate = self
        
        self.homeViewController.children.forEach {
            dashboardViewController.addTab(DashboardViewController.Tab(icon: $0.tabBarItem.image, title: $0.title ?? "unknown"))
        }
    }
    
    public func addSubCoordinator(coordinator: Coordinator) {
        self.addChild(coordinator)
        
        if let viewController = coordinator.viewController {
            self.viewController?.addChild(viewController)
        }
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
    
    public func didSelectHeading(url: URL, heading: Document.Heading) {
        // ignore
    }
}

extension HomeCoordinator: DashboardViewControllerDelegate {
    public func didSelectSubtab(at index: Int, for tabIndex: Int) {
        self.homeViewController.masterNavigationController.pushViewController(HeadingListViewController(), animated: true)
    }
    
    public func didSelectTab(at index: Int) {
        self.homeViewController.showChildViewController(at: index)
        self.homeViewController.showChildView()
    }
}
