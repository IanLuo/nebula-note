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
    let viewModel: CaptureListViewModel
    
    public override init(stack: UINavigationController, context: Context) {
        self.viewModel = CaptureListViewModel(service: CaptureService())
        let viewController = CaptureListViewController(viewModel: self.viewModel)
        
        super.init(stack: stack, context: context)
        self.viewController = viewController
        viewModel.dependency = self
    }
    
    public func showDocumentHeadingSelector() {
        let documentCoord = BrowserCoordinator(stack: self.stack,
                                               context: super.context,
                                               usage: .chooseHeading)
        documentCoord.delegate = self
        documentCoord.start(from: self)
    }
}

extension CaptureListCoordinator: BrowserCoordinatorDelegate {
    public func didSelectDocument(url: URL) {}
    
    public func didSelectHeading(url: URL, heading: Document.Heading) {
        self.viewModel.refile(editorService: OutlineEditorServer.request(url: url), heading: heading)
    }
}
