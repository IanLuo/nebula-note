//
//  CaptureAudioViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class CaptureAudioViewController: CaptureViewController {
    private let recorder: AudioRecorder = AudioRecorder()
    private let player: AudioPlayer = AudioPlayer()
    private lazy var recorderView: RecorderView = {
        let recorderView = RecorderView()
        recorderView.delegate = self
        return recorderView
    }()
    
    private lazy var actionsViewController = ActionsViewController()

    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private var isFirstLoad: Bool = true
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            self.showRecorder()
            self.isFirstLoad = false
        }
    }
    
    public func showRecorder() {
        self.actionsViewController.accessoryView = self.recorderView
        
        self.recorderView.translatesAutoresizingMaskIntoConstraints = false
        self.recorderView.sizeAnchor(width: UIScreen.main.bounds.width, height: 200)
        if let superview = self.recorderView.superview {
            self.recorderView.allSidesAnchors(to: superview, edgeInset: 0)
        }
        
        self.actionsViewController.addCancel { viewController in
            // 两个动画同时开始
            viewController.dismiss(animated: true, completion: {})
            self.viewModel.dependency?.stop()
        }
        
        self.actionsViewController.modalPresentationStyle = .overCurrentContext
        self.present(actionsViewController, animated: true, completion: nil)
    }
}

extension CaptureAudioViewController: AudioRecorderDelegate {
    public func recorderDidStartRecording() {
        
    }
    
    public func recorderDidStopRecording(url: URL) {
        
    }
    
    public func recorderDidFail(with error: Error) {
        
    }
    
    public func recorderDidMeterChanged(meter: Float) {
        
    }
    
    public func recorderDidPaused() {
        
    }
}

extension CaptureAudioViewController: AudioPlayerDelegate {
    public func playerDidStartPlaying() {
        
    }
    
    public func playerDidStopPlaying() {
        
    }
    
    public func playerDidFail(with error: Error) {
        
    }
    
    public func playerDidPaused() {
        
    }
}

extension CaptureAudioViewController: RecorderViewDelegate {
    public func tappedPlaying() {
        
    }
    
    public func tappedStart() {
        
    }
    
    public func tappedPaused() {
        
    }
    
    public func tappedStop() {
        
    }
    
    public func tappedSave() {
        
    }
}

public protocol RecorderViewDelegate: class {
    func tappedStart()
    func tappedPaused()
    func tappedStop()
    func tappedSave()
    func tappedPlaying()
}

public class RecorderView: UIView {
    public enum Status {
        case initing
        case ready
        case recording
        case recordingPaused
        case stopped
        case playing
    }
    
    public weak var delegate: RecorderViewDelegate?
    
    public var status: Status = .initing
    
    public init() {
        super.init(frame: .zero)
        
        self.backgroundColor = InterfaceTheme.Color.background2
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
