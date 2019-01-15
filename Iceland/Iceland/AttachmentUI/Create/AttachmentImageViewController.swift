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

public class AttachmentImageViewController: AttachmentViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
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
    
    private var isFirstLoad = true
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            self.showImageSourcePicker()
            self.isFirstLoad = false
        }
    }
    
    public func showImageSourcePicker() {
        let actionsViewController = ActionsViewController()
        actionsViewController.title = "Add image".localizable
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            actionsViewController.addAction(icon: nil, title: "Camera".localizable, action: { vc in
                vc.dismiss(animated: true, completion: {
                    self.showCamera()
                })
            })
        }
        
        actionsViewController.addAction(icon: nil, title: "Image Library".localizable, action: { vc in
            vc.dismiss(animated: true, completion: {
                self.showImageLibrary()
            })
        })
        
        actionsViewController.setCancel { viewController in
            // 两个动画同时开始
            viewController.dismiss(animated: true, completion: {})
            self.viewModel.dependency?.stop()
        }
        
        actionsViewController.modalPresentationStyle = .overCurrentContext
        self.present(actionsViewController, animated: true, completion: nil)
    }
}

extension AttachmentImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.viewModel.dependency?.stop()
        }
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
