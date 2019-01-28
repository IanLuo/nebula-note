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
    func didSelectHeading(url: URL, heading: Document.Heading)
}

public class BrowserCoordinator: Coordinator {
    public enum Usage {
        case chooseDocument
        case chooseHeading
    }
    
    public let usage: Usage
    public weak var delegate: BrowserCoordinatorDelegate?
    
    public init(stack: UINavigationController, context: Context, usage: Usage) {
        let viewModel = DocumentBrowserViewModel(documentManager: context.documentManager)
        let viewController = DocumentBrowserViewController(viewModel: viewModel)
        self.usage = usage
        super.init(stack: stack, context: context)
        viewModel.dependency = self
        viewController.delegate = self
        self.viewController = viewController
    }
    
    public func showOutlineHeadings(url: URL) {
        let editorCoord = EditorCoordinator(stack: self.stack,
                                            context: self.context,
                                            usage: .outline(url))
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

extension BrowserCoordinator: EditorCoordinatorSelectHeadingDelegate {
    public func didSelectHeading(url: URL, heading: Document.Heading) {
        self.delegate?.didSelectHeading(url: url, heading: heading)
        self.stop()
    }
}
