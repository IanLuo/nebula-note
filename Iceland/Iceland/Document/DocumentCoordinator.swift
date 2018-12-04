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
    public let browserViewController: UIViewController
    
    public override init(stack: UINavigationController) {
        let viewModel = DocumentBrowserViewModel()
        self.browserViewController = DocumentBrowserViewController(viewModel: viewModel)
        super.init(stack: stack)
        viewModel.delegate = self
    }
    
    public override func start() {
        self.stack.pushViewController(self.browserViewController, animated: true)
    }
    
    public func openDocument(document: Document) {
        let editViewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                  document: document)
        editViewModel.delegate = self
        let viewController = DocumentEditViewController(viewModel: editViewModel)
        stack.pushViewController(viewController, animated: true)
    }
}

extension DocumentCoordinator: DocumentEditDelegate {
    public func didClickLink(url: URL) {
        
    }
}

extension DocumentCoordinator: DocumentBrowserDelegate {
    public func didSelectDocument(document: Document) {
        self.openDocument(document: document)
    }
}
