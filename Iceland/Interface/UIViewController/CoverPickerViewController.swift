//
//  CoverPickerViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class CoverPickerViewController: UIImagePickerController {
    public var onSelecedCover: ((UIImage) -> Void)?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.sourceType = .photoLibrary
        self.delegate = self
    }
}

extension CoverPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            let resizedImage = image.resize(upto: CGSize(width: 1024, height: 1024))
            self.onSelecedCover?(resizedImage)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}
