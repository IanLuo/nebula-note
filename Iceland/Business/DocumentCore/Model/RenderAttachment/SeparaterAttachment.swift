//
//  SeparatorAttachment.swift
//  Business
//
//  Created by ian luo on 2019/2/20.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

@objc public class SeparaterAttachment: NSTextAttachment {
    public required init() {
        super.init(data: nil, ofType: nil)
        
        let image = UIImage.create(with: OutlineTheme.seperatorStyle,
                                   size: CGSize(width: UIScreen.main.bounds.width - Layout.edgeInsets.left - Layout.edgeInsets.right,
                                                height: 1))
        self.image = image
        self.bounds = CGRect(origin: .zero, size: image.size)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
