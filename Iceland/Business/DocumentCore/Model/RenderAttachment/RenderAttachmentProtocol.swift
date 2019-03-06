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
    
    public var url: URL? {
        didSet {
            if url != nil {
                self.createImage()
            }
        }
    }
    
    @objc required public init(type: String, value: String) {
        self.type = type
        self.value = value
        self.url = URL(string: value)
        super.init(data: nil, ofType: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createImage() {
        switch self.type {
        case Attachment.Kind.image.rawValue:
            let size = CGSize(width: UIScreen.main.bounds.width,
                              height: UIScreen.main.bounds.width)
            self.image = UIImage(contentsOfFile: self.url?.path ?? "")?.resize(upto: size)
            self.bounds = CGRect(origin: .zero, size: size)
        default: break
        }
    }
}
