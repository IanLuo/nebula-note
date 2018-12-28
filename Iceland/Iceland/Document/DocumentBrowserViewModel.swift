//
//  DocumentBrowserViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Storage

public protocol DocumentBrowserViewModelDelegate: class {

}

public class DocumentBrowserViewModel {
    public weak var delegate: DocumentBrowserViewModelDelegate?
    
    public weak var dependency: DocumentCoordinator?
    
    private let documentManager: DocumentManager
    
    public init(documentManager: DocumentManager) {
        self.documentManager = documentManager
    }
    
    func findDocuments(under: URL?) throws -> [URL] {
        if let under = under {
            return try self.documentManager.query(in: under.convertoFolderURL)
        } else {
            return try self.documentManager.query(in: URL.filesFolder)
        }
    }
    
    func createDocument(title: String,
                        below: URL?,
                        completion: ((URL?) -> Void)? = nil) {
        self.documentManager.add(title: title, below: below, completion: completion)
    }
    
    func deleteDocument(url: URL,
                        completion: ((Error?) -> Void)? = nil) {
        self.documentManager.delete(url: url, completion: completion)
    }
    
    func rename(url: URL,
                to: String,
                below: URL?,
                completion: ((Error?) -> Void)? = nil) {
        self.documentManager.rename(url: url, to: to, below: below, completion: completion)
    }
}
