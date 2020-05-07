//
//  UIViewController+Heirachy.swift
//  Interface
//
//  Created by ian luo on 2020/5/1.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    public func addChildViewController(_ viewController: UIViewController) {
        viewController.willMove(toParent: self)
        self.addChild(viewController)
        viewController.didMove(toParent: self)
    }
}
