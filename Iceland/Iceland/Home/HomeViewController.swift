//
//  HomeViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class HomeViewController: UIViewController {
    private var viewModel: HomeViewModel?
    
    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        let browserButton = UIButton()
        browserButton.setTitle("browser", for: .normal)
        browserButton.addTarget(self, action: #selector(showBrowser), for: .touchUpInside)
        
        let imageCaptureButton = UIButton()
        imageCaptureButton.setTitle("add image", for: .normal)
        imageCaptureButton.addTarget(self, action: #selector(showImageCapture), for: .touchUpInside)
        
        let audioRecordButton = UIButton()
        audioRecordButton.setTitle("record audio", for: .normal)
        audioRecordButton.addTarget(self, action: #selector(showAudioRecorder), for: .touchUpInside)
        
        let sketchButton = UIButton()
        sketchButton.setTitle("sketch", for: .normal)
        sketchButton.addTarget(self, action: #selector(showSketch), for: .touchUpInside)
        
        let locationButton = UIButton()
        locationButton.setTitle("location", for: .normal)
        locationButton.addTarget(self, action: #selector(showLocationPicker), for: .touchUpInside)
        
        let videoButton = UIButton()
        videoButton.setTitle("video", for: .normal)
        videoButton.addTarget(self, action: #selector(showVideoRecorder), for: .touchUpInside)
        
        let linkButton = UIButton()
        linkButton.setTitle("link", for: .normal)
        linkButton.addTarget(self, action: #selector(showLinkEditor), for: .touchUpInside)
        
        let textButton = UIButton()
        textButton.setTitle("text", for: .normal)
        textButton.addTarget(self, action: #selector(showTextEditor), for: .touchUpInside)
        
        let captureListButton = UIButton()
        captureListButton.setTitle("capture list", for: .normal)
        captureListButton.addTarget(self, action: #selector(showCaptureList), for: .touchUpInside)
        
        let agendaButton = UIButton()
        agendaButton.setTitle("agenda", for: .normal)
        agendaButton.addTarget(self, action: #selector(showAgenda), for: .touchUpInside)
        
        self.view.addSubview(browserButton)
        self.view.addSubview(imageCaptureButton)
        self.view.addSubview(audioRecordButton)
        self.view.addSubview(sketchButton)
        self.view.addSubview(locationButton)
        self.view.addSubview(videoButton)
        self.view.addSubview(linkButton)
        self.view.addSubview(textButton)
        self.view.addSubview(captureListButton)
        self.view.addSubview(agendaButton)
        
        browserButton.centerAnchors(position: [.centerX], to: self.view)
        browserButton.centerAnchors(position: [.centerY], to: self.view, multiplier: 0.5)
        
        imageCaptureButton.centerAnchors(position: .centerX, to: self.view)
        imageCaptureButton.topAnchor.constraint(equalTo: browserButton.bottomAnchor, constant: 10).isActive = true
        
        audioRecordButton.centerAnchors(position: .centerX, to: self.view)
        audioRecordButton.topAnchor.constraint(equalTo: imageCaptureButton.bottomAnchor, constant: 10).isActive = true
        
        sketchButton.centerAnchors(position: .centerX, to: self.view)
        sketchButton.topAnchor.constraint(equalTo: audioRecordButton.bottomAnchor, constant: 10).isActive = true
        
        locationButton.centerAnchors(position: .centerX, to: self.view)
        locationButton.topAnchor.constraint(equalTo: sketchButton.bottomAnchor, constant: 10).isActive = true
        
        videoButton.centerAnchors(position: .centerX, to: self.view)
        videoButton.topAnchor.constraint(equalTo: locationButton.bottomAnchor, constant: 10).isActive = true
        
        linkButton.centerAnchors(position: .centerX, to: self.view)
        linkButton.topAnchor.constraint(equalTo: videoButton.bottomAnchor, constant: 10).isActive = true
        
        textButton.centerAnchors(position: .centerX, to: self.view)
        textButton.topAnchor.constraint(equalTo: linkButton.bottomAnchor, constant: 10).isActive = true
        
        captureListButton.centerAnchors(position: .centerX, to: self.view)
        captureListButton.topAnchor.constraint(equalTo: textButton.bottomAnchor, constant: 10).isActive = true
        
        agendaButton.centerAnchors(position: .centerX, to: self.view)
        agendaButton.topAnchor.constraint(equalTo: captureListButton.bottomAnchor, constant: 10).isActive = true
    }
    
    @objc private func showBrowser() {
        self.viewModel?.dependency?.showBrowser()
    }
    
    @objc private func showImageCapture() {
        self.viewModel?.dependency?.showAttachmentCreator(type: .image)
    }
    
    @objc private func showAudioRecorder() {
        self.viewModel?.dependency?.showAttachmentCreator(type: .audio)
    }
    
    @objc private func showSketch() {
        self.viewModel?.dependency?.showAttachmentCreator(type: .sketch)
    }
    
    @objc private func showLocationPicker() {
        self.viewModel?.dependency?.showAttachmentCreator(type: .location)
    }
    
    @objc private func showVideoRecorder() {
        self.viewModel?.dependency?.showAttachmentCreator(type: .video)
    }
    
    @objc private func showLinkEditor() {
        self.viewModel?.dependency?.showAttachmentCreator(type: .link)
    }
    
    @objc private func showTextEditor() {
        self.viewModel?.dependency?.showAttachmentCreator(type: .text)
    }
    
    @objc private func showCaptureList() {
        self.viewModel?.dependency?.showCaptureList()
    }
    
    @objc private func showAgenda() {
        self.viewModel?.dependency?.showAgenda()
    }
}
