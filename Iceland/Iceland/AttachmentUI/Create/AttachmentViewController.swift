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
}

public class AttachmentViewController: UIViewController, AttachmentViewModelDelegate {
    public let viewModel: AttachmentViewModel
    public weak var delegate: AttachmentViewControllerDelegate?
    
    public init(viewModel: AttachmentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        self.view.backgroundColor = InterfaceTheme.Color.background1
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        log.error(error)
    }
}
