//
//  CaptureViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol CaptureViewControllerDelegate: class {
    func didSaveCapture(attachment: Attachment)
}

public class CaptureViewController: UIViewController {
    public let viewModel: CaptureViewModel
    public weak var delegate: CaptureViewControllerDelegate?
    
    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        self.view.backgroundColor = InterfaceTheme.Color.background1.withAlphaComponent(0.0)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func cancel() {
        self.viewModel.dependency?.stop()
    }
    
    private var isFirstLoad = true
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFirstLoad {
            self.animateShowBackground()
            isFirstLoad = false
        }
    }
    
    public func animateShowBackground() {
        UIView.animate(withDuration: 0.2) {
            self.view.backgroundColor = InterfaceTheme.Color.background1.withAlphaComponent(0.5)
        }
    }
    
    public func animateHideBackground(complete: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.backgroundColor = InterfaceTheme.Color.background1.withAlphaComponent(0.0)
        }) {
            if $0 {
                complete()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CaptureViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}

extension CaptureViewController: CaptureViewModelDelegate {
    public func didCompleteCapture(attachment: Attachment) {
        self.delegate?.didSaveCapture(attachment: attachment)
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        log.error(error)
    }
}
