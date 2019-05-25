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
import Interface

public class AttachmentLinkViewController: AttachmentViewController, AttachmentViewModelDelegate {
    public var defaultTitle: String?
    public var defaultURL: String?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.showCreateLinkForm()
        
        self.viewModel.delegate = self
    }
    
    let formViewController = ModalFormViewController()
    private func showCreateLinkForm() {
        formViewController.delegate = self
        formViewController.addTextFied(title: L10n.CaptureLink.Title.title, placeHoder: L10n.CaptureLink.Title.placeholder, defaultValue: self.defaultTitle)
        formViewController.addTextFied(title: L10n.CaptureLink.Url.title, placeHoder: L10n.CaptureLink.Url.placeholder, defaultValue: self.defaultURL, keyboardType: .URL)
        formViewController.title = L10n.CaptureLink.title

        self.view.addSubview(formViewController.view)
        self.formViewController.didMove(toParent: self)
        self.formViewController.view.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
        
        self.formViewController.makeFirstTextFieldFirstResponder()
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
        self.delegate?.didCancelAttachment()
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
            viewController.dismiss(animated: true) {
                self.viewModel.coordinator?.stop()
            }
        } catch {
            log.error(error)
        }
    }
}
