//
//  AttachmentVideoViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import Core

public class AttachmentVideoViewController: UIViewController, AttachmentViewControllerProtocol, AttachmentViewModelDelegate {
    public weak var attachmentDelegate: AttachmentViewControllerDelegate?
    
    public var viewModel: AttachmentViewModel!
    
    public var contentView: UIView = UIView()
    
    public var fromView: UIView?
    
    
    let imagePicker = UIImagePickerController()
    public override func viewDidLoad() {
        self.viewModel.delegate = self
        self.view.addSubview(self.contentView)
        self.contentView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [(kUTTypeMovie as String)]
        imagePicker.delegate = self
        self.contentView.addSubview(imagePicker.view)
        imagePicker.view.allSidesAnchors(to: self.contentView, edgeInset: 0)
        
        super.viewDidLoad()
    }
    
    public func didSaveAttachment(key: String) {
        self.attachmentDelegate?.didSaveAttachment(key: key)
        self.viewModel.coordinator?.stop(animated: false)
    }
    
    public func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentVideoViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.viewModel.coordinator?.stop()
        self.attachmentDelegate?.didCancelAttachment()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            self.viewModel.save(content: url.path, kind: .video, description: "video recorded")
        }
    }
}
