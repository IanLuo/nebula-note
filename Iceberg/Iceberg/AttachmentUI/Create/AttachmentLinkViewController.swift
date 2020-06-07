//
//  AttachmentLinkViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public class AttachmentLinkViewController: ModalFormViewController, AttachmentViewControllerProtocol, AttachmentViewModelDelegate {
    public weak var attachmentDelegate: AttachmentViewControllerDelegate?
    
    public var viewModel: AttachmentViewModel!
    
    public var defaultTitle: String?
    public var defaultURL: String? = "https://"
    
    public override func viewDidLoad() {
        self.showCreateLinkForm()
        super.viewDidLoad()
    }
    
    private func showCreateLinkForm() {
        self.delegate = self
        self.addTextFied(title: L10n.CaptureLink.Title.title, placeHoder: L10n.CaptureLink.Title.placeholder, defaultValue: self.defaultTitle)
        self.addTextFied(title: L10n.CaptureLink.Url.title, placeHoder: L10n.CaptureLink.Url.placeholder, defaultValue: self.defaultURL, keyboardType: .URL)
        self.title = L10n.CaptureLink.title
        
        self.makeFirstTextFieldFirstResponder()
    }
    
    public func didSaveAttachment(key: String) {
        self.attachmentDelegate?.didSaveAttachment(key: key)
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
        self.attachmentDelegate?.didCancelAttachment()
    }
    
    public func modalFormDidSave(viewController: ModalFormViewController, formData: [String: Codable]) {
        let jsonEncoder = JSONEncoder()
        do {
            let linkData: [String: Codable] = [
                OutlineParser.Values.Attachment.Link.keyTitle: formData[L10n.CaptureLink.Title.title]!,
                OutlineParser.Values.Attachment.Link.keyURL: formData[L10n.CaptureLink.Url.title]!
            ]
            let data = try jsonEncoder.encode(linkData)
            let string = String(data: data, encoding: .utf8) ?? ""
            self.viewModel.save(content: string, kind: .link, description: "link by user input")
        } catch {
            log.error(error)
        }
    }
}
