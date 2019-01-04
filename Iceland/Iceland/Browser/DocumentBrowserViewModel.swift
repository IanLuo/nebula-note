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
    func didLoadData()
    func didUpdate(index: Int)
}

public class DocumentBrowserViewModel {
    public weak var delegate: DocumentBrowserViewModelDelegate?
    public weak var dependency: BrowserCoordinator?
    private let documentManager: DocumentManager
    
    public var data: [DocumentBrowserCellModel] = []
    
    public init(documentManager: DocumentManager) {
        self.documentManager = documentManager
    }
    
    public func loadData() {
        do {
            self.data = try self.documentManager.query(in: URL.filesFolder).map { DocumentBrowserCellModel(url: $0) }
            self.delegate?.didLoadData()
        } catch {
            log.error(error)
        }
    }
    
    public func unfold(url: URL) {
        if let index = self.index(of: url) {
            do {
                // 读取所有当前文件的子文件
                let subDocuments = try self.documentManager.query(in: url.convertoFolderURL)
                    .map { DocumentBrowserCellModel(url: $0) }

                // 设置当前 cell 的状态为 unfoled
                self.data[index].isFolded = false

                // 插入文件数据
                data.insert(contentsOf: subDocuments, at: index + 1)
                
                // 更新新插入的数据
                self.delegate?.didAddDocument(index: index + 1, count: subDocuments.count)
                
                // 更新当前 cell 状态
                self.delegate?.didUpdate(index: index)
            } catch {
                log.error(error)
            }
        }
    }
    
    public func fold(url: URL) {
        if let index = self.index(of: url) {
            // 计算所选位置的所有子文件，包括子文件的子文件
            let count = self.subDocumentcount(index: index, recursively: true)
            for _ in 0..<count {
                // 从显示的数据中移除被 fold 的数据
                self.data.remove(at: index + 1)
            }
            
            // 标记当前 cell 的状态
            self.data[index].isFolded = true

            // 耿直界面移除删除掉的数据
            self.delegate?.didRemoveDocument(index: index + 1, count: count)
            
            // 更新当前 cell
            self.delegate?.didUpdate(index: index)
        }
    }
    
    /// 计算子文件夹中的文件数量
    /// - parameter index: 需要计算的子文件夹的位置
    /// - parameter recursively: 是否计算子文件的子文件
    private func subDocumentcount(index: Int, recursively: Bool = false) -> Int {
        guard index < self.data.count - 1 else { return 0 }
        
        let currentLevel = self.data[index].levelFromRoot
        var subDocumentCount: Int = 0
        
        var condition: (DocumentBrowserCellModel) -> Bool
        if recursively {
            condition = { return currentLevel < $0.levelFromRoot }
        } else {
            condition = { return $0.levelFromRoot - currentLevel == 1 }
        }
        
        for i in index + 1..<self.data.count {
            if condition(self.data[i]) {
                subDocumentCount += 1
            } else {
                return subDocumentCount
            }
        }

        return subDocumentCount
    }
    
    public func index(of url: URL) -> Int? {
        for (index, cellModel) in self.data.enumerated() {
            if cellModel.url == url {
                return index
            }
        }
        
        return nil
    }
    
    func createDocument(below: URL?) {
        self.documentManager.add(title: "untitled", below: below) { url in
            if let url = url {
                var index: Int = self.data.count
                if let below = below {
                    if let i = self.index(of: below) {
                        let subCount = self.subDocumentcount(index: i) // 计算子文件的数量，将新文件插入到子文件的末尾
                        index = subCount + i + 1
                    }
                }
                
                // 插入新的 cell 并更新界面
                self.data.insert(DocumentBrowserCellModel(url: url), at: index)
                self.delegate?.didAddDocument(index: index, count: 1)
                
                // 更新父 cell 的状态
                if below != nil {
                    self.data[index - 1].isFolded = false
                    self.delegate?.didUpdate(index: index - 1)
                }
            }
        }
    }
    
    func deleteDocument(index: Int) {
        self.documentManager.delete(url: self.data[index].url) { error in
            if let error = error {
                log.error(error)
            } else {
                // 当前显示的子文件个数
                let subcount = self.subDocumentcount(index: index, recursively: true)
                // 一次删除当前文件以及子文件
                for _ in 0..<subcount + 1 {
                    self.data.remove(at: index)
                }
                // 通知界面更新
                self.delegate?.didRemoveDocument(index: index, count: subcount + 1)
            }
        }
    }
    
    func rename(index: Int,
                to: String) {
        let url = self.data[index].url
        self.documentManager.rename(url: url,
                                    to: "new name",
                                    below: nil,
                                    completion: { url in
                                        self.data[index].url = url
                                        for i in index..<index + self.subDocumentcount(index: index, recursively: true) {
                                            self.data[i].parent = url
                                        }
                                        self.delegate?.didRenameDocument(index: index)
                                        self.delegate?.didUpdate(index: index)
                                        
        },
                                    failure: { error in
                                        log.error(error)
        })
    }
    
    public func duplicate(index: Int) {
        self.documentManager.duplicate(url: self.data[index].url,
                                       complete: { [weak self] in
                                        self?.delegate?.didAddDocument(index: index + 1, count: 1)
            }, failure: { error in
                log.error(error)
        })
    }
}
