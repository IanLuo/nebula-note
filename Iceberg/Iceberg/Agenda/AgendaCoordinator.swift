//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core

public protocol AgendaCoordinatorDelegate: class {
    func didSelectDocument(url: URL, location: Int)
}

/// 用户的活动中心
/// 每天的任务安排显示在此处
public class AgendaCoordinator: Coordinator {
    public weak var delegate: AgendaCoordinatorDelegate?
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        let viewModel = AgendaViewModel(coordinator: self)
        let viewController = AgendaViewController(viewModel: viewModel)
        viewController.delegate = self
        self.viewController = viewController
    }
    
    public func getAllTags() -> [String] {
        if let agendaViewController = viewController as? AgendaViewController {
            return Array(agendaViewController.viewModel.tags.value.keys)
        } else {
            return []
        }
    }
}

extension AgendaCoordinator: AgendaViewControllerDelegate {
    public func didSelectDocument(url: URL, location: Int) {
        self.delegate?.didSelectDocument(url: url, location: location)
    }
}
