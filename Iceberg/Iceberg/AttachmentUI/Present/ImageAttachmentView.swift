//
//  ImageAttachment.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class ImageAttachmentView: UIView, AttachmentViewProtocol {
    public var attachment: Attachment!
    
    public func size(for width: CGFloat) -> CGSize {
        return self.imageView.image?.size.aspectFitWidthScale(for: width) ?? CGSize(width: width, height: width)
    }
    
    private let imageView: UIImageView = UIImageView()
    
    public func setup(attachment: Attachment) {
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.allSidesAnchors(to: self, edgeInset: 0)
        
        self.attachment = attachment
        self.updateUI(attachment)
    }
    
    private func updateUI(_ attachment: Attachment) {
        self.imageView.image = UIImage(contentsOfFile: attachment.url.path)
    }
}
