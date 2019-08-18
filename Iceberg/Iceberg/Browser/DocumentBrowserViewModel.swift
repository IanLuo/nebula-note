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
    func didUpdateCell(index: Int)
}

public class DocumentBrowserViewModel {
    public weak var delegate: DocumentBrowserViewModelDelegate?
    public weak var coordinator: BrowserCoordinator? {
        didSet {
            self._setupObservers()
        }
    }
    private let documentManager: DocumentManager
    
    public var data: [DocumentBrowserCellModel] = []
    
    public init(documentManager: DocumentManager) {
        self.documentManager = documentManager
    }
    
    deinit {
        self.coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public var shouldShowActions: Bool {
        return self.coordinator?.usage == .chooseDocument
    }
    
    public var shouldShowHeadingIndicator: Bool {
        return self.coordinator?.usage == .chooseHeading
    }
    
    public func setCover(_ cover: UIImage?, index: Int) {
        self.documentManager.setCover(cover, url: self.data[index].url)
    }
    
    public func isNameAvailable(newName: String, index: Int) -> Bool {
        var newURL = self.data[index].url
        newURL.deleteLastPathComponent()
        newURL = newURL.appendingPathComponent(newName).appendingPathExtension(Document.fileExtension)
        return !FileManager.default.fileExists(atPath: newURL.path)
    }
    
    public func loadData() {
        do {
            self.data = try self.documentManager.query(in: URL.documentBaseURL).map { [unowned self] in
                let cellModel = DocumentBrowserCellModel(url: $0)
                cellModel.shouldShowActions = self.shouldShowActions
                cellModel.shouldShowChooseHeadingIndicator = self.shouldShowHeadingIndicator
                cellModel.cover = self.documentManager.cover(url: $0)
                return cellModel
            }
            self.delegate?.didLoadData()
        } catch {
            log.error(error)
        }
    }
    
    public func loadAllFiles(completion: ([DocumentBrowserCellModel]) -> Void) {
        do {
            let files = try self.documentManager.query(in: URL.documentBaseURL, recursively: true).map { [unowned self] (url: URL) -> DocumentBrowserCellModel in
                let cellModel = DocumentBrowserCellModel(url: url)
                cellModel.shouldShowActions = self.shouldShowActions
                cellModel.shouldShowChooseHeadingIndicator = self.shouldShowHeadingIndicator
                cellModel.cover = self.documentManager.cover(url: url)
                return cellModel
            }
            completion(files)
        } catch {
            log.error(error)
        }
    }
    
    public func unfold(url: URL) {
        if let index = self.index(of: url) {
            // 读取所有当前文件的子文件
            let subDocuments: [DocumentBrowserCellModel] = self.loadSubfolderData(url: url, recursively: false)
            
            // 设置当前 cell 的状态为 unfoled
            self.data[index].isFolded = false
            
            // 插入文件数据
            data.insert(contentsOf: subDocuments, at: index + 1)
            
            // 更新新插入的数据
            self.delegate?.didAddDocument(index: index + 1, count: subDocuments.count)
        }
    }
    
    private func loadSubfolderData(url: URL, recursively: Bool) -> [DocumentBrowserCellModel] {
        var cellModels: [DocumentBrowserCellModel] = []
        
        do {
            let urls = try self.documentManager.query(in: url.convertoFolderURL)
            
            urls.forEach {
                let cellModel = DocumentBrowserCellModel(url: $0)
                cellModel.shouldShowActions = self.shouldShowActions
                cellModel.shouldShowChooseHeadingIndicator = self.shouldShowHeadingIndicator
                cellModels.append(cellModel)
                if recursively {
                    let subCellModels = self.loadSubfolderData(url: $0, recursively: true)
                    if subCellModels.count > 0 {
                        cellModel.isFolded = false
                        cellModels.append(contentsOf: subCellModels)
                    }
                }
            }
        } catch {
            log.error(error)
        }
        
        return cellModels
    }
    
    public func fold(url: URL) {
        if let index = self.index(of: url) {
            // 计算所选位置的所有子文件，包括子文件的子文件
            let count = self.visualSubDocumentcount(index: index, recursively: true)
            for _ in 0..<count {
                // 从显示的数据中移除被 fold 的数据
                self.data.remove(at: index + 1)
            }
            
            // 标记当前 cell 的状态
            self.data[index].isFolded = true

            // 通知界面移除删除掉的数据
            self.delegate?.didRemoveDocument(index: index + 1, count: count)
        }
    }
    
    /// 计算子文件夹中的文件数量
    /// - parameter index: 需要计算的子文件夹的位置
    /// - parameter recursively: 是否计算子文件的子文件
    private func visualSubDocumentcount(index: Int, recursively: Bool = false) -> Int {
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
    
    func createDocument(title: String, below: URL?) {
        self.documentManager.add(title: title, below: below) { url in
            if let url = url {
                var index: Int = self.data.count
                if let below = below {
                    if let i = self.index(of: below) {
                        let subCount = self.visualSubDocumentcount(index: i) // 计算子文件的数量，将新文件插入到子文件的末尾
                        index = subCount + i + 1
                    }
                }
                
                // 插入新的 cell 并更新界面
                self.data.insert(DocumentBrowserCellModel(url: url), at: index)
                self.delegate?.didAddDocument(index: index, count: 1)
                
                // 更新父 cell 的状态
                if below != nil {
                    self.data[index - 1].isFolded = false
                    self.delegate?.didUpdateCell(index: index - 1)
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
                let subcount = self.visualSubDocumentcount(index: index, recursively: true)
                // 一次删除当前文件以及子文件
                for _ in 0..<subcount + 1 {
                    self.data.remove(at: index)
                }
                // 通知界面更新
                self.delegate?.didRemoveDocument(index: index, count: subcount + 1)
            }
        }
    }
    
    func move(url: URL,
              to: URL) {
        let fileName = url.packageName
        
        self.documentManager.rename(url: url,
                                    to: fileName,
                                    below: to,
                                    completion: { [unowned self] newURL in
                                        for (index, data) in self.data.enumerated() {
                                            // 移除改名后的文件
                                            if data.url.documentRelativePath == url.documentRelativePath {
                                                self.data.remove(at: index)
                                                break
                                            }
                                        }
                                        
                                        for (index, data) in self.data.enumerated() {
                                            if data.url.documentRelativePath == to.documentRelativePath
                                                && data.isFolded == false {
                                                // 添加到移到的位置(如果当前显示了上级文件)
                                                self.data.insert(DocumentBrowserCellModel(url: newURL), at: index + 1)
                                                break
                                            }
                                        }
                                        
                                        if newURL.parentDocumentURL == nil {
                                            self.data.insert(DocumentBrowserCellModel(url: newURL), at: 0)
                                        }
                                        
                                        self.delegate?.didLoadData()
                                    },
                                        failure: { error in
                                            log.error(error)
                                    })
    }
    
    func rename(index: Int,
                to: String) {
        let url = self.data[index].url
        self.documentManager.rename(url: url,
                                    to: to,
                                    below: nil,
                                    completion: { url in
                                        self.data[index].url = url
                                        self.delegate?.didRenameDocument(index: index)
                                        self.delegate?.didUpdateCell(index: index)
                                        self.fold(url: url)
        },
                                    failure: { error in
                                        log.error(error)
        })
    }
    
    public func duplicate(index: Int, copyExt: String) {
        self.documentManager.duplicate(url: self.data[index].url,
                                       copyExt: copyExt,
                                       complete: { [weak self] url in
                                        self?.data.insert(DocumentBrowserCellModel(url: url), at: index)
                                        self?.delegate?.didAddDocument(index: index, count: 1)
            }, failure: { error in
                log.error(error)
        })
    }
    
    private func _setupObservers() {
        let eventObserver = self.coordinator?.dependency.eventObserver
        
        eventObserver?.registerForEvent(on: self, eventType: iCloudEnabledEvent.self, queue: nil, action: { [weak self] (event: iCloudEnabledEvent) in
            self?.loadData()
        })
        
        eventObserver?.registerForEvent(on: self, eventType: iCloudDisabledEvent.self, queue: nil, action: { [weak self] (event: iCloudDisabledEvent) in
            self?.loadData()
        })
        
        eventObserver?.registerForEvent(on: self, eventType: AddDocumentEvent.self, queue: nil, action: { [weak self] (event: AddDocumentEvent) -> Void in
            self?.loadData()
        })
        
        eventObserver?.registerForEvent(on: self,
                                        eventType: iCloudOpeningStatusChangedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                            
                                            self?.loadData()
        })
        
        eventObserver?.registerForEvent(on: self,
                                        eventType: NewDocumentPackageDownloadedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
                                            let newDocumentURL = event.url
                                            let newDocumentParentURL = event.url.parentDocumentURL
                                            
                                            if newDocumentParentURL == nil {
                                                self?.data.append(DocumentBrowserCellModel(url: newDocumentURL))
                                            } else {
                                                for (index, cellModel) in (self?.data ?? []).enumerated() {
                                                    if cellModel.url.documentRelativePath == newDocumentParentURL?.documentRelativePath {
                                                        self?.data.insert(DocumentBrowserCellModel(url: newDocumentURL), at: index + 1)
                                                    }
                                                }
                                            }
        })
    }
}
