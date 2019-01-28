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

public protocol EditorCoordinatorSelectHeadingDelegate: class {
    func didSelectHeading(url: URL, heading: Document.Heading)
}

public class EditorCoordinator: Coordinator {
    public enum Usage {
        case editor(URL, Int)
        case outline(URL)
    }
    
    public weak var delegate: EditorCoordinatorSelectHeadingDelegate?
    
    private let usage: Usage
    
    public init(stack: UINavigationController, context: Context, usage: Usage) {
        self.usage = usage
        
        switch usage {
        case .editor(let url, let location):
            let viewModel = DocumentEditViewModel(editorService: OutlineEditorServer.request(url: url))
            viewModel.onLoadingLocation = location
            super.init(stack: stack, context: context)
            let viewController = DocumentEditViewController(viewModel: viewModel)
            viewController.delegate = self
            viewModel.dependency = self
            self.viewController = viewController
        case .outline(let url):
            let viewModel = DocumentEditViewModel(editorService: OutlineEditorServer.request(url: url))
            super.init(stack: stack, context: context)
            let viewController = HeadingsOutlineViewController(viewModel: viewModel)
            viewController.outlineDelegate = self
            viewController.title = url.fileName
            viewModel.dependency = self
            self.viewController = viewController
        }
    }
    
    public override func moveIn(top: UIViewController?, animated: Bool) {
        guard let viewController = self.viewController else { return }
        switch self.usage {
        case .editor:
            super.moveIn(top: top, animated: animated)
        case .outline:
            if let top = top {
                (viewController as? HeadingsOutlineViewController)?.show(from: nil, on: top)
            }
        }
    }
}

extension EditorCoordinator: SearchCoordinatorDelegate {
    public func didSelectDocument(url: URL) {
        self.openDocument(url: url, location: 0)
    }
    
    public func didCancelSearching() {
        // ignore
    }
    
    public func search() {
        let searchCoordinator = SearchCoordinator(stack: self.stack, context: self.context)
        searchCoordinator.delegate = self
        searchCoordinator.start(from: self)
    }
}

extension EditorCoordinator: DocumentEditViewControllerDelegate {
    public func didTapLink(url: URL, title: String, point: CGPoint) {
        
    }
}

extension EditorCoordinator: HeadingsOutlineViewControllerDelegate {
    public func didSelectHeading(url: URL, heading: Document.Heading) {
        self.stop()
        self.delegate?.didSelectHeading(url: url, heading: heading)
    }
}
