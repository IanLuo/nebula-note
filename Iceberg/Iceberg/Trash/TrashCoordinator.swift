//
//  TrashCoordinator.swift
//  Iceberg
//
//  Created by ian luo on 2019/12/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class TrashCoordinator: Coordinator {
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        self.viewController = TrashViewController(viewModel: TrashViewModel(coordinator: self))
    }
}
