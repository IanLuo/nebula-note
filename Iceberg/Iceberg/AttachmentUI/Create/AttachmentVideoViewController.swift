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
import Interface

public class AttachmentVideoViewController: ActionsViewController, AttachmentViewControllerProtocol, AttachmentViewModelDelegate {
    public weak var attachmentDelegate: AttachmentViewControllerDelegate?
    
    public var viewModel: AttachmentViewModel!
    
    public override func viewDidLoad() {
        self.showImageSourcePicker()
        super.viewDidLoad()
    }
    
    public func showCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [(kUTTypeMovie as String)]
        imagePicker.delegate = self
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    public func showImageLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [(kUTTypeMovie as String)]
        imagePicker.delegate = self
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // select from file system(mac) or files(iOS)
    public func showDocumentPicker() {
        let controller = UIDocumentPickerViewController(documentTypes: ["public.movie"], in: UIDocumentPickerMode.import)
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
        
        self.addAction(icon: Asset.SFSymbols.doc.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.ImagePicker.files, action: { vc in
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

extension AttachmentVideoViewController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true) {
            for url in urls {
                var fileName = url.lastPathComponent
                var newUrl = URL.file(directory: URL.imageCacheURL, name: fileName, extension: url.pathExtension)
                
                // for mac, just copy the file, but on other platforms, some time copy won't work, so need to save the file manually
                if isMac {
                    fileName = UUID().uuidString
                    newUrl = URL.imageCacheURL.appendingPathComponent(fileName).appendingPathExtension(url.pathExtension)
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
                            self.viewModel.save(content: newUrl.path, kind: .video, description: "pick video")
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
