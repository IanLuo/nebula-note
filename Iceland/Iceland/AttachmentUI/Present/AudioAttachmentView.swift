//
//  AudioAttachmentView.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public class AudioAttachmentView: UIView, AttachmentViewProtocol {
    public var attachment: Attachment!
    
    public func size(for width: CGFloat) -> CGSize {
        return CGSize(width: width, height: width / 2)
    }
    
    public let player: AudioPlayer = AudioPlayer()
    
    private let playerView: AudioPlayerView = AudioPlayerView()
    
    public func setup(attachment: Attachment) {
        self.addSubview(self.playerView)
        self.attachment = attachment
        self.playerView.allSidesAnchors(to: self, edgeInset: 0)
        
        self.playerView.delegate = self
        self.player.delegate = self
        
        self.player.url = attachment.url
        self.player.getReady()
    }
}

extension AudioAttachmentView: AudioPlayerViewDelegate {
    func didTapStart() {
        self.player.start()
    }
    
    func didTapPause() {
        self.player.pause()
    }
    
    func didTapContinue() {
        self.player.continue()
    }
    
    func didTapStop() {
        self.player.stop()
    }
}

extension AudioAttachmentView: AudioPlayerDelegate {
    public func playerDidContinuePlaying() {
        self.playerView.status = .playing
    }
    
    public func playerDidStartPlaying() {
        self.playerView.status = .playing
    }
    
    public func playerDidReadyToPlay() {
        self.playerView.status = .ready
    }
    
    public func playerDidStopPlaying() {
        self.playerView.status = .ready
    }
    
    public func playerDidFail(with error: AudioPlayerError) {
        self.playerView.status = .ready
        log.error(error)
    }
    
    public func playerDidPaused() {
        self.playerView.status = .paused
    }
}

private protocol AudioPlayerViewDelegate: class {
    func didTapStart()
    func didTapPause()
    func didTapContinue()
    func didTapStop()
}

private class AudioPlayerView: UIView {
    public enum Status {
        case ready
        case playing
        case paused
    }
    
    private lazy var playButton: RoundButton = {
        let button = RoundButton()
        button.title = "play".localizable
        button.tapped { button in
            self.delegate?.didTapStart()
        }
        return button
    }()
    
    private lazy var pauseButton: RoundButton = {
        let button = RoundButton()
        button.title = "pause".localizable
        button.tapped { button in
            self.delegate?.didTapStart()
        }
        return button
    }()
    
    private lazy var stopButton: RoundButton = {
        let button = RoundButton()
        button.title = "stop".localizable
        button.tapped { button in
            self.delegate?.didTapStart()
        }
        return button
    }()
    
    private lazy var continueButton: RoundButton = {
        let button = RoundButton()
        button.title = "continue".localizable
        button.tapped { button in
            self.delegate?.didTapStart()
        }
        return button
    }()
    
    fileprivate weak var delegate: AudioPlayerViewDelegate?
    
    fileprivate var status: Status = .ready {
        didSet {
            self.updateUI(status: status)
        }
    }
    
    public init() {
        super.init(frame: .zero)
        
        self.addSubview(self.playButton)
        self.addSubview(self.pauseButton)
        self.addSubview(self.stopButton)
        self.addSubview(self.continueButton)
        
        self.playButton.centerAnchors(position: [.centerX, .centerY], to: self)
        self.playButton.sizeAnchor(width: 60)
        
        self.pauseButton.centerAnchors(position: [.centerX, .centerY], to: self)
        self.stopButton.sizeAnchor(width: 60)
        
        self.continueButton.centerAnchors(position: [.centerX], to: self, multiplier: 0.5)
        self.continueButton.sizeAnchor(width: 60)
        self.continueButton.centerAnchors(position: [.centerY], to: self)
        
        self.stopButton.centerAnchors(position: [.centerX], to: self, multiplier: 1.5)
        self.stopButton.sizeAnchor(width: 60)
        self.stopButton.centerAnchors(position: [.centerY], to: self)
        
        self.updateUI(status: .ready)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateUI(status: Status) {
        self.playButton.isHidden = true
        self.pauseButton.isHidden = true
        self.stopButton.isHidden = true
        self.continueButton.isHidden = true
        
        switch status {
        case .playing:
            self.pauseButton.isHidden = false
        case .paused:
            self.continueButton.isHidden = false
            self.stopButton.isHidden = false
        case .ready:
            self.playButton.isHidden = false
        }
    }
}
