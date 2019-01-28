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
    func didSelectDocument(url: URL, location: Int, searchCoordinator: SearchCoordinator)
    func didCancelSearching()
}

public class SearchCoordinator: Coordinator {
    public weak var delegate: SearchCoordinatorDelegate?
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        let viewModel = DocumentSearchViewModel(documentSearchManager: dependency.documentSearchManager)
        let viewController = DocumentSearchViewController(viewModel: viewModel)
        super.init(stack: stack, dependency: dependency)
        viewController.delegate = self
        self.viewController = viewController
        viewModel.coordinator = self
    }
}

extension SearchCoordinator: DocumentSearchViewControllerDelegate {
    public func didSelectDocument(url: URL, location: Int) {
        self.delegate?.didSelectDocument(url: url, location: location, searchCoordinator: self)
    }
    
    public func didCancelSearching() {
        self.stop()
    }
}
