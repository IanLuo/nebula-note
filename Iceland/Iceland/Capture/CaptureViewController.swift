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

public protocol CaptureViewControllerDelegate: class {
    func didSaveCapture(attachment: Attachment)
}

public class CaptureViewController: UIViewController {
    private let viewModel: CaptureViewModel
    public weak var delegate: CaptureViewControllerDelegate?
    
    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CaptureViewController: CaptureViewModelDelegate {
    public func didCompleteCapture(attachment: Attachment) {
        self.delegate?.didSaveCapture(attachment: attachment)
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        
    }
}
