//
//  AudioPlayer.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public enum AudioPlayerError: Error {
    
}

public protocol AudioPlayerDelegate: class {
    func playerDidStartPlaying()
    func playerDidStopPlaying()
    func playerDidFail(with error: Error)
    func playerDidPaused()
}

public class AudioPlayer {
    public weak var delegate: AudioPlayerDelegate?
    
    public var url: URL?
    
    public init() {}
    
    public func start() {
        
    }
    
    public func pause() {
        
    }
    
    public func stop() {
        
    }
}
