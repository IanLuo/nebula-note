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
    func didSelectDocument(url: URL, coordinator: BrowserCoordinator)
    func didSelectHeading(url: URL, heading: DocumentHeading, coordinator: BrowserCoordinator)
    func didCancel(coordinator: BrowserCoordinator)
}

public class BrowserCoordinator: Coordinator {
    public enum Usage {
        case chooseDocument
        case chooseHeading
    }
    
    public let usage: Usage
    public weak var delegate: BrowserCoordinatorDelegate?
    
    public var didSelectDocumentAction: ((URL) -> Void)?
    public var didSelectHeadingAction: ((URL, DocumentHeading) -> Void)?
    public var didCancelAction: (() -> Void)?
    
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
        let navigationController = Coordinator.createDefaultNavigationControlller()
        navigationController.isNavigationBarHidden = true
        
        let editorCoord = EditorCoordinator(stack: navigationController,
                                            dependency: self.dependency,
                                            usage: .outline(url, nil))
        editorCoord.delegate = self
        editorCoord.start(from: self)
    }
}

extension BrowserCoordinator: DocumentBrowserViewControllerDelegate {
    public func didSelectDocument(url: URL) {
        switch self.usage {
        case .chooseDocument:
            self.delegate?.didSelectDocument(url: url, coordinator: self)
            self.didSelectDocumentAction?(url)
        case .chooseHeading:
            self.showOutlineHeadings(url: url)
        }
    }
    
    public func didCancel() {
        self.didCancelAction?()
    }
}

extension BrowserCoordinator: EditorCoordinatorSelectHeadingDelegate {
    public func didSelectHeading(url: URL, heading: DocumentHeading, coordinator: EditorCoordinator) {
        coordinator.stop {
            self.delegate?.didSelectHeading(url: url, heading: heading, coordinator: self)
            self.didSelectHeadingAction?(url, heading)
        }
    }
    
    public func didCancel(coordinator: EditorCoordinator) {
        coordinator.stop()
    }
}
