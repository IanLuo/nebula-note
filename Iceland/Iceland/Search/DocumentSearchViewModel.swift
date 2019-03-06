//
//  DocumentSearchViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol DocumentSearchViewModelDelegate: class {
    func didAddResult(index: Int, count: Int)
    func didClearResults()
    func didCompleteSearching()
}

public class DocumentSearchViewModel {
    public weak var delegate: DocumentSearchViewModelDelegate?
    public weak var coordinator: SearchCoordinator?
    
    private let documentSearchManager: DocumentSearchManager
    
    public init(documentSearchManager: DocumentSearchManager) {
        self.documentSearchManager = documentSearchManager
    }
    
    public var data: [SearchTabelCellModel] = []
    
    public var allDocumentsTags: [String] = []
    
    public var allDocumentsPlannings: [String] = []
    
    public func loadAllTags() {
        
    }
    
    public func search(query: String) {
        self.documentSearchManager.search(contain: query, resultAdded: { [weak self] searchResults in
            let location = max(0, self?.data.count ?? 0 - 1)
            self?.data.append(contentsOf: searchResults.map { SearchTabelCellModel(searchResult: $0) })
            self?.delegate?.didAddResult(index: location, count: searchResults.count)
        }, complete: { [weak self] in
            self?.delegate?.didCompleteSearching()
        }) { error in
            log.error(error)
        }
    }
    
    public func clearSearchResults() {
        self.data = []
        self.delegate?.didClearResults()
    }
}
