//
//  AttachmentAudioViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public class AttachmentAudioViewController: ActionsViewController, AttachmentViewControllerProtocol, AttachmentViewModelDelegate {
    public weak var attachmentDelegate: AttachmentViewControllerDelegate?
    
    public var viewModel: AttachmentViewModel!
    
    private lazy var recorder: AudioRecorder = {
        let _ = URL.audioCacheURL.createDirectoryIfNeeded()
        let recorder = AudioRecorder(url: URL.file(directory: URL.audioCacheURL, name: UUID().uuidString, extension: "m4a"))
        recorder.delegate = self
        return recorder
    }()
    
    private lazy var player: AudioPlayer = {
        let player = AudioPlayer()
        player.delegate = self
        return player
    }()
    
    private lazy var recorderView: RecorderView = {
        let recorderView = RecorderView()
        recorderView.delegate = self
        return recorderView
    }()
    
    public override func viewDidLoad() {
        self.title = L10n.Document.Record.title
        
        self.viewModel.delegate = self
        
        self.recorderView.status = .initing
        self.recorder.getReady()
        
        self.showRecorder()
        super.viewDidLoad()
    }
    
    public func showRecorder() {
        self.accessoryView = self.recorderView
        
        self.recorderView.translatesAutoresizingMaskIntoConstraints = false
        self.recorderView.sizeAnchor(width: UIScreen.main.bounds.width, height: 200)
        if let superview = self.recorderView.superview {
            self.recorderView.allSidesAnchors(to: superview, edgeInset: 0)
        }
        
        self.setCancel { viewController in
            self.viewModel.coordinator?.stop()
            self.attachmentDelegate?.didCancelAttachment()
        }
    }
    
    public func didSaveAttachment(key: String) {
        self.attachmentDelegate?.didSaveAttachment(key: key)
        self.viewModel.coordinator?.stop(animated: false)
    }
    
    public func didFailToSave(error: Error, content: String, kind: Attachment.Kind, descritpion: String) {
        log.error(error)
    }
}

extension AttachmentAudioViewController: AudioRecorderDelegate {
    public func recorderDidReadyToRecord() {
        self.recorderView.status = .readyToRecord
    }
    
    public func recorderDidStartRecording() {
        self.recorderView.status = .recording
        
        // 移除保存按钮
        self.removeAction(with: L10n.General.Button.Title.save)
    }
    
    public func recorderDidStopRecording(url: URL) {
        self.recorderView.status = .stopped
        
        // 显示保存按钮
        self.addAction(icon: nil, title: L10n.General.Button.Title.save, style: .highlight) { [unowned self] (actionController) in
            self.viewModel.save(content: url.path, kind: .audio, description: "recorded voice")
        }
        
        // 初始化播放器
        self.player.url = url
        self.player.getReady()
    }
    
    public func recorderDidFail(with error: AudioRecorderError) {
        switch error {
        case .unauthorized:
            log.error(error)
        default:
            log.error(error)
        }
    }
    
    public func recorderDidMeterChanged(meter: Float) {
        // TODO: metring did change
        log.info("metering: \(meter)")
    }
    
    public func recorderDidPaused() {
        self.recorderView.status = .recordingPaused
    }
}

extension AttachmentAudioViewController: AudioPlayerDelegate {
    public func playerDidContinuePlaying() {
        
    }
    
    public func playerDidReadyToPlay() {
        self.recorderView.status = .readyToPlay
    }
    
    public func playerDidFail(with error: AudioPlayerError) {
        log.error(error)
    }
    
    public func playerDidStartPlaying() {
        self.recorderView.status = .playing
    }
    
    public func playerDidStopPlaying() {
        self.recorderView.status = .readyToPlay
    }
    
    public func playerDidPaused() {
        
    }
}

extension AttachmentAudioViewController: RecorderViewDelegate {
    public func tappedPlay() {
        self.player.start()
    }
    
    public func tappedPause() {
        self.recorder.pause()
    }
    
    public func tappedStopPlaying() {
        self.player.stop()
    }
    
    public func tappedStopRecording() {
        self.recorder.stop()
    }
    
    public func tappedRecord() {
        self.recorder.start()
    }
    
    public func tappedResumRecording() {
        self.recorder.start()
    }
}

public protocol RecorderViewDelegate: class {
    func tappedPause()
    func tappedPlay()
    func tappedStopPlaying()
    func tappedStopRecording()
    func tappedRecord()
    func tappedResumRecording()
}

public class RecorderView: UIView {
    public enum Status {
        case initing
        case readyToRecord
        case recording
        case recordingPaused
        case stopped
        case readyToPlay
        case playing
    }
    
    public weak var delegate: RecorderViewDelegate?
    
    public var status: Status = .initing {
        didSet {
            DispatchQueue.runOnMainQueueSafely {
                self.updateUI()
            }
        }
    }
    
    private lazy var playButton: RoundButton = {
        let button = RoundButton()
        button.title = L10n.Audio.Player.play
        button.setIcon(Asset.SFSymbols.play.image.fill(color: InterfaceTheme.Color.spotlight), for: .normal)
        button.tapped { _ in
            self.delegate?.tappedPlay()
        }
        return button
    }()
    
