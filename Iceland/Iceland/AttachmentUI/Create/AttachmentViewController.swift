//
//  CaptureViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol AttachmentViewControllerDelegate: class {
    func didSaveAttachment(key: String)
    func didCancelAttachment()
}

public class AttachmentViewController: UIViewController {
    public let viewModel: AttachmentViewModel
    public weak var delegate: AttachmentViewControllerDelegate?
    
    private let _transition: UIViewControllerTransitioningDelegate
    
    public init(viewModel: AttachmentViewModel) {
        self.viewModel = viewModel
        self._transition = FadeBackgroundTransition(animator: MoveInAnimtor())
        
        super.init(nibName: nil, bundle: nil)
        
        self.transitioningDelegate = self._transition
        self.modalPresentationStyle = .overCurrentContext
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
