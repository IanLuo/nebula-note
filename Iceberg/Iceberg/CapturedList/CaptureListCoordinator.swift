//
//  CaptureListCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public protocol CaptureListCoordinatorDelegate: class {
    func didSelectAttachment(attachment: Attachment, coordinator: CaptureListCoordinator)
}

public class CaptureListCoordinator: Coordinator {
    var viewModel: CaptureListViewModel!
    
    public weak var delegate: CaptureListCoordinatorDelegate?
    
    public var onSelectAction: ((Attachment) -> Void)?
    public var onCancelAction: (() -> Void)?
    
    public init(stack: UINavigationController, dependency: Dependency, mode: CaptureListViewModel.Mode) {
        super.init(stack: stack, dependency: dependency)
        
        self.viewModel = CaptureListViewModel(service: CaptureService(attachmentManager: dependency.attachmentManager), mode: mode, coordinator: self)
        let viewController = CaptureListViewController(viewModel: self.viewModel)
                
        viewController.delegate = self
        self.viewController = viewController
    }
    
    public func showDocumentHeadingSelector(completion: @escaping (URL, OutlineLocation) -> Void, canceled: @escaping () -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let documentCoord = BrowserCoordinator(stack: navigationController,
                                               dependency: super.dependency,
                                               usage: .chooseHeader)
        
        if #available(macOS 11, *) {
            documentCoord.viewController?.modalPresentationStyle = .fullScreen
        }
        
        documentCoord.didSelectOutlineAction = { [weak documentCoord]  url, outlineLocation in
            documentCoord?.stop()
            completion(url, outlineLocation)
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
