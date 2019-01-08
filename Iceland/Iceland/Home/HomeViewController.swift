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
        imageCaptureButton.setTitle("capture image", for: .normal)
        imageCaptureButton.addTarget(self, action: #selector(showImageCapture), for: .touchUpInside)
        
        let audioRecordButton = UIButton()
        audioRecordButton.setTitle("record audio", for: .normal)
        audioRecordButton.addTarget(self, action: #selector(showAudioRecorder), for: .touchUpInside)
        
        self.view.addSubview(browserButton)
        self.view.addSubview(imageCaptureButton)
        self.view.addSubview(audioRecordButton)
        
        browserButton.translatesAutoresizingMaskIntoConstraints = false
        imageCaptureButton.translatesAutoresizingMaskIntoConstraints = false
        audioRecordButton.translatesAutoresizingMaskIntoConstraints = false
        
        browserButton.centerAnchors(position: [.centerX, .centerY], to: self.view)
        imageCaptureButton.centerAnchors(position: .centerX, to: self.view)
        imageCaptureButton.topAnchor.constraint(equalTo: browserButton.bottomAnchor, constant: 10).isActive = true
        
        audioRecordButton.centerAnchors(position: .centerX, to: self.view)
        audioRecordButton.topAnchor.constraint(equalTo: imageCaptureButton.bottomAnchor, constant: 10).isActive = true
    }
    
    @objc private func showBrowser() {
        self.viewModel?.dependency?.showBrowser()
    }
    
    @objc private func showImageCapture() {
        self.viewModel?.dependency?.showImageCapture()
    }
    
    @objc private func showAudioRecorder() {
        self.viewModel?.dependency?.showAudioRecorder()
    }
}
