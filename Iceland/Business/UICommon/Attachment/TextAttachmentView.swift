//
//  TextAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class TextAttachmentView: UIView, AttachmentViewProtocol {
    public func size(for width: CGFloat) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: self.label.font]
        let attString = NSAttributedString(string: self.label.text ?? "", attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), nil)
    }
    
    public let label: UILabel = UILabel()
    
    public func setup(attachment: Attachment) {
        self.addSubview(self.label)
        self.label.translatesAutoresizingMaskIntoConstraints = false
        
        self.label.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        self.label.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        self.label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        do {
            label.text = try String(contentsOf: attachment.url)
        } catch {
            label.text = "\(error)"
        }
    }
}
