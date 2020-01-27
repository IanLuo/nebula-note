//
//  VideoAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import AVKit

public class VideoAttachmentView: UIView, AttachmentViewProtocol {
    public var attachment: Attachment!
    
    public func size(for width: CGFloat) -> CGSize {
        return CGSize(width: width, height: width)
    }
    
    public var player: AVPlayerViewController!
    
    public func setup(attachment: Attachment) {
        self.player = AVPlayerViewController()
        
        self.addSubview(self.player.view)
        self.player.view.allSidesAnchors(to: self, edgeInset: 0)
        
        self.player.player = AVPlayer(url: attachment.url)
        
        self.attachment = attachment
    }
}
