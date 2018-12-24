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
    public enum CaptureType {
        case text
        case link
        case image
        case location
        case sketch
        case audio
        case video
    }
    
    public let viewController: UIViewController
    
    public override init(stack: UINavigationController) {
        let viewModel = CaptureListViewModel()
        let viewController = CatpureListViewController(viewModel: viewModel)
        self.viewController = viewController
        super.init(stack: stack)
        viewModel.delegate = viewController
    }
    
    public init(stack: UINavigationController, type: CaptureType) {
        
        switch type {
        case .text:
            viewController = CaptureTextViewController(viewModel: CaptureViewModel(service: CaptureService()))
            
        default:
            viewController = CaptureTextViewController(viewModel: CaptureViewModel(service: CaptureService()))
        }
        
        super.init(stack: stack)
    }
    
    
    public override func start() {
        self.stack.pushViewController(self.viewController, animated: true)
    }
}
