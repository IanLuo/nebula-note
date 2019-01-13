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

public class AttachmentVideoViewController: AttachmentViewController {
    
    private var isFirstLoad = true
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstLoad {
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .camera
            imagePicker.mediaTypes = [(kUTTypeMovie as String)]
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
            isFirstLoad = false
        }
    }
}

extension AttachmentVideoViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.viewModel.dependency?.stop()
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            self.viewModel.save(content: url.path, type: .video, description: "video recorded")
        }
    }
}
