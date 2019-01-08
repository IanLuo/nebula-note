//
//  AudioRecording.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public enum AudioRecorderError: Error {
    
}

public protocol AudioRecorderDelegate: class {
    func recorderDidStartRecording()
    func recorderDidStopRecording(url: URL)
    func recorderDidFail(with error: Error)
    func recorderDidMeterChanged(meter: Float)
    func recorderDidPaused()
}

public class AudioRecorder {
    public init() {}
    
    public weak var delegate: AudioRecorderDelegate?
    
    public func start() {
        
    }
    
    public func pause() {
        
    }
    
    public func stop() {
        
    }
}
