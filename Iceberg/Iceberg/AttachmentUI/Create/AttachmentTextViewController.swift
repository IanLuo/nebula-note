//
//  AttachmentTextViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/23.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public class AttachmentTextViewController: ModalFormViewController, AttachmentViewControllerProtocol, AttachmentViewModelDelegate {

    public var viewModel: AttachmentViewModel!
    public weak var attachmentDelegate: AttachmentViewControllerDelegate?
    
    public override func viewDidLoad() {        
        self.viewModel.delegate = self

        self.delegate = self
        self.title = L10n.CaptureText.title
        self.addTextView(title: L10n.CaptureText.Text.title, defaultValue: nil)
        
        super.viewDidLoad()
    }
    
    public func didSaveAttachment(key: String) {
        self.attachmentDelegate?.didSaveAttachment(key: key)
        self.viewModel.coordinator?.stop()
    }
    
    public func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentTextViewController: ModalFormViewControllerDelegate {
    public func validate(formdata: [String : Codable]) -> [String : String] {
        return [:]
    }
    
    public func modalFormDidCancel(viewController: ModalFormViewController) {
        self.viewModel.coordinator?.stop()
        self.attachmentDelegate?.didCancelAttachment()
    }
    
    public func modalFormDidSave(viewController: ModalFormViewController, formData: [String : Codable]) {
        let string = formData[L10n.CaptureText.Text.title] as? String ?? ""
        self.viewModel.save(content: string, kind: .text, description: "user write text")
    }
}
