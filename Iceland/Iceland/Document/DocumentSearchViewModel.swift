//
//  DocumentSearchViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol DocumentSearchDelegate: class {
    func didFoundDocuments(documents: [URL])
    func didFailToSearchDocument(error: Error)
}

public class DocumentSearchViewModel {
    public weak var delegate: DocumentSearchDelegate?
    
    public func search(tags: [String]) {
        // TODO: search by tags(one or many)
    }
    
    public func search(contain: String) {
        // TODO: search by content of text
    }
    
    public func search(sechedule: Date) {
        // TODO: search by schedule date
    }
    
    public func search(deadline: Date) {
        // TODO: search by deadline
    }
}
