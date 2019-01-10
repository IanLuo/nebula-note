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

public protocol AttachmentViewControllerDelegate: class {
    func didSaveAttachment(key: String)
}

public class AttachmentViewController: UIViewController {
    public let viewModel: AttachmentViewModel
    public weak var delegate: AttachmentViewControllerDelegate?
    
    public init(viewModel: AttachmentViewModel) {
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

extension AttachmentViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}

extension AttachmentViewController: AttachmentViewModelDelegate {
    public func didSaveAttachment(key: String) {
        self.delegate?.didSaveAttachment(key: key)
    }
    
    public func didFailToSave(error: Error, content: String, type: Attachment.AttachmentType, descritpion: String) {
        log.error(error)
    }
}
