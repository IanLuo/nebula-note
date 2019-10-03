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
    func didSelectOutline(url: URL, selection: OutlineLocation, coordinator: EditorCoordinator)
    func didCancel(coordinator: EditorCoordinator)
}

public class EditorCoordinator: Coordinator {
    public enum Usage {
        case editor(URL, Int)
        case outline(URL, Int?)
    }
    
    public weak var delegate: EditorCoordinatorSelectHeadingDelegate?
    
    private let usage: Usage
    
    private let _viewModel: DocumentEditViewModel
    
    public var didSelectOutlineSelectionAction: ((OutlineLocation) -> Void)?
    
    public init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        self.usage = usage
        
        switch usage {
        case .editor(let url, let location):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url))
            viewModel.onLoadingLocation = location
            self._viewModel = viewModel
            super.init(stack: stack, dependency: dependency)
            let viewController = DocumentEditViewController(viewModel: viewModel)
            viewController.title = url.packageName
            viewController.delegate = self
            viewModel.coordinator = self
            self.viewController = viewController
        case .outline(let url, let ignoredHeadingLocation):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url))
            self._viewModel = viewModel
            super.init(stack: stack, dependency: dependency)
            let viewController = HeadingsOutlineViewController(viewModel: viewModel)
            viewController.ignoredHeadingLocation = ignoredHeadingLocation
            viewController.outlineDelegate = self
            viewController.title = url.packageName
            viewModel.coordinator = self
            self.viewController = viewController
        }
    }
    
    public func showOutline(ignoredHeadingLocation: Int? = nil, completion: @escaping (OutlineLocation) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        navigationController.isNavigationBarHidden = true
        let coordinator = EditorCoordinator(stack: navigationController, dependency: self.dependency, usage: EditorCoordinator.Usage.outline(self._viewModel.url, ignoredHeadingLocation))
        coordinator.didSelectOutlineSelectionAction = { [weak coordinator] selection in
            coordinator?.stop(animated: true, completion: {
                completion(selection)
            })
        }
        coordinator.start(from: self)
    }
    
    public func showDocumentHeadingPicker(completion: @escaping (URL, OutlineLocation) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let documentCoord = BrowserCoordinator(stack: navigationController,
                                               dependency: super.dependency,
                                               usage: .chooseHeader)
        
        documentCoord.didSelectOutlineAction = { [weak documentCoord]  url, outlineLocation in
            documentCoord?.stop()
            completion(url, outlineLocation)
        }
        
        documentCoord.didCancelAction = { [weak documentCoord] in
            documentCoord?.stop()
        }
        
        documentCoord.start(from: self)
    }
    
    public func showCapturedList(completion: @escaping (Attachment) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let capturedListCoordinator = CaptureListCoordinator(stack: navigationController, dependency: self.dependency, mode: CaptureListViewModel.Mode.pick)
        capturedListCoordinator.onSelectAction = { [unowned capturedListCoordinator] attachment in
            capturedListCoordinator.stop()
            completion(attachment)
        }
        
        capturedListCoordinator.start(from: self)
    }
        
    public func showLinkEditor(title: String, url: String, completeEdit: @escaping (String) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
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
    
    public func loadAllTags() -> [String] {
        if let home = self.rootCoordinator.searchFirstCoordinator(type: HomeCoordinator.self) {
            return home.getAllTags()
        } else {
            return []
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
    
    public func showDocumentInfo(viewModel: DocumentEditViewModel, completion: @escaping () -> Void) {
        let documentInfoViewController = DocumentInfoViewController(viewModel: viewModel)
        documentInfoViewController.didCloseAction = completion
        self.viewController?.present(documentInfoViewController, animated: true, completion: nil)
    }
}

extension EditorCoordinator: DocumentEditViewControllerDelegate {

}

extension EditorCoordinator: HeadingsOutlineViewControllerDelegate {
    public func didCancel() {
        self.delegate?.didCancel(coordinator: self)
    }
    
    public func didSelect(url: URL, selection: OutlineLocation) {
        self.delegate?.didSelectOutline(url: url, selection: selection, coordinator: self)
        self.didSelectOutlineSelectionAction?(selection)
    }
}
