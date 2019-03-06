//
//  AttachmentLinkViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class AttachmentLinkViewController: AttachmentViewController, AttachmentViewModelDelegate {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showCreateLinkForm()
        
        self.viewModel.delegate = self
    }
    
    let formViewController = ModalFormViewController()
    private func showCreateLinkForm() {
        formViewController.delegate = self
        formViewController.addTextFied(title: "title".localizable, placeHoder: "Please input title".localizable, defaultValue: nil)
        formViewController.addTextFied(title: "link".localizable, placeHoder: "Please input link".localizable, defaultValue: nil, keyboardType: .URL)
        formViewController.title = "Create link".localizable

        self.view.addSubview(formViewController.view)
    }
    
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
        self.viewModel.coordinator?.stop()
    }
    
    public func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentLinkViewController: ModalFormViewControllerDelegate {
    public func validate(formdata: [String : Codable]) -> [String : String] {
        return [:]
    }
    
    public func modalFormDidCancel(viewController: ModalFormViewController) {
        self.viewModel.coordinator?.stop()
    }
    
    public func modalFormDidSave(viewController: ModalFormViewController, formData: [String: Codable]) {
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(formData)
            let string = String(data: data, encoding: .utf8) ?? ""
            self.viewModel.save(content: string, kind: .link, description: "link by user input")
            viewController.dismiss(animated: true) {
                self.viewModel.coordinator?.stop()
            }
        } catch {
            log.error(error)
        }
    }
}
