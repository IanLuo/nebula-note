//
//  AttachmentImageViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Storage

public class AttachmentImageViewController: AttachmentViewController, AttachmentViewModelDelegate {
    let actionsViewController = ActionsViewController()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel.delegate = self
        
        self.setupUI()
        
        self.showImageSourcePicker()
    }
    
    public func showCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    public func showImageLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    private func setupUI() {
     
    }
    
    public func showImageSourcePicker() {
        actionsViewController.title = "Add image".localizable
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            actionsViewController.addAction(icon: nil, title: "Camera".localizable, action: { vc in
                self.showCamera()
            })
        }
        
        actionsViewController.addAction(icon: nil, title: "Image Library".localizable, action: { vc in
            self.showImageLibrary()
        })
        
        actionsViewController.setCancel { viewController in
            self.viewModel.dependency?.stop()
        }
        
        self.view.addSubview(self.actionsViewController.view)
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.viewModel.dependency?.stop()
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
       
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let fileName = UUID().uuidString
            let file = File(File.Folder.temp("image"), fileName: fileName + ".png", createFolderIfNeeded: true).url
            do {
                try image.pngData()?.write(to: file)
                self.viewModel.save(content: file.path, type: .image, description: "image")
            } catch {
                log.error(error)
            }
        }
    }
}
