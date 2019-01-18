//
//  AttachmentTextViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/23.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class AttachmentTextViewController: AttachmentViewController, AttachmentViewModelDelegate {

    private let formViewController: ModalFormViewController = ModalFormViewController()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewModel.delegate = self

        self.formViewController.delegate = self
        self.formViewController.title = "Write text"
        self.formViewController.addTextView(title: "text".localizable, defaultValue: nil)
        
        self.view.addSubview(self.formViewController.view)
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.viewModel.dependency?.stop()
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentTextViewController: ModalFormViewControllerDelegate {
    public func validate(formdata: [String : Codable]) -> [String : String] {
        return [:]
    }
    
    public func modalFormDidCancel(viewController: ModalFormViewController) {
        self.viewModel.dependency?.stop()
    }
    
    public func modalFormDidSave(viewController: ModalFormViewController, formData: [String : Codable]) {
        let string = formData["text"] as? String ?? ""
        self.viewModel.save(content: string, type: Attachment.AttachmentType.text, description: "user write text")
    }
}
