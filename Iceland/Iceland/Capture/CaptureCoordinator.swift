//
//  Capture.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage
import Business

public protocol CaptureCoordinatorDelegate: class {
    func didSaveCapture(attachment: Attachment)
}

public class CaptureCoordinator: Coordinator {
    public weak var delegate: CaptureCoordinatorDelegate?
    
    public init(stack: UINavigationController, type: Attachment.AttachmentType) {

        let captureViewModel = CaptureViewModel(service: CaptureService())
        
        super.init(stack: stack)

        let viewController: CaptureViewController!
        switch type {
        case .text:
            viewController = CaptureTextViewController(viewModel: captureViewModel)
        case .link:
            viewController = CaptureLinkViewController(viewModel: captureViewModel)
        case .image:
            viewController = CaptureImageViewController(viewModel: captureViewModel)
        case .sketch:
            viewController = CaptureSketchViewController(viewModel: captureViewModel)
        case .location:
            viewController = CaptureLocationViewController(viewModel: captureViewModel)
        case .audio:
            viewController = CaptureAudioViewController(viewModel: captureViewModel)
        case .video:
            viewController = CaptureVideoViewController(viewModel: captureViewModel)
        }

        viewController.delegate = self
        
        self.viewController = viewController
    }
}

extension CaptureCoordinator: CaptureViewControllerDelegate {
    public func didSaveCapture(attachment: Attachment) {
        self.delegate?.didSaveCapture(attachment: attachment)
    }
}
