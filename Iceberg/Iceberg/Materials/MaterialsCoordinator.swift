//
//  MaterialsCoordinator.swift
//  x3Note
//
//  Created by ian luo on 2021/6/25.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

public class MaterialsCoordinator: Coordinator {
    public override init(stack: UINavigationController, dependency: Dependency) {
        self.captureCoordinator = CaptureListCoordinator(stack: stack, dependency: dependency, mode: CaptureListViewModel.Mode.manage)
        self.attachmentmanagerCoordinator = AttachmentManagerCoordinator(stack: stack, dependency: dependency)
        
        super.init(stack: stack, dependency: dependency)
        
        self.viewController = MaterialsViewController(viewControllers: [self.captureCoordinator.viewController!, self.attachmentmanagerCoordinator.viewController!])
    }
    
    let captureCoordinator: CaptureListCoordinator
    let attachmentmanagerCoordinator: AttachmentManagerCoordinator
}
