//
//  KanbanCoordinator.swift
//  x3Note
//
//  Created by ian luo on 2021/3/22.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit

public class KanbanCoordinator: Coordinator {
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        self.viewController = KanbanViewController(viewModel: KanbanViewModel(coordinator: self))
    }
}
