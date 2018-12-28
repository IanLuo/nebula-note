//
//  DocumentCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol DocumentCoordinatorDelegate: class {
    func didPickDocument(url: URL, location: Int, from: DocumentCoordinator)
    func didPickHeading(url: URL, heading: OutlineTextStorage.Heading, from: DocumentCoordinator)
}

public class DocumentCoordinator: Coordinator {
    public enum DocumentError: Error {
        case failToInsert
        case failToOpenFile
        case failToReschedule
        case failToChangeDueDate
        case failToChangePlanning
    }

    public enum Usage {
        case pickHeading
        case pickDocument
        case search
    }
    
    private let documentManager: DocumentManager
    private let documentSearchManager: DocumentSearchManager
    public let usage: Usage
    
    public weak var delegate: DocumentCoordinatorDelegate?
    
    public init(stack: UINavigationController,
                usage: Usage,
                documentManager: DocumentManager,
                documentSearchManager: DocumentSearchManager) {
        
        self.usage = usage
        self.documentManager = documentManager
        self.documentSearchManager = documentSearchManager
        super.init(stack: stack)

        switch usage {
        case .pickDocument:
            let viewModel = DocumentBrowserViewModel(documentManager: documentManager)
            let viewController = DocumentBrowserViewController(viewModel: viewModel)
            
            viewModel.delegate = viewController
            viewModel.dependency = self
            viewController.delegate = self
            self.viewController = viewController
        case .pickHeading:
            let viewModel = DocumentBrowserViewModel(documentManager: documentManager)
            let viewController = DocumentBrowserViewController(viewModel: viewModel)

            viewModel.delegate = viewController
            viewModel.dependency = self
            viewController.delegate = self
            self.viewController = viewController
        case .search:
            let viewModel = DocumentSearchViewModel(documentSearchManager: documentSearchManager)
            let viewController = DocumentSearchViewController(viewModel: viewModel)
            
            viewModel.delegate = viewController
            viewModel.dependency = self
            viewController.delegate = self
            self.viewController = viewController
        }
    }
        
    public func showHeadingOutlines(viewModel: DocumentEditViewModel) {
        let viewController = HeadingsOutlineViewController(viewModel: viewModel)
        viewController.modalPresentationStyle = .overCurrentContext
        self.stack.topViewController?.present(viewController, animated: true, completion: nil)
    }
    
    /// 打开文件
    public func openDocument(url: URL, location: Int) {
        let editorCood = EditorCoordinator(stack: self.stack, usage: .editor(url, location))
        editorCood.delegate = self

        editorCood.start(from: self)
    }
}

extension DocumentCoordinator: DocumentBrowserViewControllerDelegate {
    public func didSelectDocument(url: URL) {
        
    }
    
    public func didSelectDocumentHeading(url: URL, heading: OutlineTextStorage.Heading) {
        
    }
}

extension DocumentCoordinator: EditorCoordinatorDelegate {
    public func didFinishRefiling() {}
}

extension DocumentCoordinator: DocumentSearchViewControllerDelegate {
    
}
