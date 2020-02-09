//
//  AttachmentManagerCoordinator.swift
//  Icetea
//
//  Created by ian luo on 2020/2/6.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import Core

public class AttachmentManagerCoordinator: Coordinator {
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        let viewController = AttachmentManagerViewController(viewModel: AttachmentManagerViewModel(coordinator: self))
        
        self.viewController = viewController
    }
}
