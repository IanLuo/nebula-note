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
        let viewModel = CaptureListViewModel(service: CaptureService())
        let viewController = CatpureListViewController(viewModel: viewModel)
        self.viewController = viewController
        super.init(stack: stack)
        viewModel.delegate = viewController
    }
    
    public init(stack: UINavigationController, type: Attachment.AttachmentType) {
        
        switch type {
        case .text:
            viewController = CaptureTextViewController(viewModel: CaptureViewModel(service: CaptureService()))
        case .link:
            viewController = CaptureLinkViewController(viewModel: CaptureViewModel(service: CaptureService()))
        case .image:
            viewController = CaptureImageViewController(viewModel: CaptureViewModel(service: CaptureService()))
        case .sketch:
            viewController = CaptureSketchViewController(viewModel: CaptureViewModel(service: CaptureService()))
        case .location:
            viewController = CaptureLocationViewController(viewModel: CaptureViewModel(service: CaptureService()))
        case .audio:
            viewController = CaptureAudioViewController(viewModel: CaptureViewModel(service: CaptureService()))
        case .video:
            viewController = CaptureVideoViewController(viewModel: CaptureViewModel(service: CaptureService()))
        }
        
        super.init(stack: stack)
    }
    
    public override func start() {
        self.stack.pushViewController(self.viewController, animated: true)
    }
    
    public func openDocumentBrowserForRefile() {
        
    }
}
