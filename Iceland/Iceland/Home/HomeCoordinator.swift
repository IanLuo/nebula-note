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
        let viewModel = DashboardViewModel(documentSearchManager: dependency.documentSearchManager)
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        
        let viewController = HomeViewController(masterViewController: UINavigationController(rootViewController: dashboardViewController))
        self.homeViewController = viewController
        
        super.init(stack: stack, dependency: dependency)
        
        viewModel.coordinator = self
        dashboardViewController.delegate = self
        
        self.viewController = viewController
        
        let agendaCoordinator = AgendaCoordinator(stack: stack, dependency: dependency)
        self.addChild(agendaCoordinator)
        
        let captureCoordinator = CaptureListCoordinator(stack: stack, dependency: dependency)
        self.addChild(captureCoordinator)
        
        let searchCoordinator = SearchCoordinator(stack: stack, dependency: dependency)
        searchCoordinator.delegate = self
        self.addChild(searchCoordinator)
        
        let browserCoordinator = BrowserCoordinator(stack: stack, dependency: dependency, usage: .chooseDocument)
        browserCoordinator.delegate = self
        self.addChild(browserCoordinator)
        
        dashboardViewController.addTab(tabs: [DashboardViewController.TabType.agenda(agendaCoordinator.viewController!, 0),
                                              DashboardViewController.TabType.captureList(captureCoordinator.viewController!, 1),
                                              DashboardViewController.TabType.search(searchCoordinator.viewController!, 2),
                                              DashboardViewController.TabType.documents(browserCoordinator.viewController!, 3)])
        
        self.homeViewController.showChildViewController(agendaCoordinator.viewController!)
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
    public func didSelectHeading(_ heading: Document.Heading, url: URL) {
        
    }
    
    public func didSelectTab(at index: Int, viewController: UIViewController) {
        self.homeViewController.showChildViewController(viewController)
        self.homeViewController.showChildView()
    }
}
