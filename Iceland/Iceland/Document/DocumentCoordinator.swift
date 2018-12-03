//
//  DocumentCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class DocumentCoordinator: Coordinator {
    private let viewController: DocumentEditViewController
    
    public init(stack: UINavigationController, newFileTitle title: String) {
        let pageViewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                  title: title)
        self.viewController = DocumentEditViewController(viewModel: pageViewModel)
        super.init(stack: stack)
    }
    
    public init(stack: UINavigationController, editFile url: URL) {
        let pageViewModel = DocumentEditViewModel(editorController: EditorController(parser: OutlineParser()),
                                                  url: url)
        self.viewController = DocumentEditViewController(viewModel: pageViewModel)
        super.init(stack: stack)
    }
    
    public override func start() {
        self.stack.pushViewController(self.viewController, animated: true)
    }
}
