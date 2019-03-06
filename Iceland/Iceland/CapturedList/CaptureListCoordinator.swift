//
//  CaptureListCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol CaptureListCoordinatorDelegate: class {
    func didSelectAttachment(attachment: Attachment, coordinator: CaptureListCoordinator)
}

public class CaptureListCoordinator: Coordinator {
    let viewModel: CaptureListViewModel
    
    public weak var delegate: CaptureListCoordinatorDelegate?
    
    public init(stack: UINavigationController, dependency: Dependency, mode: CaptureListViewModel.Mode) {
        self.viewModel = CaptureListViewModel(service: CaptureService(), mode: mode)
        let viewController = CaptureListViewController(viewModel: self.viewModel)
        
        super.init(stack: stack, dependency: dependency)
        self.viewController = viewController
        viewModel.coordinator = self
    }
    
    public func showDocumentHeadingSelector() {
        let documentCoord = BrowserCoordinator(stack: self.stack,
                                               dependency: super.dependency,
                                               usage: .chooseHeading)
        documentCoord.delegate = self
        documentCoord.start(from: self)
    }
}

extension CaptureListCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL) {}
    
    public func didSelectHeading(url: URL, heading: HeadingToken) {
        self.viewModel.refile(editorService: self.dependency.editorContext.request(url: url), heading: heading)
    }
}
