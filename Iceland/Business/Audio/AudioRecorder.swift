//
//  AudioRecording.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import AVFoundation
import Storage

public enum AudioRecorderError: Error {
    case unauthorized
    case notReady
    case failToGetReady
    case failToCreateRecorder(Error)
    case recordingError(Error)
    case audioEndFailed
}

public protocol AudioRecorderDelegate: class {
    func recorderDidStartRecording()
    func recorderDidStopRecording(url: URL)
    func recorderDidFail(with error: AudioRecorderError)
    func recorderDidMeterChanged(meter: Float)
    func recorderDidPaused()
    func recorderDidReadyToRecord()
}

public class AudioRecorder: NSObject {
    private var _recorder: AVAudioRecorder!
    private let _url: URL
    private let _settings: [String: Any]
    private let _audioSession = AVAudioSession.sharedInstance()
    private var _meteringTimer: Timer?
    
    public var isReady: Bool = false

    public init(url: URL) {
        self._url = url
        self._settings = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                         AVSampleRateKey: 44100,
                         AVNumberOfChannelsKey: 1]
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didInterruptionChange(notification:)), name: AVAudioSession.interruptionNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func startUpdateMetering() {
        self._recorder.isMeteringEnabled = true
        self._meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
            self._recorder.updateMeters()
            let power = self._recorder.averagePower(forChannel: 0)
            self.delegate?.recorderDidMeterChanged(meter: power)
        })
    }
    
    private func _stopUpdateMetering() {
        self._recorder.isMeteringEnabled = false
        self._meteringTimer?.invalidate()
        self._meteringTimer = nil
    }
    
    public func getReady() {
        AVAudioSession.sharedInstance().requestRecordPermission () { [unowned self] allowed in
            if allowed {
                do {
                    try self._audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
                    try self._audioSession.setActive(true)
                    
                    try self._recorder = AVAudioRecorder(url: self._url, settings: self._settings)
                    self._recorder.delegate = self
                    
                    log.info("start recording to: \(self._url)")
                    if self._recorder.prepareToRecord() {
                        self.isReady = true
                        self.delegate?.recorderDidReadyToRecord()
                    } else {
                        self.delegate?.recorderDidFail(with: AudioRecorderError.failToGetReady)
                    }
                } catch {
                    self.delegate?.recorderDidFail(with: AudioRecorderError.failToCreateRecorder(error))
                }
            } else {
                self.delegate?.recorderDidFail(with: AudioRecorderError.unauthorized)
            }
        }
    }
    
    public weak var delegate: AudioRecorderDelegate?
    
    public func delete() {
        if !self._recorder.isRecording {
            self._recorder.deleteRecording()
        }
    }
    
    public func start() {
        if self.isReady {
            self._recorder.record()
            self.delegate?.recorderDidStartRecording()
            self.startUpdateMetering()
        } else {
            self.delegate?.recorderDidFail(with: AudioRecorderError.notReady)
        }
    }
    
    public func pause() {
        if self._recorder.isRecording {
            self._stopUpdateMetering()
            self._recorder.pause()
            self.delegate?.recorderDidPaused()
        }
    }
    
    public func stop() {
        self._stopUpdateMetering()
        self._recorder.stop()
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    @objc func didInterruptionChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
                
        switch type {
        case .began:
            self.delegate?.recorderDidPaused()
        case .ended:
            if let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Interruption Ended - playback should resume
                } else {
                    // Interruption Ended - playback should NOT resume
                }
                self.delegate?.recorderDidStartRecording()
            }
        }
    }
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        self._stopUpdateMetering()
        self.delegate?.recorderDidStopRecording(url: self._url)
        if !flag {
            self.delegate?.recorderDidFail(with: AudioRecorderError.audioEndFailed)
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            self.delegate?.recorderDidFail(with: AudioRecorderError.recordingError(error))
        }
    }
}
