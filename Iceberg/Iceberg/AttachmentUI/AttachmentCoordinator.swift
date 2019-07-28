//
//  AttachmentCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage
import Business

public protocol AttachmentCoordinatorDelegate: class {
    func didSaveAttachment(key: String)
    func didCancelAttachment(coordinator: AttachmentCoordinator)
}

public class AttachmentCoordinator: Coordinator {
    public weak var delegate: AttachmentCoordinatorDelegate?
    
    public var onSaveAttachment: ((String) -> Void)?
    public var onCancel: (() -> Void)?
    
    public var kind: Attachment.Kind
    
    public init(stack: UINavigationController, dependency: Dependency, kind: Attachment.Kind) {

        let attachmentViewModel = AttachmentViewModel(attachmentManager: dependency.attachmentManager)
        
        self.kind = kind
        
        super.init(stack: stack, dependency: dependency)
        
        attachmentViewModel.coordinator = self

        let viewController: AttachmentViewController!
        switch kind {
        case .text:
            viewController = AttachmentTextViewController(viewModel: attachmentViewModel)
        case .link:
            viewController = AttachmentLinkViewController(viewModel: attachmentViewModel)
        case .image:
            viewController = AttachmentImageViewController(viewModel: attachmentViewModel)
        case .sketch:
            viewController = AttachmentSketchViewController(viewModel: attachmentViewModel)
        case .location:
            viewController = AttachmentLocationViewController(viewModel: attachmentViewModel)
        case .audio:
            viewController = AttachmentAudioViewController(viewModel: attachmentViewModel)
        case .video:
            viewController = AttachmentVideoViewController(viewModel: attachmentViewModel)
        }

        viewController.delegate = self
        
        self.viewController = viewController
    }
    
    public convenience init (stack: UINavigationController, dependency: Dependency, title: String, url: String) {
        self.init(stack: stack, dependency: dependency, kind: Attachment.Kind.link)
        
        if let linkViewController = self.viewController as? AttachmentLinkViewController {
            linkViewController.defaultTitle = title
            linkViewController.defaultURL = url
        }
    }
}

extension AttachmentCoordinator: AttachmentViewControllerDelegate {
    public func didCancelAttachment() {
        self.delegate?.didCancelAttachment(coordinator: self)
        self.onCancel?()
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.onSaveAttachment?(key)
    }
}
