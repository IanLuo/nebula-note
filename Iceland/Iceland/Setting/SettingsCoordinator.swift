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
        let viewModel = SettingsViewModel()
        super.init(stack: stack, dependency: dependency)
        let viewController = SettingsViewController(viewModel: viewModel)
        viewModel.delegate = viewController
        self.viewController = viewController
    }
    
    public func getCustomizedPlannings() -> [String: [String]]? {
        return nil
    }
}
