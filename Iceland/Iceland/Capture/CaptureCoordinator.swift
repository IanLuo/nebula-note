//
//  Capture.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage

public class CaptureCoordinator: Coordinator {
    public let viewController: UIViewController
    
    public override init(stack: UINavigationController) {
        let viewModel = CaptureListViewModel()
        self.viewController = CatpureListViewController(viewModel: viewModel)
        super.init(stack: stack)
        viewModel.delegate = self
    }
    
    public override func start() {
        self.stack.pushViewController(self.viewController, animated: true)
    }
}

extension CaptureCoordinator: CaptureListViewModelDelegate {
    
}
