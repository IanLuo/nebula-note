//
//  AudioAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import AVKit

public class AudioAttachmentView: UIView, AttachmentViewProtocol {
    public var attachment: Attachment!
    
    public func size(for width: CGFloat) -> CGSize {
        return CGSize(width: width, height: 180)
    }
    
    public var playerController: AVPlayerViewController!
    
    public func setup(attachment: Attachment) {
        self.playerController = AVPlayerViewController()
        self.playerController.view.backgroundColor = InterfaceTheme.Color.background2
        self.addSubview(self.playerController.view)
        self.playerController.view.allSidesAnchors(to: self, edgeInset: 0)
        
        self.playerController.player = AVPlayer(url: attachment.url)
        
        self.attachment = attachment
    }
}
