//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

/// 用户的活动中心
/// 每天的任务安排显示在此处
public class AgendaCoordinator: Coordinator {
    private let documentManager: DocumentManager
    private let documentSearchManager: DocumentSearchManager
    
    public init(stack: UINavigationController,
                documentSearchManager: DocumentSearchManager,
                documentManager: DocumentManager) {
        let viewModel = AgendaViewModel(documentSearchManager: documentSearchManager)
        let viewController = AgendaViewController(viewModel: viewModel)
        self.documentManager = documentManager
        self.documentSearchManager = documentSearchManager
        super.init(stack: stack)
        self.viewController = viewController
        viewModel.delegate = viewController
        viewModel.dependency = self
    }
}

extension AgendaCoordinator {
    public func openAgendaActions(url: URL, heading: OutlineTextStorage.Heading) {
        let viewModel = AgendaActionViewModel(service: OutlineEditorServer.request(url: url), heading: heading)
        let viewController = AgendaActionViewController(viewModel: viewModel)
        viewModel.delegate = viewController
        viewController.delegate = self
        viewController.modalPresentationStyle = .overCurrentContext
        self.stack.present(viewController, animated: true, completion: nil)
    }
    
    public func openDocument(url: URL, location: Int) {
        let docCood = EditorCoordinator(stack: self.stack,
                                        usage: EditorCoordinator.Usage.editor(url, location))
        docCood.start(from: self)
    }
}

extension AgendaCoordinator: AgendaActionViewControllerDelegate {
    public func openDocument(url: URL) {
        let docCood = EditorCoordinator(stack: self.stack,
                                        usage: .editor(url, 0))
        docCood.start(from: self)
    }
}
