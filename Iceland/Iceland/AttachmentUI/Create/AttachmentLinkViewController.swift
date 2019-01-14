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

public class AttachmentLinkViewController: AttachmentViewController {
    private var isFirstLoad = true
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isFirstLoad {
            self.showCreateLinkForm()
            self.isFirstLoad = false
        }
    }
    
    private func showCreateLinkForm() {
        let formViewController = ModalFormViewController()
        formViewController.delegate = self
        formViewController.addTextFied(title: "title".localizable, placeHoder: "Please input title".localizable, defaultValue: nil)
        formViewController.addTextFied(title: "link".localizable, placeHoder: "Please input link".localizable, defaultValue: nil)
        
        formViewController.show(from: self)
    }
}

extension AttachmentLinkViewController: ModalFormViewControllerDelegate {
    public func modalFormDidCancel(viewController: ModalFormViewController) {
        viewController.dismiss(animated: true) {
            self.viewModel.dependency?.stop()
        }
    }
    
    public func modalFormDidSave(viewController: ModalFormViewController, formData: [String: Codable]) {
        let jsonEncoder = JSONEncoder()
        do {
            let data = try jsonEncoder.encode(formData)
            let string = String(data: data, encoding: .utf8) ?? ""
            self.viewModel.save(content: string, type: .link, description: "link by user input")
            viewController.dismiss(animated: true) {
                self.viewModel.dependency?.stop()
            }
        } catch {
            log.error(error)
        }
    }
}

private extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}

extension JSONEncoder {
    private struct EncodableWrapper: Encodable {
        let wrapped: Encodable
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try self.wrapped.encode(to: &container)
        }
    }
    
    func encode<Key: Encodable>(_ dictionary: [Key: Encodable]) throws -> Data {
        let wrappedDict = dictionary.mapValues(EncodableWrapper.init(wrapped:))
        return try self.encode(wrappedDict)
    }
}
