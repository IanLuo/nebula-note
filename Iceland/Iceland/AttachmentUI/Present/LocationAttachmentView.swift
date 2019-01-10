//
//  LocationAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class LocationAttachmentView: UIView, AttachmentViewProtocol {
    public func size(for width: CGFloat) -> CGSize {
        return CGSize(width: width, height: width / 2)
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
