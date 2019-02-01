//
//  HomeViewModel.swift
//  Iceland
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Business

public protocol DashboardViewModelDelegate: class {
    func didLoadAllTags()
}

public class DashboardViewModel {
    public weak var coordinator: HomeCoordinator?
    private let documentSearchManager: DocumentSearchManager
    public weak var delegate: DashboardViewModelDelegate?
    
    public init(documentSearchManager: DocumentSearchManager) {
        self.documentSearchManager = documentSearchManager
    }
    
    public var allTags: [String] = []
    
    public func loadAllTags() {
        self.documentSearchManager.loadAllTags { [weak self] searchResult in
            self?.allTags = searchResult.map { $0.context }
            self?.delegate?.didLoadAllTags()
        }
    }
}
