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
    public override init(stack: UINavigationController) {
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        super.init(stack: stack)
        viewModel.dependency = self
        self.viewController = viewController
    }

    public func showBrowser() {
        let coord = BrowserCoordinator(stack: self.stack, documentManager: DocumentManager(), usage: BrowserCoordinator.Usage.chooseHeading)
        coord.delegate = self
        coord.start(from: self)
    }
    
    public func showAttachmentCreator(type: Attachment.AttachmentType) {
        let captureImage = AttachmentCoordinator(stack: self.stack, type: type)
        captureImage.delegate = self
        captureImage.start(from: self)
    }
}

extension HomeCoordinator: AttachmentCoordinatorDelegate {
    public func didSaveAttachment(key: String) {
        
    }
}

extension HomeCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL) {
        
    }
    
    public func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading) {
        
    }
}
