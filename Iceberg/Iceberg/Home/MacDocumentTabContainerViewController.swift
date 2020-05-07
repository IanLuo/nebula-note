//
//  MacDocumentTabContainerViewController.swift
//  Interface
//
//  Created by ian luo on 2020/5/2.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import Core

public protocol MacDocumentTabContainerViewControllerDelegate: class {
    func didCloseDocument(url: URL, editorViewController: DocumentEditorViewController)
}

public class MacDocumentTabContainerViewController: UIViewController {
    public weak var delegate: MacDocumentTabContainerViewControllerDelegate?
    
    private var openingViewControllers: [URL: DocumentEditorViewController] = [:]
    
    public func showDocument(url: URL, viewController: DocumentEditorViewController) {
        self.openingViewControllers[url] = viewController
        self.addChild(viewController)
        
        self.view.addSubview(viewController.view)
        viewController.view.allSidesAnchors(to: self.view, edgeInset: 0)
    }
    
    public func closeDocument(url: URL) {
        if let viewController = self.openingViewControllers[url] {
            viewController.removeFromParent()
            viewController.view.removeFromSuperview()
        }
    }
}
