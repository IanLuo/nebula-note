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
    
    public var type: Attachment.AttachmentType
    
    public init(stack: UINavigationController, type: Attachment.AttachmentType) {

        let attachmentViewModel = AttachmentViewModel(attachmentManager: AttachmentManager())
        
        self.type = type
        
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
        
        switch self.type {
        case .sketch:
            from?.present(viewController, animated: true, completion: nil)
            return
        default: break
        }
        
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.view.backgroundColor = .clear
        from?.present(viewController, animated: false, completion: nil)
    }
    
    public override func moveOut(from: UIViewController) {
        switch self.type {
        case .sketch:
            from.dismiss(animated: true, completion: nil)
            return
        default: break
        }
        
        self.viewController?.dismiss(animated: false, completion: nil)
    }
}

extension AttachmentCoordinator: AttachmentViewControllerDelegate {
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.stop()
    }
}
