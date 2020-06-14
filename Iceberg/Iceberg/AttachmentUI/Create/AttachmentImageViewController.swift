//
//  AttachmentImageViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public class AttachmentImageViewController: ActionsViewController, AttachmentViewControllerProtocol {
    public weak var attachmentDelegate: AttachmentViewControllerDelegate?
    
    public var viewModel: AttachmentViewModel!
    
    public override func viewDidLoad() {
        self.showImageSourcePicker()
        super.viewDidLoad()
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
    
    public func showImageSourcePicker() {
        self.title = L10n.ImagePicker.add
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            self.addAction(icon: Asset.Assets.camera.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.ImagePicker.camera, action: { vc in
                self.showCamera()
            })
        }
        
        self.addAction(icon: Asset.Assets.imageLibrary.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.ImagePicker.library, action: { vc in
            self.showImageLibrary()
        })
        
        self.setCancel { viewController in
            self.viewModel.coordinator?.stop()
            self.attachmentDelegate?.didCancelAttachment()
        }
    }
    
    public func didSaveAttachment(key: String) {
        self.viewModel.coordinator?.stop()
        self.attachmentDelegate?.didSaveAttachment(key: key)
    }
    
    public func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String) {
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
            let file = URL.file(directory: URL.imageCacheURL, name: fileName, extension: "jpg")
            file.deletingLastPathComponent().createDirectoryIfNeeded { error in
                if let error = error {
                    log.error(error)
                } else {
                    do {
                        try image.jpegData(compressionQuality: 1.0)?.write(to: file)
                        self.viewModel.save(content: file.path, kind: .image, description: "pick image")
                    } catch {
                        log.error(error)
                    }
                }
            }
        }
    }
}
