//
//  CaptureImageViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Storage

public class CaptureImageViewController: CaptureViewController {
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
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            actionsViewController.addAction(icon: nil, title: "Camera".localizable, action: {
                self.showCamera()
            })
        }
        
        actionsViewController.addAction(icon: nil, title: "Image Library".localizable, action: {
            self.showImageLibrary()
        })
        
        self.present(actionsViewController, animated: true, completion: nil)
    }
}

extension CaptureImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.viewModel.dependency?.stop()
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
