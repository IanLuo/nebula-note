//
//  DocumentCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class DocumentCoordinator: Coordinator {
    public enum DocumentError: Error {
        case failToInsert
        case failToOpenFile
        case failToReschedule
        case failToChangeDueDate
        case failToChangePlanning
    }
    
    public enum HeadingSearchBy {
        case planning([String])
        case tags([String])
        case schedule(Date)
        case due(Date)
    }
    
    public let viewController: UIViewController
    
    public enum Usage {
        case refile
        case pickDocument
        case search
        case editor(URL, Int)
        case headless
    }
    
    private let documentManager: DocumentManager
    private let documentSearchManager: DocumentSearchManager
    public let usage: Usage
    
    public init(stack: UINavigationController,
                usage: Usage,
                documentManager: DocumentManager,
                documentSearchManager: DocumentSearchManager) {
        
        self.usage = usage
        self.documentManager = documentManager
        self.documentSearchManager = documentSearchManager
        
        switch usage {
        case let .editor(url, location):
            let viewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
            viewModel.onLoadingLocation = location
            self.viewController = DocumentEditViewController(viewModel: viewModel)
            super.init(stack: stack)
            viewModel.dependency = self
        case .pickDocument:
            let viewModel = DocumentBrowserViewModel(documentManager: documentManager)
            self.viewController = DocumentBrowserViewController(viewModel: viewModel)
            super.init(stack: stack)
            viewModel.dependency = self
        case .refile:
            let viewModel = DocumentBrowserViewModel(documentManager: documentManager)
            self.viewController = DocumentBrowserViewController(viewModel: viewModel)
            super.init(stack: stack)
            viewModel.dependency = self
        case .search:
            let viewModel = DocumentSearchViewModel(documentSearchManager: documentSearchManager)
            self.viewController = DocumentSearchViewController(viewModel: viewModel)
            super.init(stack: stack)
            viewModel.dependency = self
        case .headless:
            self.viewController = UIViewController()
            super.init(stack: stack)
        }
    }
    
    public override func start() {
        self.stack.pushViewController(self.viewController, animated: true)
    }
    
    public func showHeadingOutlines(viewModel: DocumentEditViewModel) {
        let viewController = HeadingsOutlineViewController(viewModel: viewModel)
        viewController.modalPresentationStyle = .overCurrentContext
        self.stack.topViewController?.present(viewController, animated: true, completion: nil)
    }
    
    /// 打开文件
    public func openDocument(url: URL, location: Int) {
        let editViewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()), document: Document(fileURL: url))
        editViewModel.dependency = self
        editViewModel.onLoadingLocation = location
        let viewController = DocumentEditViewController(viewModel: editViewModel)
        stack.pushViewController(viewController, animated: true)
    }
}
