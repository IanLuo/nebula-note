//
//  CaptureViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/23.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol CaptureViewModelDelegate: class {
    func didCompleteCapture(attachment: Attachment)
    func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String)
}

public class CaptureViewModel {
    private let service: CaptureServiceProtocol
    public weak var delegate: CaptureViewModelDelegate?
    
    public init(service: CaptureServiceProtocol) {
        self.service = service
    }
    
    public func save(content: String,
                     type: Attachment.AttachmentType,
                     description: String) {
        self.service
            .save(content: content, type: type, description: description, completion: { [weak self] attachment in
                self?.delegate?.didCompleteCapture(attachment: attachment)
            }, failure: { [weak self] error in
                self?.delegate?.didFailToSave(error: error,
                                              content: content,
                                              type: type,
                                              descritpion: description)
            })
    }

}
