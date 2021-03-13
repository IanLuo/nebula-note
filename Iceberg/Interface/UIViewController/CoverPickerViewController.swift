//
//  CoverPickerViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class CoverPickerViewController: ActionsViewController {
    public var onSelecedCover: ((UIImage) -> Void)?
    public var onCancel: (() -> Void)?
    
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
    
    // select from file system(mac) or files(iOS)
    public func showDocumentPicker() {
        let controller = UIDocumentPickerViewController(documentTypes: ["public.image"], in: UIDocumentPickerMode.import)
        controller.delegate = self
        
        self.present(controller, animated: true, completion: nil)
    }
    
    public func showImageSourcePicker() {
        self.title = L10n.ImagePicker.add
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            self.addAction(icon: Asset.SFSymbols.camera.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.ImagePicker.camera, action: { vc in
                self.showCamera()
            })
        }
        
        self.addAction(icon: Asset.SFSymbols.photoOnRectangle.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.ImagePicker.library, action: { vc in
            self.showImageLibrary()
        })
        
        self.addAction(icon: Asset.SFSymbols.docText.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.ImagePicker.files, action: { vc in
            self.showDocumentPicker()
        })
    }
}

extension CoverPickerViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true) {
            for url in urls {
                if let image = UIImage(contentsOfFile: url.path) {
                    let resizedImage = image.resize(upto: CGSize(width: 1024, height: 1024))
                    self.dismiss(animated: true) { [unowned self] in
                        self.onSelecedCover?(resizedImage)
                    }
                }
            }
        }
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

extension CoverPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                let resizedImage = image.resize(upto: CGSize(width: 1024, height: 1024))
                self.dismiss(animated: true) { [unowned self] in
                    self.onSelecedCover?(resizedImage)
                }
            }
            
        }
       
    }
}
