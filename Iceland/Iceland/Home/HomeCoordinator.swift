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
    public override init(stack: UINavigationController, context: Context) {
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        super.init(stack: stack, context: context)
        viewModel.dependency = self
        self.viewController = viewController
        
        self.addSubCoordinator(coordinator: AgendaCoordinator(stack: stack, context: context))
        self.addSubCoordinator(coordinator: CaptureListCoordinator(stack: stack, context: context))
        self.addSubCoordinator(coordinator: SearchCoordinator(stack: stack, context: context))
        
        let browserCoordinator = BrowserCoordinator(stack: stack, context: context, usage: .chooseDocument)
        browserCoordinator.delegate = self
        self.addSubCoordinator(coordinator: browserCoordinator)
    }
    
    public func addSubCoordinator(coordinator: Coordinator) {
        self.addChild(coordinator)
        
        if let viewController = coordinator.viewController {
            self.viewController?.addChild(viewController)
        }
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
