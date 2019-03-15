//
//  LinkAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public protocol LinkAttachmentViewDelegate {
    func didTapLink(url: String)
}

public class LinkAttachmentView: UIView, AttachmentViewProtocol {
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
    
    public var url: String?
    
    public func setup(attachment: Attachment) {
        self.addSubview(self.label)
        self.label.allSidesAnchors(to: self, edgeInsets: .init(top: 0, left: 0, bottom: 20, right: 0))
        
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
        } catch {
            label.text = "\(error)"
        }
    }
}
