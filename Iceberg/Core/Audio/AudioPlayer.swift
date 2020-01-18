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
    func playerDidContinuePlaying()
    func playerDidReadyToPlay()
    func playerDidStopPlaying()
    func playerDidFail(with error: AudioPlayerError)
    func playerDidPaused()
}

public class AudioPlayer: NSObject {
    public weak var delegate: AudioPlayerDelegate?
    
    public var url: URL?
    
    public var isReady: Bool = false
    
    private var _player: AVAudioPlayer!
    
    private let _audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
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
                try _audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
                try _audioSession.setActive(true)
                
                try self._player = AVAudioPlayer(contentsOf: url)
                self._player.delegate = self
                
                if self._player.prepareToPlay() {
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
        if !self._player.isPlaying {
            self._player.play()
            self.delegate?.playerDidStartPlaying()
        }
    }
    
    public func `continue`() {
        guard isReady else { return }

        self._player.play()
        self.delegate?.playerDidContinuePlaying()
    }
    
    public func pause() {
        if self._player.isPlaying {
            self._player.pause()
            self.delegate?.playerDidPaused()
        }
    }
    
    public func stop() {
        if self._player.isPlaying {
            self._player.pause()
        }
        
        self._player.stop()
        self._player.currentTime = 0
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
        self._player.stop()
        self.delegate?.playerDidStopPlaying()
        if !flag {
            self.delegate?.playerDidFail(with: AudioPlayerError.failToEnd)
        }
    }
}
