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
import Interface

public protocol EditorCoordinatorSelectHeadingDelegate: class {
    func didSelectHeading(url: URL, heading: HeadingToken, coordinator: EditorCoordinator)
    func didCancel(coordinator: EditorCoordinator)
}

public class EditorCoordinator: Coordinator {
    public enum Usage {
        case editor(URL, Int)
        case outline(URL)
    }
    
    public weak var delegate: EditorCoordinatorSelectHeadingDelegate?
    
    private let usage: Usage
    
    private let _viewModel: DocumentEditViewModel
    
    public init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        self.usage = usage
        
        switch usage {
        case .editor(let url, let location):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url))
            viewModel.onLoadingLocation = location
            self._viewModel = viewModel
            super.init(stack: stack, dependency: dependency)
            let viewController = DocumentEditViewController(viewModel: viewModel)
            viewController.delegate = self
            viewModel.coordinator = self
            self.viewController = viewController
        case .outline(let url):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url))
            self._viewModel = viewModel
            super.init(stack: stack, dependency: dependency)
            let viewController = HeadingsOutlineViewController(viewModel: viewModel)
            viewController.outlineDelegate = self
            viewController.title = url.fileName
            viewModel.coordinator = self
            self.viewController = viewController
        }
    }
    
    public func showCapturedList() {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        let capturedListCoordinator = CaptureListCoordinator(stack: navigationController, dependency: self.dependency, mode: CaptureListViewModel.Mode.pick)
        capturedListCoordinator.delegate = self
    }
    
    public func showLinkEditor(title: String, url: String, completeEdit: @escaping (String) -> Void) {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        let attachmentLinkCoordinator = AttachmentCoordinator(stack: navigationController, dependency: self.dependency, title: title, url: url)
        attachmentLinkCoordinator.onSaveAttachment = { key in
            AttachmentManager().attachment(with: key, completion: { attachment in
                let linkString = OutlineParser.Values.Attachment.serialize(attachment: attachment)
                completeEdit(linkString)
            }, failure: { error in
                log.error(error)
            })
        }
        
        attachmentLinkCoordinator.start(from: self)
    }
}

extension EditorCoordinator: CaptureListCoordinatorDelegate {
    public func didSelectAttachment(attachment: Attachment, coordinator: CaptureListCoordinator) {
        if let editViewController = self.viewController as? DocumentEditViewController {
            self._viewModel.performAction(EditAction.addAttachment(editViewController.textView.selectedRange.location,
                                                                   attachment.key,
                                                                   attachment.kind.rawValue),
                                          undoManager: editViewController.textView.undoManager!,
                                          completion: nil)
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
    public func didCancel() {
        self.delegate?.didCancel(coordinator: self)
    }
    
    public func didSelectHeading(url: URL, heading: HeadingToken) {
        self.delegate?.didSelectHeading(url: url, heading: heading, coordinator: self)
    }
}
