//
//  SearchCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol SearchCoordinatorDelegate: class {
    func didSelectDocument(url: URL)
}

public class SearchCoordinator: Coordinator {
    public weak var delegate: SearchCoordinatorDelegate?
    
    public override init(stack: UINavigationController, context: Context) {
        let viewModel = DocumentSearchViewModel(documentSearchManager: context.documentSearchManager)
        let viewController = DocumentSearchViewController(viewModel: viewModel)
        super.init(stack: stack, context: context)
        viewController.delegate = self
        self.viewController = viewController
    }
}

extension SearchCoordinator: DocumentSearchViewControllerDelegate {
    public func didSelectDocument(url: URL) {
        self.delegate?.didSelectDocument(url: url)
    }
}
