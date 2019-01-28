//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

/// 用户的活动中心
/// 每天的任务安排显示在此处
public class AgendaCoordinator: Coordinator {
    public override init(stack: UINavigationController, dependency: Dependency) {
        let viewModel = AgendaViewModel(documentSearchManager: dependency.documentSearchManager, headingTrimmer: dependency.headingTrimmer)
        let viewController = AgendaViewController(viewModel: viewModel)
        super.init(stack: stack, dependency: dependency)
        self.viewController = viewController
        viewModel.coordinator = self
    }
}

extension AgendaCoordinator {
    public func openAgendaActions(url: URL, heading: Document.Heading) {
        let viewModel = AgendaActionViewModel(service: OutlineEditorServer.request(url: url), heading: heading)
        let viewController = AgendaActionViewController(viewModel: viewModel)
        viewModel.delegate = viewController
        viewController.modalPresentationStyle = .overCurrentContext
        self.stack.present(viewController, animated: true, completion: nil)
    }
}
