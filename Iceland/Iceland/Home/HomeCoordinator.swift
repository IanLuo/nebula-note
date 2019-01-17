//
//  HomeCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class HomeCoordinator: Coordinator {
    public override init(stack: UINavigationController, context: Context) {
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        super.init(stack: stack, context: context)
        viewModel.dependency = self
        self.viewController = viewController
    }

    public func showBrowser() {
        let coord = BrowserCoordinator(stack: self.stack,
                                       context: self.context,
                                       usage: BrowserCoordinator.Usage.chooseHeading)
        coord.delegate = self
        coord.start(from: self)
    }
    
    public func showAttachmentCreator(type: Attachment.AttachmentType) {
        let captureImage = AttachmentCoordinator(stack: self.stack,
                                                 context: self.context,
                                                 type: type)
        captureImage.delegate = self
        captureImage.start(from: self)
    }
    
    public func showCaptureList() {
        let captureListCoordinator = CaptureListCoordinator(stack: self.stack,
                                                            context: self.context)
        captureListCoordinator.start(from: self)
    }
}

extension HomeCoordinator: AttachmentCoordinatorDelegate {
    public func didSaveAttachment(key: String) {
        CaptureService().save(key: key)
    }
}

extension HomeCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL) {
        
    }
    
    public func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading) {
        
    }
}
