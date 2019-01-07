//
//  EditorCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/26.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol EditorCoordinatorDelegate: class {
    func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading)
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
    
    public override func moveIn(from: UIViewController?) {
        guard let viewController = self.viewController else { return }
        switch self.usage {
        case .editor:
            self.stack.pushViewController(viewController, animated: true)
        case .outline:
            from?.present(viewController, animated: true, completion: nil)
        }
    }
    
    public override func moveOut(from: UIViewController) {
        switch self.usage {
        case .editor:
            self.stack.popViewController(animated: true)
        case .outline:
            self.viewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension EditorCoordinator: DocumentEditViewControllerDelegate {
    public func didTapLink(url: URL, title: String, point: CGPoint) {
        
    }
}

extension EditorCoordinator: HeadingsOutlineViewControllerDelegate {
    public func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading) {
        self.stop()
        self.delegate?.didSelectHeading(url: url, heading: heading)
    }
}
