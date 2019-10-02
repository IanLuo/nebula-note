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
import Interface

public protocol CaptureListCoordinatorDelegate: class {
    func didSelectAttachment(attachment: Attachment, coordinator: CaptureListCoordinator)
}

public class CaptureListCoordinator: Coordinator {
    let viewModel: CaptureListViewModel
    
    public weak var delegate: CaptureListCoordinatorDelegate?
    
    public var onSelectAction: ((Attachment) -> Void)?
    public var onCancelAction: (() -> Void)?
    
    public init(stack: UINavigationController, dependency: Dependency, mode: CaptureListViewModel.Mode) {
        self.viewModel = CaptureListViewModel(service: CaptureService(attachmentManager: dependency.attachmentManager), mode: mode)
        let viewController = CaptureListViewController(viewModel: self.viewModel)
        
        super.init(stack: stack, dependency: dependency)
        
        viewController.delegate = self
        self.viewController = viewController
        viewModel.coordinator = self
    }
    
    public func showDocumentHeadingSelector(completion: @escaping (URL, DocumentHeading) -> Void, canceled: @escaping () -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let documentCoord = BrowserCoordinator(stack: navigationController,
                                               dependency: super.dependency,
                                               usage: .chooseHeader)
        
        documentCoord.didSelectHeadingAction = { [weak documentCoord]  url, heading in
            documentCoord?.stop()
            completion(url, heading)
        }
        
        documentCoord.didCancelAction = { [weak documentCoord] in
            documentCoord?.stop()
            canceled()
        }
        
        documentCoord.start(from: self)
    }
}

extension CaptureListCoordinator: CaptureListViewControllerDelegate {
    public func didChooseAttachment(_ attachment: Attachment, viewController: UIViewController) {
        self.delegate?.didSelectAttachment(attachment: attachment, coordinator: self)
        self.onSelectAction?(attachment)
    }
}
