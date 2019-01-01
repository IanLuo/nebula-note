//
//  DocumentBrowserViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol DocumentBrowserViewModelDelegate: class {
    func didAddDocument(index: Int, count: Int)
    func didRemoveDocument(index: Int, count: Int)
    func didRenameDocument(index: Int)
}

public class DocumentBrowserViewModel {
    public weak var delegate: DocumentBrowserViewModelDelegate?
    public weak var dependency: BrowserCoordinator?
    private let documentManager: DocumentManager
    
    public var data: [DocumentBrowserCellModel] = []
    
    public init(documentManager: DocumentManager) {
        self.documentManager = documentManager
    }
    
    public func unfold(url: URL) {
        if let index = self.index(of: url) {
            do {
                let subDocuments = try self.documentManager.query(in: url)
                    .map { DocumentBrowserCellModel(url: $0) }
                data.insert(contentsOf: subDocuments, at: index)
                self.delegate?.didAddDocument(index: index, count: subDocuments.count)
            } catch {
                // ignore
            }
        }
    }
    
    public func fold(url: URL) {
        if let index = self.index(of: url) {
            let count = self.subDocumentcount(index: index)
            for i in 0..<count {
                self.data.remove(at: i)
            }
            self.delegate?.didRemoveDocument(index: index, count: count)
        }
    }
    
    private func subDocumentcount(index: Int) -> Int {
        guard index < self.data.count - 1 else { return 0 }
        
        var subDocumentCount: Int = 0
        for i in index + 1..<self.data.count {
            let cellModel = self.data[i]
            if cellModel.parent == self.data[index].url {
                subDocumentCount += 1
            } else {
                return subDocumentCount
            }
        }

        return subDocumentCount
    }
    
    private func index(of url: URL) -> Int? {
        for (index, cellModel) in self.data.enumerated() {
            if cellModel.url == url {
                return index
            }
        }
        
        return nil
    }
    
    func findDocuments(under: URL?) throws -> [URL] {
        if let under = under {
            return try self.documentManager.query(in: under.convertoFolderURL)
        } else {
            return try self.documentManager.query(in: URL.filesFolder)
        }
    }
    
    func createDocument(below: URL?) {
        self.documentManager.add(title: "untitled", below: below) { url in
            if let url = url {
                var index: Int = self.data.count
                if let below = below {
                    if let i = self.index(of: below) {
                        let subCount = self.subDocumentcount(index: i)
                        index = subCount + i + 1
                    }
                }
                
                self.data.insert(DocumentBrowserCellModel(url: url), at: index)
                self.delegate?.didAddDocument(index: index, count: 1)
            }
        }
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
