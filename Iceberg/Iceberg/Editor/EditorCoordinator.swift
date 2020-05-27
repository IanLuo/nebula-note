//
//  EditorCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/26.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

public protocol EditorCoordinatorSelectHeadingDelegate: class {
    func didSelectOutline(url: URL, selection: OutlineLocation, coordinator: EditorCoordinator)
    func didCancel(coordinator: EditorCoordinator)
}

public class EditorCoordinator: Coordinator {
    public enum Usage {
        case temp(URL)
        case editor(URL, Int)
        case outline(URL, Int?)
    }
    
    public weak var delegate: EditorCoordinatorSelectHeadingDelegate?
    
    let usage: Usage
    
    private var _viewModel: DocumentEditViewModel!
    
    public var didSelectOutlineSelectionAction: ((OutlineLocation) -> Void)?
    public var didCancelSelectionOutlineSelectionAction: (() -> Void)?
    
    private var _url: URL!
    
    public init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        self.usage = usage
        super.init(stack: stack, dependency: dependency)
        
        switch usage {
        case .editor(let url, let location):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url), coordinator: self)
            viewModel.onLoadingLocation = location
            self._viewModel = viewModel
            self._url = url
            let viewController = DocumentEditorViewController(viewModel: viewModel)
            viewController.title = url.packageName
            self.viewController = viewController
        case .outline(let url, let ignoredHeadingLocation):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.request(url: url), coordinator: self)
            self._viewModel = viewModel
            self._url = url
            let viewController = HeadingsOutlineViewController(viewModel: viewModel)
            viewController.ignoredHeadingLocation = ignoredHeadingLocation
            viewController.outlineDelegate = self
            viewController.title = url.packageName
            self.viewController = viewController
        case .temp(let url):
            let viewModel = DocumentEditViewModel(editorService: dependency.editorContext.requestTemp(url: url), coordinator: self)
            self._viewModel = viewModel
            self._url = url
            let viewController = DocumentEditorViewController(viewModel: viewModel)
            viewController.title = url.packageName
            self.viewController = viewController
        }
    }
    
    deinit {
        self.dependency.editorContext.end(with: self._url)
    }
    
    public func toggleFullScreen() {
        (self.rootCoordinator as? Application)?.homeCoordinator?.toggleFullScreen()
    }
    
    public func showOutline(ignoredHeadingLocation: Int? = nil, from: UIView? = nil, completion: @escaping (OutlineLocation) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        navigationController.isNavigationBarHidden = true
        let coordinator = EditorCoordinator(stack: navigationController, dependency: self.dependency, usage: EditorCoordinator.Usage.outline(self._viewModel.url, ignoredHeadingLocation))
        coordinator.didSelectOutlineSelectionAction = { [weak coordinator] selection in
            coordinator?.stop(animated: true, completion: {
                completion(selection)
            })
        }
        coordinator.didCancelSelectionOutlineSelectionAction = { [weak coordinator] in
            coordinator?.stop(animated: true, completion: {})
        }
        coordinator.fromView = from
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
    
    public func showAllAttachmentPicker(completion: @escaping (Attachment) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let attachmentPickerCoordinator = AttachmentManagerCoordinator(stack: navigationController, dependency: self.dependency, usage: .pick)
        attachmentPickerCoordinator.onSelectAttachment = { [unowned attachmentPickerCoordinator] attachment in
            attachmentPickerCoordinator.stop()
            
            if let attachment = attachment {
                completion(attachment)
            }
        }
        
        attachmentPickerCoordinator.start(from: self)
    }
        
    public func showLinkEditor(title: String, url: String, completeEdit: @escaping (String) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        let attachmentLinkCoordinator = AttachmentCoordinator(stack: navigationController, dependency: self.dependency, title: title, url: url)
        attachmentLinkCoordinator.onSaveAttachment = { key in
            if let attachment = self.dependency.attachmentManager.attachment(with: key) {
                let linkString = OutlineParser.Values.Attachment.serialize(attachment: attachment)
                completeEdit(linkString)
                self.dependency.attachmentManager.delete(key: key, completion: {}, failure: { _ in })
            }
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
    
    public func showConfictResolver(from: UIViewController, viewModel: DocumentEditViewModel) {
        guard viewModel.isResolvingConflict == false else { return }
        viewModel.isResolvingConflict = true
        let resolverViewController = ConflictResolverViewController(viewModel: viewModel)
        let nav = Application.createDefaultNavigationControlller(root: resolverViewController, transparentBar: false)
        from.present(nav, animated: true)
    }
    
    public func showTempDocument(url: URL, from: UIViewController) {
        let documentCoordinator = EditorCoordinator(stack: self.stack, dependency: self.dependency,
                                                    usage: EditorCoordinator.Usage.temp(url))
        
        guard let vc = documentCoordinator.viewController else { return }
        
        from.navigationController?.pushViewController(vc, animated: true)
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

extension EditorCoordinator: HeadingsOutlineViewControllerDelegate {
    public func didCancel() {
        self.delegate?.didCancel(coordinator: self)
        self.didCancelSelectionOutlineSelectionAction?()
    }
    
    public func didSelect(url: URL, selection: OutlineLocation) {
        self.delegate?.didSelectOutline(url: url, selection: selection, coordinator: self)
        self.didSelectOutlineSelectionAction?(selection)
    }
}
