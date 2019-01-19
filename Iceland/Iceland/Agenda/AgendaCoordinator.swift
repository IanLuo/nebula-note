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
    public override init(stack: UINavigationController, context: Context) {
        let viewModel = AgendaViewModel(documentSearchManager: context.documentSearchManager)
        let viewController = AgendaViewController(viewModel: viewModel)
        super.init(stack: stack, context: context)
        self.viewController = viewController
        viewModel.delegate = viewController
        viewModel.dependency = self
    }
    
    public override func moveIn(top: UIViewController?, animated: Bool) {
        guard let viewController = self.viewController else { return }
        
        top?.present(viewController, animated: true, completion: nil)
    }
    
    public override func moveOut(top: UIViewController, animated: Bool) {
        top.dismiss(animated: true)
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
                                        context: self.context,
                                        usage: EditorCoordinator.Usage.editor(url, location))
        docCood.start(from: self)
    }
}

extension AgendaCoordinator: AgendaActionViewControllerDelegate {
    public func openDocument(url: URL) {
        let docCood = EditorCoordinator(stack: self.stack,
                                        context: self.context,
                                        usage: .editor(url, 0))
        docCood.start(from: self)
    }
}
