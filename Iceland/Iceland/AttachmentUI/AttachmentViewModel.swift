//
//  AttachmentViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/23.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol AttachmentViewModelDelegate: class {
    func didSaveAttachment(key: String)
    func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String)
}

public class AttachmentViewModel {
    public weak var delegate: AttachmentViewModelDelegate?
    public weak var coordinator: AttachmentCoordinator?
    private var attachmentManager: AttachmentManager
    
    public init(attachmentManager: AttachmentManager) {
        self.attachmentManager = attachmentManager
    }
    
    public func save(content: String,
                     kind: Attachment.Kind,
                     description: String) {
        self.attachmentManager
            .insert(content: content, kind: kind, description: description, complete: { [weak self] key in
                self?.delegate?.didSaveAttachment(key: key)
                self?.coordinator?.stop()
            }, failure: { [weak self] error in
                self?.delegate?.didFailToSave(error: error,
                                              content: content,
                                              kind: kind,
                                              descritpion: description)
            })
    }

}
