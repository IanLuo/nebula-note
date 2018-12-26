//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

/// 用户的活动中心
/// 1. 每天的任务安排显示在此处
/// 2. capture 的内容显示在此处

/// 不管是任务，还是 capture 的内容，都可以直接编辑，可以使用 document 中的格式，方便临时的任务记录
public class AgendaCoordinator: Coordinator {
    public var viewController: UIViewController
    private let documentManager: DocumentManager
    private let documentSearchManager: DocumentSearchManager
    
    public init(stack: UINavigationController,
                documentSearchManager: DocumentSearchManager,
                documentManager: DocumentManager) {
        let viewModel = AgendaViewModel(documentSearchManager: documentSearchManager)
        let viewController = AgendaViewController(viewModel: viewModel)
        self.documentManager = documentManager
        self.documentSearchManager = documentSearchManager
        self.viewController = viewController
        super.init(stack: stack)
        viewModel.delegate = viewController
        viewModel.dependency = self
    }
    
    public override func start() {
        self.stack.pushViewController(viewController, animated: true)
    }
}

extension AgendaCoordinator {
    public func openDocument(url: URL, location: Int) {
        let docCood = DocumentCoordinator(stack: self.stack,
                                          usage: .editor(url, location),
                                          documentManager: self.documentManager,
                                          documentSearchManager: self.documentSearchManager)
        self.addChild(docCood)
        docCood.start()
    }
}
