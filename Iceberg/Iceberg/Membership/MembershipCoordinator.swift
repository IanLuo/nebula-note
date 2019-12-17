//
//  MembershipCoordinator.swift
//  Icetea
//
//  Created by ian luo on 2019/12/17.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class MembershipCoordinator: Coordinator {
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        let viewModel = MembershipViewModel(coordinator: self)
        let viewController = MembershipViewController(viewModel: viewModel)
        
        self.viewController = viewController
    }
}
