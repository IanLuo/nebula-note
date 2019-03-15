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
import Interface

public class AttachmentImageViewController: AttachmentViewController, AttachmentViewModelDelegate, TransitionProtocol {
    public var contentView: UIView {
        return self.actionsViewController.contentView
    }
    
    public var fromView: UIView?
    
    let actionsViewController = ActionsViewController()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel.delegate = self
        
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
    
    public func showImageSourcePicker() {
        actionsViewController.title = "Add image".localizable
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            actionsViewController.addAction(icon: Asset.Assets.camera.image.withRenderingMode(.alwaysTemplate), title: "Camera".localizable, action: { vc in
                self.showCamera()
            })
        }
        
        actionsViewController.addAction(icon: Asset.Assets.imageLibrary.image.withRenderingMode(.alwaysTemplate), title: "Image Library".localizable, action: { vc in
            self.showImageLibrary()
        })
        
        actionsViewController.setCancel { viewController in
            self.viewModel.coordinator?.stop()
            self.delegate?.didCancelAttachment()
        }
        
        self.view.addSubview(self.actionsViewController.view)
        
        self.actionsViewController.view.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.viewModel.coordinator?.stop()
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
            let file = URL.file(directory: URL.imageCacheURL, name: fileName, extension: "png")
            file.deletingLastPathComponent().createDirectorysIfNeeded()
            do {
                try image.pngData()?.write(to: file)
                self.viewModel.save(content: file.path, kind: .image, description: "pick image")
            } catch {
                log.error(error)
            }
        }
    }
}
