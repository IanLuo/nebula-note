//
//  TextAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public class TextAttachmentView: UIView, AttachmentViewProtocol {
    public var attachment: Attachment!
    
    public func size(for width: CGFloat) -> CGSize {
        return self.label.text?.boundingBox(for: width, font: self.label.font).heigher(by: 20) ?? .zero
    }
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.body
        label.textColor = InterfaceTheme.Color.interactive
        label.numberOfLines = 0
        return label
    }()
    
    public func setup(attachment: Attachment) {
        self.addSubview(self.label)
        
        self.label.allSidesAnchors(to: self, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        self.attachment = attachment
        
        self.updateUI(attachment: attachment)
    }
    
    private func updateUI(attachment: Attachment) {
        
        do {
            label.text = try String(contentsOf: attachment.url)
        } catch {
            label.text = "\(error)"
        }
    }
}
