//
//  Capture.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit.UIImage

public class CaptureCoordinator: Coordinator {
    private let documentManager: DocumentManager
    private let documentSearchManager: DocumentSearchManager
    
    private let captureService = CaptureService()
    
    private var listViewModel: CaptureListViewModel?
    private var captureViewModel: CaptureViewModel?
    
    public init(stack: UINavigationController, documentManager: DocumentManager, documentSearchManager: DocumentSearchManager) {
        let listViewModel = CaptureListViewModel(service: self.captureService)
        let viewController = CatpureListViewController(viewModel: listViewModel)
        
        self.documentManager = documentManager
        self.documentSearchManager = documentSearchManager
        self.listViewModel = listViewModel
        super.init(stack: stack)
        self.viewController = viewController
    }
    
    public init(stack: UINavigationController, type: Attachment.AttachmentType, documentManager: DocumentManager, documentSearchManager: DocumentSearchManager) {
        self.documentManager = documentManager
        self.documentSearchManager = documentSearchManager
        
        let captureViewModel = CaptureViewModel(service: self.captureService)
        
        super.init(stack: stack)

        switch type {
        case .text:
            viewController = CaptureTextViewController(viewModel: captureViewModel)
        case .link:
            viewController = CaptureLinkViewController(viewModel: captureViewModel)
        case .image:
            viewController = CaptureImageViewController(viewModel: captureViewModel)
        case .sketch:
            viewController = CaptureSketchViewController(viewModel: captureViewModel)
        case .location:
            viewController = CaptureLocationViewController(viewModel: captureViewModel)
        case .audio:
            viewController = CaptureAudioViewController(viewModel: captureViewModel)
        case .video:
            viewController = CaptureVideoViewController(viewModel: captureViewModel)
        }
    }
    
    public func chooseDocumentHeadingForRefiling() {
        let documentCood = DocumentManagementCoordinator(stack: self.stack,
                                             usage: .pickHeading,
                                             documentManager: self.documentManager,
                                             documentSearchManager: self.documentSearchManager)
        documentCood.delegate = self

        documentCood.start(from: self)
    }
}

extension CaptureCoordinator: DocumentManagementCoordinatorDelegate {
    public func didPickDocument(url: URL, location: Int) {
        // ignore
    }
    
    public func didPickHeading(url: URL, heading: OutlineTextStorage.Heading) {
        // FIXME: 添加缓存提高多次 refile 的性能
        listViewModel?.refile(editViewModel: DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                                   document: Document(fileURL: url)),
                              heading: heading)
    }
}
