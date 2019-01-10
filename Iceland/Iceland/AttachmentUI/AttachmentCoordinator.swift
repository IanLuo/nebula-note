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
}

public class AttachmentCoordinator: Coordinator {
    public weak var delegate: AttachmentCoordinatorDelegate?
    
    public init(stack: UINavigationController, type: Attachment.AttachmentType) {

        let attachmentViewModel = AttachmentViewModel(attachmentManager: AttachmentManager())
        
        super.init(stack: stack)
        
        attachmentViewModel.dependency = self

        let viewController: AttachmentViewController!
        switch type {
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
    
    public override func moveIn(from: UIViewController?) {
        guard let viewController = self.viewController else { return }
        viewController.modalPresentationStyle = .overCurrentContext
        from?.present(viewController, animated: false, completion: nil)
    }
    
    public override func moveOut(from: UIViewController) {
        (self.viewController as? AttachmentViewController)?.animateHideBackground { [weak self] in
            self?.viewController?.dismiss(animated: false, completion: nil)
        }
    }
}

extension AttachmentCoordinator: AttachmentViewControllerDelegate {
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.stop()
    }
}
