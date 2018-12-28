//
//  EditorCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/26.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol EditorCoordinatorDelegate: class {
    func didFinishRefiling()
}

public class EditorCoordinator: Coordinator {
    public enum Usage {
        case editor(URL, Int)
        case outline(URL)
    }
    
    public weak var delegate: EditorCoordinatorDelegate?
    
    private let usage: Usage
    
    public init(stack: UINavigationController, usage: Usage) {
        self.usage = usage
        
        switch usage {
        case .editor(let url, let location):
            let viewModel = DocumentEditViewModel(editorService: OutlineEditorServer.request(url: url))
            viewModel.onLoadingLocation = location
            super.init(stack: stack)
            let viewController = DocumentEditViewController(viewModel: viewModel)
            viewController.delegate = self
            viewModel.delegate = viewController
            self.viewController = viewController
        case .outline(let url):
            let viewModel = DocumentEditViewModel(editorService: OutlineEditorServer.request(url: url))
            super.init(stack: stack)
            let viewController = HeadingsOutlineViewController(viewModel: viewModel)
            viewController.delegate = self
            viewModel.delegate = viewController
            self.viewController = viewController
        }
    }

}

extension EditorCoordinator: DocumentEditViewControllerDelegate {
    public func didTapLink(url: URL, title: String, point: CGPoint) {
        
    }
    
    public func didChooseHeading(heading: OutlineTextStorage.Heading) {

    }
}

extension EditorCoordinator: HeadingsOutlineViewControllerDelegate {
    
}
