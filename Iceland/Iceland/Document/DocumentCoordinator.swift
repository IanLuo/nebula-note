//
//  DocumentCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class DocumentCoordinator: Coordinator {
    private let viewController: PageViewController

    public override init(stack: UINavigationController) {
        self.viewController = PageViewController()
        super.init(stack: stack)
    }
    
    public override func start() {
        self.stack.pushViewController(self.viewController, animated: true)
    }
}
