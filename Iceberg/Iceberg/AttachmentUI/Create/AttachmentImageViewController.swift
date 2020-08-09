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
    
    // select from file system(mac) or files(iOS)
    public func showDocumentPicker() {
        let controller = UIDocumentPickerViewController(documentTypes: ["public.image"], in: UIDocumentPickerMode.import)
        controller.delegate = self
        
        self.present(controller, animated: true, completion: nil)
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
        
        self.addAction(icon: Asset.Assets.document.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.ImagePicker.files, action: { vc in
            self.showDocumentPicker()
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

extension AttachmentImageViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true) {
            for url in urls {
                var fileName = url.lastPathComponent
                var newUrl = URL.file(directory: URL.imageCacheURL, name: fileName, extension: "png")
                
                // for mac, just copy the file, but on other platforms, some time copy won't work, so need to save the file manually
                if isMac {
                    fileName = UUID().uuidString
                    newUrl = URL.imageCacheURL.appendingPathComponent(fileName)
                }
                
                newUrl.deletingLastPathComponent().createDirectoryIfNeeded { (error) in
                    if let error = error {
                        print(error)
                    } else {
                        do {
                            if isMac {
                                try FileManager.default.copyItem(at: url, to: newUrl)
                            } else {
                                let image = UIImage(contentsOfFile: url.path)
                                try image?.pngData()?.write(to: newUrl)
                            }
                            self.viewModel.save(content: newUrl.path, kind: .image, description: "pick image")
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

extension AttachmentImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
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
}
