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
        
        self.view.addSubview(browserButton)
        self.view.addSubview(imageCaptureButton)
        
        browserButton.translatesAutoresizingMaskIntoConstraints = false
        imageCaptureButton.translatesAutoresizingMaskIntoConstraints = false
        
        browserButton.centerAnchors(position: [.centerX, .centerY], to: self.view)
        imageCaptureButton.centerAnchors(position: .centerY, to: self.view)
        imageCaptureButton.sideAnchor(for: .top, to: browserButton, edgeInsets: .init(top: 10, left: 0, bottom: 0, right: 0))
    }
    
    @objc private func showBrowser() {
        self.viewModel?.showbrowser()
    }
    
    @objc private func showImageCapture() {
        self.viewModel?.showCaptureImage()
    }
}
