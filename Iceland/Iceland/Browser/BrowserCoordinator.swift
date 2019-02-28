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
    func didSelectHeading(url: URL, heading: Heading)
}

public class BrowserCoordinator: Coordinator {
    public enum Usage {
        case chooseDocument
        case chooseHeading
    }
    
    public let usage: Usage
    public weak var delegate: BrowserCoordinatorDelegate?
    
    public init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        let viewModel = DocumentBrowserViewModel(documentManager: dependency.documentManager)
        let viewController = DocumentBrowserViewController(viewModel: viewModel)
        self.usage = usage
        super.init(stack: stack, dependency: dependency)
        viewModel.coordinator = self
        viewController.delegate = self
        self.viewController = viewController
    }
    
    public func showOutlineHeadings(url: URL) {
        let editorCoord = EditorCoordinator(stack: self.stack,
                                            dependency: self.dependency,
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
    public func didSelectHeading(url: URL, heading: Heading) {
        self.delegate?.didSelectHeading(url: url, heading: heading)
        self.stop()
    }
}
