//
//  TrashViewModel.swift
//  Iceberg
//
//  Created by ian luo on 2019/12/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Business

public struct TrashSection {
    public var items: [TrashCellModel]
}

extension TrashSection: SectionModelType {
    public typealias Item = TrashCellModel
    public init(original: TrashSection, items: [TrashCellModel]) {
        self = original
        self.items = items
    }
}


public class TrashViewModel: ViewModelProtocol {
    public required init() {}
    
    public var context: ViewModelContext<TrashCoordinator>!
    
    public typealias CoordinatorType = TrashCoordinator
        
    public struct Output {
        let documents: BehaviorRelay<[TrashSection]> = BehaviorRelay(value: [])
    }
    
    public let output: Output = Output()

    public func loadData() {
        guard let trashCoordinator = self.context.coordinator else { return }
        
        trashCoordinator.dependency.documentSearchManager.searchTrash() {
            let cellModels = $0.map { TrashCellModel(url: $0) }
            self.output.documents.accept([TrashSection(items: cellModels)])
        }
    }
    
    public func delete(index: Int) {
        guard let url = self.output.documents.value.first?.items[index].url else { return }
        
        url.delete(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)) { error in
            if let error = error {
                log.error(error)
            } else {
                if FileManager.default.fileExists(atPath: url.convertoFolderURL.path, isDirectory: nil) {
                    url.convertoFolderURL.delete(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)) { error in
                        if let error = error {
                            log.error(error)
                            self.loadData()
                        }
                    }
                }
                
                self.loadData()
            }
        }
    }
    
    public func fileName(at index: Int) -> String {
        guard let cellModel = self.output.documents.value.first?.items[index] else { return "" }
        
        return cellModel.name
    }
    
    public func url(at index: Int) -> URL? {
        return self.output.documents.value.first?.items[index].url
    }
    
    public func deleteAll() {
        var deleteURLs: (([URL], DispatchQueue) -> Void)!
            
           deleteURLs = { urls, queue in
            if let first = urls.first {
                first.delete(queue: queue) { error in
                    if let error =  error {
                        log.error(error)
                    } else {
                        if FileManager.default.fileExists(atPath: first.convertoFolderURL.path, isDirectory: nil) {
                            first.convertoFolderURL.delete(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)) { error in
                                if let error = error {
                                    log.error(error)
                                }
                            }
                        }
                        
                        var urls = urls
                        urls.remove(at: 0)
                        deleteURLs(urls, queue)
                    }
                }
            } else {
                self.loadData()
            }
        }
        
        if let items = self.output.documents.value.first?.items {
            deleteURLs(items.map { $0.url }, DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive))
        }
    }
    
    public func recover(index: Int) {
        guard let url = self.output.documents.value.first?.items[index].url else { return }
        
        let ext = url.pathExtension
        let fileName = url.packageName.replacingOccurrences(of: SyncCoordinator.Prefix.deleted.rawValue, with: "")
        let newURL = url.deletingLastPathComponent().appendingPathComponent(fileName).appendingPathExtension(ext)
        
        newURL.deletingLastPathComponent().createDirectoryIfNeeded { [weak self] error in
            if let error = error {
                log.error(error)
            }
            
            self?.context.coordinator?.dependency.documentManager.rename(url: url, to: fileName, below: url.deletingLastPathComponent(), completion: { url in
                self?.loadData()
                // notify UI update
                self?.context.coordinator?.dependency.eventObserver.emit(AddDocumentEvent(url: url))
            }, failure: { error in
                log.error(error)
            })
        }
    }
}

public class TrashCellModel {
    let url: URL
    let name: String
    public init(url: URL) {
        self.url = url
        self.name = url.packageName.replacingOccurrences(of: SyncCoordinator.Prefix.deleted.rawValue, with: "")
    }
}
