//
//  AudioPlayer.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import AVFoundation

public enum AudioPlayerError: Error {
    case canNotPlay
    case failToStart(Error)
    case playingError(Error)
    case failToEnd
    case urlIsNotSet
}

public protocol AudioPlayerDelegate: class {
    func playerDidStartPlaying()
    func playerDidReadyToPlay()
    func playerDidStopPlaying()
    func playerDidFail(with error: AudioPlayerError)
    func playerDidPaused()
}

public class AudioPlayer: NSObject {
    public weak var delegate: AudioPlayerDelegate?
    
    public var url: URL?
    
    public var isReady: Bool = false
    
    private var player: AVAudioPlayer!
    
    private let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    public override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didInterruptionChange(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func getReady() {
        do {
            if let url = self.url {
                try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
                try audioSession.setActive(true)
                
                try self.player = AVAudioPlayer(contentsOf: url)
                self.player.delegate = self
                
                if self.player.prepareToPlay() {
                    self.isReady = true
                    self.delegate?.playerDidReadyToPlay()
                } else {
                    self.delegate?.playerDidFail(with: AudioPlayerError.canNotPlay)
                }
            } else {
                self.delegate?.playerDidFail(with: AudioPlayerError.urlIsNotSet)
            }
        } catch {
            self.delegate?.playerDidFail(with: AudioPlayerError.failToStart(error))
        }
    }
    
    public func start() {
        guard isReady else { return }
        if !self.player.isPlaying {
            self.player.play()
            self.delegate?.playerDidStartPlaying()
        }
    }
    
    public func pause() {
        if self.player.isPlaying {
            self.player.pause()
            self.delegate?.playerDidPaused()
        }
    }
    
    public func stop() {
        if self.player.isPlaying {
            self.player.pause()
        }
        
        self.player.stop()
        self.player.currentTime = 0
        self.delegate?.playerDidStopPlaying()
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    @objc func didInterruptionChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch type {
        case .began:
            self.delegate?.playerDidPaused()
        case .ended:
            if let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                } else {
                    // Interruption Ended - playback should NOT resume
                }
                self.delegate?.playerDidStopPlaying()
            }
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            self.delegate?.playerDidFail(with: AudioPlayerError.playingError(error))
        }
    }
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.player.stop()
        self.delegate?.playerDidStopPlaying()
        if !flag {
            self.delegate?.playerDidFail(with: AudioPlayerError.failToEnd)
        }
    }
}
