//
//  BrowserCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol BrowserCoordinatorDelegate: class {
    func didSelectDocument(url: URL)
    func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading)
}

public class BrowserCoordinator: Coordinator {
    public enum Usage {
        case chooseDocument
        case chooseHeading
    }
    
    public let usage: Usage
    private let documentManager: DocumentManager
    public weak var delegate: BrowserCoordinatorDelegate?
    
    public init(stack: UINavigationController, documentManager: DocumentManager, usage: Usage) {
        self.documentManager = documentManager
        let viewModel = DocumentBrowserViewModel(documentManager: documentManager)
        let viewController = DocumentBrowserViewController(viewModel: viewModel)
        self.usage = usage
        super.init(stack: stack)
        viewModel.dependency = self
        viewController.delegate = self
        self.viewController = viewController
    }
    
    public override func moveIn(top: UIViewController?, animated: Bool) {
        guard let viewController = self.viewController else { return }
        
        top?.present(viewController, animated: animated, completion: nil)
    }
    
    public override func moveOut(top: UIViewController, animated: Bool) {
        self.viewController?.dismiss(animated: animated, completion: nil)
    }
    
    public func showOutlineHeadings(url: URL) {
        let editorCoord = EditorCoordinator(stack: self.stack, usage: .outline(url))
        editorCoord.delegate = self
        editorCoord.start(from: self)
    }
}

extension BrowserCoordinator: DocumentBrowserViewControllerDelegate {
    public func didSelectDocument(url: URL) {
        switch self.usage {
        case .chooseDocument:
            self.delegate?.didSelectDocument(url: url)
        case .chooseHeading:
            self.showOutlineHeadings(url: url)
        }
    }
}

extension BrowserCoordinator: EditorCoordinatorDelegate {
    public func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading) {
        self.delegate?.didSelectHeading(url: url, heading: heading)
        self.stop()
    }
}
