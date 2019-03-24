//
//  AttachmentProtocol.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface

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
        self.bounds = CGRect(origin: .zero, size: .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
        
        self._manager.attachment(with: value, completion: { attachment in
            self._attachment = attachment
            self.url = attachment.url
            self.image = UIImage(contentsOfFile: attachment.url.path)?.resize(upto: self.bounds.size)
        }) { error in
            
        }
        self.createImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createImage() {
        switch self.type {
        case Attachment.Kind.sketch.rawValue: fallthrough
        case Attachment.Kind.image.rawValue:
            let size = self.bounds.size
            self.bounds = CGRect(origin: .zero, size: size)
        default: break
        }
    }
}
