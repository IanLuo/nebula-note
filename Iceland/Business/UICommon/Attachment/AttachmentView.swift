//
//  AttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol AttachmentViewProtocol {
    func setup(attachment: Attachment)
    func size(for width: CGFloat) -> CGSize
}

public typealias AttachmentViewType = AttachmentViewProtocol & UIView

public class AttachmentViewFactory {
    public static func create(attachment: Attachment) -> AttachmentViewType {
        var attachmentView: AttachmentViewType?
        switch attachment.type {
        case .image:
            attachmentView = ImageAttachmentView()
        case .text:
            attachmentView = TextAttachmentView()
        case .audio:
            attachmentView = AudioAttachmentView()
        case .link:
            attachmentView = LinkAttachmentView()
        case .location:
            attachmentView = LocationAttachmentView()
        case .sketch:
            attachmentView = SketchAttachmentView()
        case .video:
            attachmentView = VideoAttachmentView()
        }
        
        attachmentView?.setup(attachment: attachment)
        return attachmentView!
    }
}
