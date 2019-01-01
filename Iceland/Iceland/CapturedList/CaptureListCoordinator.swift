//
//  CaptureListCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class CaptureListCoordinator: Coordinator {
    let documentManager: DocumentManager
    let documentSearchManager: DocumentSearchManager
    let viewModel: CaptureListViewModel
    
    public init(stack: UINavigationController, documentManager: DocumentManager, documentSearchManager: DocumentSearchManager) {
        self.documentManager = documentManager
        self.documentSearchManager = documentSearchManager
        
        self.viewModel = CaptureListViewModel(service: CaptureService())
        let viewController = CaptureListViewController(viewModel: self.viewModel)
        
        super.init(stack: stack)
        self.viewController = viewController
    }
    
    public func showDocumentHeadingSelector() {
        let documentCoord = BrowserCoordinator(stack: self.stack,
                                               documentManager: self.documentManager,
                                               usage: .chooseHeading)
        documentCoord.delegate = self
        documentCoord.start(from: self)
    }
}

extension CaptureListCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL) {}
    
    public func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading) {
        self.viewModel.refile(editorService: OutlineEditorServer.request(url: url), heading: heading)
    }
}
