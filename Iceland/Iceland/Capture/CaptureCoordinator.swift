//
//  CaptureCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2019/3/6.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol CaptureCoordinatorDelegate: class {
    func didSelect(attachmentKind: Attachment.Kind, coordinator: CaptureCoordinator)
    func didCancel(coordinator: CaptureCoordinator)
}

public class CaptureCoordinator: Coordinator {
    public weak var delegate: CaptureCoordinatorDelegate?
    private let captureService = CaptureService()
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        
        let viewController = CaptureViewController()
        viewController.coordinator = self
        viewController.delegate = self
        self.viewController = viewController
    }
    
    public func addAttachment(attachmentId: String) {
        self.captureService.save(key: attachmentId)
    }
}

extension CaptureCoordinator: CaptureViewControllerDelegate {
    public func didSelect(attachmentKind: Attachment.Kind) {
        self.delegate?.didSelect(attachmentKind: attachmentKind, coordinator: self)
    }
    
    public func didCancel() {
        self.delegate?.didCancel(coordinator: self)
    }
}
