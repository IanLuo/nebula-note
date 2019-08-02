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
import Business

public class AttachmentVideoViewController: AttachmentViewController, AttachmentViewModelDelegate {
    
    let imagePicker = UIImagePickerController()
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.delegate = self
        
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [(kUTTypeMovie as String)]
        imagePicker.delegate = self
        self.view.addSubview(imagePicker.view)
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
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
        self.delegate?.didCancelAttachment()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            self.viewModel.save(content: url.path, kind: .video, description: "video recorded")
        }
    }
}