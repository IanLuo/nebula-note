//
//  CaptureTableCellModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public class CaptureTableCellModel {
    private let attachment: Attachment
    
    public var url: URL {
        return attachment.url
    }
    
    public init(attacment: Attachment) {
        self.attachment = attacment
    }
    
    public lazy var attachmentView: AttachmentViewType = AttachmentViewFactory.create(attachment: self.attachment)
}