    private lazy var recordButton: RoundButton = {
        let button = RoundButton()
        button.title = L10n.Audio.Recorder.start
        button.setIcon(Asset.SFSymbols.recordCircle.image.fill(color: InterfaceTheme.Color.warning), for: .normal)
        button.tapped { _ in
            self.delegate?.tappedRecord()
        }
        return button
    }()
    
    private lazy var pauseRecordingButton: RoundButton = {
        let button = RoundButton()
        button.title = L10n.Audio.Recorder.pause
        button.setIcon(Asset.SFSymbols.pause.image.fill(color: InterfaceTheme.Color.spotlight), for: .normal)
        button.tapped { _ in
            self.delegate?.tappedPause()
        }
        return button
    }()
    
    private lazy var stopRecordingButton: RoundButton = {
        let button = RoundButton()
        button.title = L10n.Audio.Recorder.stop
        button.setIcon(Asset.SFSymbols.stop.image.fill(color: InterfaceTheme.Color.spotlight), for: .normal)
        button.tapped { _ in
            self.delegate?.tappedStopRecording()
        }
        return button
    }()
    
    private lazy var stopPlayingButton: RoundButton = {
        let button = RoundButton()
        button.title = L10n.Audio.Player.stop
        button.setIcon(Asset.SFSymbols.stop.image.fill(color: InterfaceTheme.Color.spotlight), for: .normal)
        button.tapped { _ in
            self.delegate?.tappedStopPlaying()
        }
        return button
    }()
    
    private lazy var reRecordButton: RoundButton = {
        let button = RoundButton()
        button.title = L10n.Audio.Recorder.restart
        button.setIcon(Asset.SFSymbols.recordCircle.image.fill(color: InterfaceTheme.Color.warning), for: .normal)
        button.tapped { _ in
            self.delegate?.tappedRecord()
        }
        return button
    }()
    
    private lazy var continueRecordingButton: RoundButton = {
        let button = RoundButton()
        button.title = L10n.Audio.Recorder.continue
        button.setIcon(Asset.SFSymbols.recordCircle.image.fill(color: InterfaceTheme.Color.spotlight), for: .normal)
        button.tapped { _ in
            self.delegate?.tappedResumRecording()
        }
        return button
    }()
    
    public init() {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background1
        
        self.playButton.translatesAutoresizingMaskIntoConstraints = false
        self.recordButton.translatesAutoresizingMaskIntoConstraints = false
        self.pauseRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        self.stopRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        self.stopPlayingButton.translatesAutoresizingMaskIntoConstraints = false
        self.reRecordButton.translatesAutoresizingMaskIntoConstraints = false
        self.continueRecordingButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.playButton)
        self.addSubview(self.recordButton)
        self.addSubview(self.pauseRecordingButton)
        self.addSubview(self.stopRecordingButton)
        self.addSubview(self.stopPlayingButton)
        self.addSubview(self.reRecordButton)
        self.addSubview(self.continueRecordingButton)
        
        // 单独显示的按钮
        self.recordButton.centerAnchors(position: [.centerX, .centerY], to: self)
        self.recordButton.setButtonRadius(40)
        self.stopPlayingButton.centerAnchors(position: [.centerX, .centerY], to: self)
        self.stopPlayingButton.setButtonRadius(40)
        self.pauseRecordingButton.centerAnchors(position: [.centerX, .centerY], to: self)
        self.pauseRecordingButton.setButtonRadius(40)
        
        // 在一起显示的按钮
        self.reRecordButton.setButtonRadius(25)
        self.reRecordButton.centerAnchors(position: .centerY, to: self)
        self.reRecordButton.centerAnchors(position: .centerX, to: self, multiplier: 0.5)

        self.playButton.setButtonRadius(35)
        self.playButton.centerAnchors(position: .centerY, to: self)
        self.playButton.centerAnchors(position: .centerX, to: self, multiplier: 1.5)
        
        // --
        
        self.continueRecordingButton.setButtonRadius(35)
        self.continueRecordingButton.centerAnchors(position: .centerY, to: self)
        self.continueRecordingButton.centerAnchors(position: .centerX, to: self, multiplier: 0.5)
        
        self.stopRecordingButton.setButtonRadius(25)
        self.stopRecordingButton.centerAnchors(position: .centerY, to: self)
        self.stopRecordingButton.centerAnchors(position: .centerX, to: self, multiplier: 1.5)
    }
    
    private func updateUI() {
        self.playButton.isHidden = true
        self.recordButton.isHidden = true
        self.pauseRecordingButton.isHidden = true
        self.stopRecordingButton.isHidden = true
        self.stopPlayingButton.isHidden = true
        self.reRecordButton.isHidden = true
        self.continueRecordingButton.isHidden = true
        
        switch self.status {
        case .initing:
            self.recordButton.isHidden = false
        case .readyToRecord:
            self.recordButton.isEnabled = true
            self.recordButton.isHidden = false
        case .recording:
            self.pauseRecordingButton.isHidden = false
        case .recordingPaused:
            self.continueRecordingButton.isHidden = false
            self.stopRecordingButton.isHidden = false
        case .stopped:
            self.reRecordButton.isHidden = false
            self.playButton.isHidden = false
        case .readyToPlay:
            self.reRecordButton.isHidden = false
            self.playButton.isHidden = false
            self.playButton.isEnabled = true
        case .playing:
            self.stopPlayingButton.isHidden = false
        }
    }
}
