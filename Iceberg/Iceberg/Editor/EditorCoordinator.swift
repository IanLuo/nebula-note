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
    
    private var _viewModel: DocumentEditorViewModel!
    
    public var didSelectOutlineSelectionAction: ((OutlineLocation) -> Void)?
    public var didCancelSelectionOutlineSelectionAction: (() -> Void)?
    
    public private(set) var url: URL!
    
    public init(stack: UINavigationController, dependency: Dependency, usage: Usage) {
        self.usage = usage
        super.init(stack: stack, dependency: dependency)
        
        switch usage {
        case .editor(let url, let location):
            let viewModel = DocumentEditorViewModel(editorService: dependency.editorContext.request(url: url), coordinator: self)
            viewModel.onLoadingLocation = location
            self._viewModel = viewModel
            self.url = url
            let viewController = DocumentEditorViewController(viewModel: viewModel)
            viewController.title = url.packageName
            self.viewController = viewController
        case .outline(let url, let ignoredHeadingLocation):
            let viewModel = DocumentEditorViewModel(editorService: dependency.editorContext.request(url: url), coordinator: self)
            self._viewModel = viewModel
            self.url = url
            let viewController = HeadingsOutlineViewController(viewModel: viewModel)
            viewController.ignoredHeadingLocation = ignoredHeadingLocation
            viewController.outlineDelegate = self
            viewController.title = url.packageName
            self.viewController = viewController
        case .temp(let url):
            let viewModel = DocumentEditorViewModel(editorService: dependency.editorContext.request(url: url), coordinator: self)
            self._viewModel = viewModel
            self.url = url
            let viewController = DocumentEditorViewController(viewModel: viewModel)
            viewController.title = url.packageName
            self.viewController = viewController
        }
    }
    
    public func showOutline(ignoredHeadingLocation: Int? = nil, from: UIView? = nil, point: CGPoint? = nil, completion: @escaping (OutlineLocation) -> Void) {
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
        
        coordinator.fromLocation = point
        coordinator.fromView = from
        coordinator.start(from: self)
    }
    
    public func showDocumentHeadingPicker(completion: @escaping (URL, OutlineLocation) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
            
        let documentCoord = BrowserCoordinator(stack: navigationController,
                                               dependency: super.dependency,
                                               usage: .chooseHeader)
        
        documentCoord.didSelectOutlineAction = { [weak documentCoord] url, outlineLocation in
            documentCoord?.stop()
            completion(url, outlineLocation)
        }
        
        documentCoord.didCancelAction = { [weak documentCoord] in
            documentCoord?.stop()
        }
        
        if #available(macOS 11, *) {
            documentCoord.viewController?.modalPresentationStyle = .fullScreen
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
        
    public func showLinkEditor(title: String, url: String, from: UIView, location: CGPoint?, completeEdit: @escaping (String) -> Void) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        let attachmentLinkCoordinator = AttachmentCoordinator(stack: navigationController, dependency: self.dependency, title: title, url: url, at: self.fromView, location: self.fromLocation)
        attachmentLinkCoordinator.onSaveAttachment = { key in
            if let attachment = self.dependency.attachmentManager.attachment(with: key) {
                let linkString = OutlineParser.Values.Attachment.serialize(attachment: attachment)
                completeEdit(linkString)
                self.dependency.attachmentManager.delete(key: key, completion: {}, failure: { _ in })
            }
        }
        
        attachmentLinkCoordinator.fromView = from
        attachmentLinkCoordinator.fromLocation = location
        attachmentLinkCoordinator.start(from: self)
    }
        
    public func showPublish(from: UIViewController, url: URL) {
        let viewController = PublishViewController(url: url, viewModel: self._viewModel)
        let navigationController = Coordinator.createDefaultNavigationControlller(root: viewController, transparentBar: false)
        from.present(navigationController, animated: true)
    }
    
    public func loadAllTags() -> [String] {
        if let home = self.rootCoordinator.searchFirstCoordinator(type: HomeCoordinator.self) {
            return home.getAllTags()
        } else {
            return []
        }
    }
    
    public func showConfictResolverIfFoundConflictVersions(from: UIViewController, viewModel: DocumentEditorViewModel) {
        guard viewModel.isResolvingConflict == false else { return }
        viewModel.isResolvingConflict = true
        let resolverViewController = ConflictResolverViewController(viewModel: viewModel)
        
        guard resolverViewController.shouldShow else { return }
        
        let nav = Application.createDefaultNavigationControlller(root: resolverViewController, transparentBar: false)
        from.present(nav, animated: true)
    }
    
    public func showTempDocument(url: URL, from: UIViewController) {
        let documentCoordinator = EditorCoordinator(stack: self.stack, dependency: self.dependency,
                                                    usage: EditorCoordinator.Usage.temp(url))
        
        guard let vc = documentCoordinator.viewController else { return }
        
        from.navigationController?.pushViewController(vc, animated: true)
    }
    
    public func showDocumentBrowser(completion: @escaping (URL) -> Void) {
        let coor = BrowserCoordinator(stack: Application.createDefaultNavigationControlller(), dependency: self.dependency, usage: .browseDocument)
        coor.didSelectDocumentAction = { [weak coor] url in
            coor?.stop()
            completion(url)
        }
        
        coor.didCancelAction = { [weak coor] in
            coor?.stop()
        }
        
        coor.start(from: self)
    }
    
    public func openDocumentLink(link: String) {
        let url = URL.documentBaseURL.appendingPathComponent(OutlineParser.Values.Link.removeScheme(link: link))
        
        if let idMatchResult = try! NSRegularExpression(pattern: "(\\{.*\\})", options: []).firstMatch(in: url.path, options: [], range: NSRange(location: 0, length: url.path.count)) {
            let idRange = idMatchResult.range(at: 1)
            let id = url.path.nsstring.substring(with: idRange).trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
            
            self.dependency.documentSearchManager.search(contain: id, cancelOthers: true) { results in
                if let firstResult = results.first {
                    let documentInfo = firstResult.documentInfo
                    let url = documentInfo.url
                    
                    let offset = firstResult.heading?.range.upperBound ?? 0
                    
                    if isMacOrPad {
                        self.dependency.eventObserver.emit(OpenDocumentEvent(url: url, location: offset))
                    } else {
                        let editorCoor = EditorCoordinator(stack: self.stack, dependency: self.dependency, usage: .editor(url, offset))
                        editorCoor.start(from: self)
                    }
                }
            } failed: { error in
                print(error)
            }
        } else {
            var location = 0
            var url = url
            if url.pathExtension == "" {
                location = Int(url.lastPathComponent) ?? 0
                url = url.deletingLastPathComponent()
            }
            
            if FileManager.default.fileExists(atPath: url.path) {
                if isMacOrPad {
                    self.dependency.eventObserver.emit(OpenDocumentEvent(url: url, location: location))
                } else {
                    let editorCoor = EditorCoordinator(stack: self.stack, dependency: self.dependency, usage: .editor(url, location))
                    editorCoor.start(from: self)
                }
            } else {
                self.viewController?.showAlert(title: L10n.Browser.fileNotExisted, message: L10n.Browser.FileNotExisted.message)
            }
        }
    }
    
    public func openDocument(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            if isMacOrPad {
                self.dependency.eventObserver.emit(OpenDocumentEvent(url: url))
            } else {
                let editorCoor = EditorCoordinator(stack: self.stack, dependency: self.dependency, usage: .editor(url, 0))
                editorCoor.start(from: self)
            }
        } else {
            self.viewController?.showAlert(title: L10n.Browser.fileNotExisted, message: L10n.Browser.FileNotExisted.message)
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
    
    public func showDocumentInfo(viewModel: DocumentEditorViewModel, completion: @escaping () -> Void) {
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
