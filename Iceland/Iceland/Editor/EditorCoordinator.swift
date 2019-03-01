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
    func didSelectHeading(url: URL, heading: HeadingToken)
}

public class EditorCoordinator: Coordinator {
    public enum Usage {
        case editor(URL, Int)
        case outline(URL)
    }
    
    public weak var delegate: EditorCoordinatorSelectHeadingDelegate?
    
    private let usage: Usage
    
    public init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        self.usage = usage
        
        switch usage {
        case .editor(let url, let location):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url))
            viewModel.onLoadingLocation = location
            super.init(stack: stack, dependency: dependency)
            let viewController = DocumentEditViewController(viewModel: viewModel)
            viewController.delegate = self
            viewModel.coordinator = self
            self.viewController = viewController
        case .outline(let url):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url))
            super.init(stack: stack, dependency: dependency)
            let viewController = HeadingsOutlineViewController(viewModel: viewModel)
            viewController.outlineDelegate = self
            viewController.title = url.fileName
            viewModel.coordinator = self
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
    public func didSelectDocument(url: URL, location: Int, searchCoordinator: SearchCoordinator) {
        searchCoordinator.stop()
        let documentCoordinator = EditorCoordinator(stack: self.stack,
                                                    dependency: self.dependency,
                                                    usage: EditorCoordinator.Usage.editor(url, location))
        documentCoordinator.start(from: self)
    }
    
    public func didCancelSearching() {
        // ignore
    }
    
    public func search() {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        navigationController.modalPresentationStyle = .overCurrentContext
        let searchCoordinator = SearchCoordinator(stack: navigationController, dependency: self.dependency)
        searchCoordinator.delegate = self
        searchCoordinator.start(from: self)
    }
}

extension EditorCoordinator: DocumentEditViewControllerDelegate {
    public func didTapLink(url: URL, title: String, point: CGPoint) {
        
    }
}

extension EditorCoordinator: HeadingsOutlineViewControllerDelegate {
    public func didSelectHeading(url: URL, heading: HeadingToken) {
        self.stop()
        self.delegate?.didSelectHeading(url: url, heading: heading)
    }
}
