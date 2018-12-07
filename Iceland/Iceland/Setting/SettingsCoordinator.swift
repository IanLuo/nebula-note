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
    public let viewController: UIViewController
    
    public override init(stack: UINavigationController) {
        let viewModel = SettingsViewModel()
        self.viewController = SettingsViewController(viewModel: viewModel)
        super.init(stack: stack)
        viewModel.delegate = self
    }
}

extension SettingsCoordinator: SettingsViewModelDelegate {
    
}
