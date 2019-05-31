//
//  AttachmentProtocol.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface
import UIKit

public class RenderAttachment: NSTextAttachment {
    public var type: String
    public var value: String
    
    private let _manager: AttachmentManager
    private var _attachment: Attachment?
    
    public var url: URL?
    
    @objc required public init?(type: String, value: String, manager: AttachmentManager) {
        self._manager = manager
        self.type = type
        self.value = value
        super.init(data: nil, ofType: nil)
        self.bounds = CGRect(origin: .zero, size: .init(width: 200, height: 60))
        
        self._manager.attachment(with: value, completion: { [weak self] attachment in
            self?._attachment = attachment
            self?.url = attachment.url
            DispatchQueue.main.async {
                self?.image = AttachmentThumbnailView(bounds: self!.bounds, attachment: attachment).snapshot
            }
        }) { error in
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class AttachmentThumbnailView: UIView {
    let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = InterfaceTheme.Color.background3
        return imageView
    }()
    
    let title: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.interactive
        label.textAlignment = .center
        return label
    }()
    
    var attachment: Attachment? {
        didSet {
            
        }
    }
    
    private func createImage(attachment: Attachment) {
        switch attachment.kind {
        case Attachment.Kind.sketch:
            self.title.text = "sketch"
            self.icon.contentMode = .scaleAspectFill
            self.icon.image = UIImage(contentsOfFile: attachment.url.path)?.resize(upto: self.bounds.size)
        case Attachment.Kind.image:
            self.title.text = "image"
            self.icon.contentMode = .scaleAspectFill
            self.icon.image = UIImage(contentsOfFile: attachment.url.path)?.resize(upto: self.bounds.size)
        case .audio:
            self.title.text = "audio"
            self.icon.contentMode = .center
            self.icon.image = Asset.Assets.audio.image.fill(color: InterfaceTheme.Color.descriptive)
        case .video:
            self.title.text = "video"
            self.icon.contentMode = .center
            self.icon.image = Asset.Assets.video.image.fill(color: InterfaceTheme.Color.descriptive)
        case .location:
            self.title.text = "location"
            self.icon.contentMode = .center
            self.icon.image = Asset.Assets.location.image.fill(color: InterfaceTheme.Color.descriptive)
        default: break
        }
    }
    
    init(bounds: CGRect, attachment: Attachment) {
        self.attachment = attachment
        
        super.init(frame: bounds)
        
        self.backgroundColor = InterfaceTheme.Color.background1
        
        let contentView = UIView(frame: self.bounds)
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        
        contentView.backgroundColor = InterfaceTheme.Color.background2
        
        self.addSubview(contentView)
        contentView.addSubview(icon)
        contentView.addSubview(title)
        
        self.icon.size(width: contentView.bounds.height, height: self.bounds.height)
        self.align(to: contentView.bounds, direction: AlignmentDirection.top, inset: 0)
        self.align(to: contentView.bounds, direction: AlignmentDirection.left, inset: 0)
        
        self.title.align(to: self.icon, direction: AlignmentDirection.right, position: AlignmentPosition.head, inset: 0)
        self.title.size(width: contentView.bounds.width - self.icon.bounds.width, height: contentView.bounds.height)
        
        self.createImage(attachment: attachment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
