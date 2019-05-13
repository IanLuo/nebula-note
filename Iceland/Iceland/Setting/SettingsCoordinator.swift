//
//  SettingsCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class SettingsCoordinator: Coordinator {
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        let viewModel = SettingsViewModel(coordinator: self)
        let viewController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as! SettingsViewController
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        self.viewController = viewController
    }
}
