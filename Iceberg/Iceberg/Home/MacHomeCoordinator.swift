//
//  MacHomeCoordinator.swift
//  x3Note
//
//  Created by ian luo on 2020/4/28.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import Core

public class MacHomeCoordinator: Coordinator {
    
    private let disposeBag = DisposeBag()
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        let viewModel = DashboardViewModel(documentSearchManager: dependency.documentSearchManager)
        let dashboardViewController = DashboardViewController(viewModel: viewModel)
        
        let homeViewController = MacHomeViewController(dashboardViewController: dashboardViewController)
        super.viewController = homeViewController
        
        let agendaCoordinator = AgendaCoordinator(stack: stack, dependency: dependency)
        let captureCoordinator = CaptureListCoordinator(stack: stack, dependency: dependency, mode: CaptureListViewModel.Mode.manage)
        let searchCoordinator = SearchCoordinator(stack: stack, dependency: dependency)
        let browserCoordinator = BrowserCoordinator(stack: stack, dependency: dependency, usage: .browseDocument)
        
        self.addChild(agendaCoordinator)
        self.addChild(captureCoordinator)
        self.addChild(searchCoordinator)
        self.addChild(browserCoordinator)
        
        let tabs = [Coordinator.createDefaultNavigationControlller(root: agendaCoordinator.viewController!),
                    Coordinator.createDefaultNavigationControlller(root: captureCoordinator.viewController!),
                    Coordinator.createDefaultNavigationControlller(root: searchCoordinator.viewController!),
                    Coordinator.createDefaultNavigationControlller(root: browserCoordinator.viewController!)]
        
        dashboardViewController.addTab(tabs: [DashboardViewController.TabType.agenda(tabs[0], 0),
                                              DashboardViewController.TabType.captureList(tabs[1], 1),
                                              DashboardViewController.TabType.search(tabs[2], 2),
                                              DashboardViewController.TabType.documents(tabs[3], 3)])
        
        let hasInitedLandingTab: PublishSubject<Void> = PublishSubject<Void>()
        self.dependency.appContext.isFileReadyToAccess.takeUntil(hasInitedLandingTab).subscribe(onNext: { _ in
            hasInitedLandingTab.onNext(())
            homeViewController.chooseTab(index: SettingsAccessor.Item.landingTabIndex.get(Int.self) ?? 3, subTab: nil)
        }).disposed(by: self.disposeBag)
    }
}
