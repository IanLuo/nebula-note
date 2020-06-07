//
//  AttachmentCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage
import Core

public protocol AttachmentCoordinatorDelegate: class {
    func didSaveAttachment(key: String)
    func didCancelAttachment(coordinator: AttachmentCoordinator)
}

public class AttachmentCoordinator: Coordinator {
    public weak var delegate: AttachmentCoordinatorDelegate?
    
    public var onSaveAttachment: ((String) -> Void)?
    public var onCancel: (() -> Void)?
    
    public var kind: Attachment.Kind
    
    public init(stack: UINavigationController, dependency: Dependency, kind: Attachment.Kind, at: UIView?, location: CGPoint?) {

        let attachmentViewModel = AttachmentViewModel(attachmentManager: dependency.attachmentManager)
        
        self.kind = kind
        
        super.init(stack: stack, dependency: dependency)
        
        attachmentViewModel.coordinator = self

        var viewController: AttachmentViewControllerProtocol!
        switch kind {
        case .text:
            viewController = AttachmentTextViewController()
        case .link:
            viewController = AttachmentLinkViewController()
        case .image:
            viewController = AttachmentImageViewController()
        case .sketch:
            viewController = AttachmentSketchViewController()
        case .location:
            viewController = AttachmentLocationViewController()
        case .audio:
            viewController = AttachmentAudioViewController()
        case .video:
            viewController = AttachmentVideoViewController()
        }

        viewController.attachmentDelegate = self
        viewController.viewModel = attachmentViewModel
        attachmentViewModel.delegate = viewController
        self.viewController = viewController
        
        self.fromLocation = location
        self.fromView = at
        
    }
    
    public convenience init (stack: UINavigationController, dependency: Dependency, title: String, url: String, at: UIView?, location: CGPoint?) {
        self.init(stack: stack, dependency: dependency, kind: Attachment.Kind.link, at: at, location: location)
        
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
