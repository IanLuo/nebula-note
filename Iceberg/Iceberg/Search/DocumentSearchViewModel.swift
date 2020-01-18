//
//  DocumentSearchViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Core

public protocol DocumentSearchViewModelDelegate: class {
    func didCompleteSearching()
    func didClearResults()
}

public class DocumentSearchViewModel {
    public weak var delegate: DocumentSearchViewModelDelegate?
    public weak var coordinator: SearchCoordinator?
    
    private let documentSearchManager: DocumentSearchManager
    
    public init(documentSearchManager: DocumentSearchManager) {
        self.documentSearchManager = documentSearchManager
        
        self._setupObservers()
    }
    
    deinit {
        self.coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public var data: [SearchTabelCellModel] = []
    
    public var allDocumentsTags: [String] = []
    
    public var allDocumentsPlannings: [String] = []
    
    public func search(query: String) {
        self.documentSearchManager.search(contain:query, completion: { [weak self] results in
            self?.data = results.map { SearchTabelCellModel(searchResult: $0) }
            self?.delegate?.didCompleteSearching()
        }) { error in
            log.error(error)
        }
    }
    
    public func clearSearchResults() {
        self.data = []
        self.delegate?.didClearResults()
    }
    
    private func _setupObservers() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: iCloudOpeningStatusChangedEvent.self, queue: .main, action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
            self?.clearSearchResults()
        })
    }
}
