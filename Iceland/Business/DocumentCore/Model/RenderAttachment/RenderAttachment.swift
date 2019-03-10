//
//  AttachmentProtocol.swift
//  Business
//
//  Created by ian luo on 2019/2/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class RenderAttachment: NSTextAttachment {
    public var type: String
    public var value: String
    
    private let _manager: AttachmentManager
    private let _attachment: Attachment
    
    public var url: URL?
    
    @objc required public init?(type: String, value: String, manager: AttachmentManager) {
        self._manager = manager
        self.type = type
        self.value = value
        do {
            self._attachment = try self._manager.attachment(with: value)
        } catch {
            log.error("fail to create RenderAttachment with type: \(type), key: \(value)")
            return nil
        }
        self.url = self._attachment.url
        super.init(data: nil, ofType: nil)
        self.bounds = CGRect(origin: .zero, size: .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
        self.createImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createImage() {
        guard let url = self.url else { return }
        switch self.type {
        case Attachment.Kind.sketch.rawValue: fallthrough
        case Attachment.Kind.image.rawValue:
            let size = self.bounds.size
            self.image = UIImage(contentsOfFile: url.path)?.resize(upto: size)
            self.bounds = CGRect(origin: .zero, size: size)
        default: break
        }
    }
}
