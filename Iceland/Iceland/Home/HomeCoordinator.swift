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
    
    public func showImageCapture() {
        let captureImage = CaptureCoordinator(stack: self.stack, type: .image)
        captureImage.delegate = self
        captureImage.start(from: self)
    }
    
    public func showAudioRecorder() {
        let captureAudio = CaptureCoordinator(stack: self.stack, type: .audio)
        captureAudio.delegate = self
        captureAudio.start(from: self)
    }
}

extension HomeCoordinator: CaptureCoordinatorDelegate {
    public func didSaveCapture(attachment: Attachment) {
        
    }
}

extension HomeCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL) {
        
    }
    
    public func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading) {
        
    }
}
