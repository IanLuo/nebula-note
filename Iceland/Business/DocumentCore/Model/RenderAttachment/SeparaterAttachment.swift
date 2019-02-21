//
//  SeparatorAttachment.swift
//  Business
//
//  Created by ian luo on 2019/2/20.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class SeparaterAttachment: NSTextAttachment, RenderAttachmentProtocol {
    public var rawString: String
    
    public var value: String = ""
    
    public var type: String = ""
    
    public required init(rawString: String, ranges: [String : NSRange]) {
        self.rawString = rawString
        super.init(data: nil, ofType: nil)
        
        let image = UIImage.create(with: InterfaceTheme.Color.background2, size: CGSize(width: UIScreen.main.bounds.width, height: 1))
        self.image = image
        self.bounds = CGRect(origin: .zero, size: image.size)
    }
    
    public func serialize() -> String {
        return rawString
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
