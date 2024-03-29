//
//  LinkAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public protocol LinkAttachmentViewDelegate {
    func didTapLink(url: String)
}

public class LinkAttachmentView: UIView, AttachmentViewProtocol {
    public var attachment: Attachment!
    
    public func size(for width: CGFloat) -> CGSize {
        return self.label.sizeThatFits(CGSize(width: width - 20, height: CGFloat.greatestFiniteMagnitude))
    }
    
    public let label: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.body
        label.textColor = InterfaceTheme.Color.interactive
        label.numberOfLines = 0
        return label
    }()
    
    public var url: String?
    
    public func setup(attachment: Attachment) {
        self.addSubview(self.label)
        self.label.allSidesAnchors(to: self, edgeInsets: .init(top: 0, left: 10, bottom: 0, right: -10))
        
        self.attachment = attachment
        self.updateUI(attachment: attachment)
    }
    
    private func updateUI(attachment: Attachment) {
        do {
            let jsonDecoder = JSONDecoder()
            let data = try Data(contentsOf: attachment.url)
            let dic = try jsonDecoder.decode(Dictionary<String, String>.self, from: data)
            label.attributedText = NSAttributedString(string: dic["title"] ?? "bad data",
                                                      attributes: [NSAttributedString.Key.underlineStyle : 1,
                                                                   NSAttributedString.Key.underlineColor : InterfaceTheme.Color.interactive,
                                                                   NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive])
            self.url = dic["link"]
            if label.text?.count == 0 {
                label.text = "Empty"
            }
        } catch {
            label.text = "\(error)"
        }
    }
}
