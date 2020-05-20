//
//  BrowserRecentViewModel.swift
//  Iceberg
//
//  Created by ian luo on 2019/10/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Core

public struct RecentDocumentSection: SectionModelType {
    public var items: [BrowserCellModel]
    public var identity: String = UUID().uuidString
}

extension RecentDocumentSection {
    public typealias Item = BrowserCellModel
    public init(original: RecentDocumentSection, items: [BrowserCellModel]) {
        self = original
        self.items = items
    }
}

extension RecentDocumentSection: AnimatableSectionModelType {
    public typealias Identity = String
}

public class BrowserRecentViewModel: NSObject, ViewModelProtocol {
    public var context: ViewModelContext<BrowserCoordinator>!
    
    public typealias CoordinatorType = BrowserCoordinator
    
    public required override init() {
        super.init()
    }
    
    deinit {
        self.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public func didSetupContext() {
        self.setupObservers()
    }
    
    public struct Output {
        public let recentDocuments: BehaviorRelay<[RecentDocumentSection]> = BehaviorRelay(value: [])
    }
        
    public let output: Output = Output()
    
    private let disposeBag = DisposeBag()
    
    private func setupObservers() {
        self.dependency.eventObserver.registerForEvent(on: self, eventType: UIStackReadyEvent.self, queue: .main, action: { [weak self] (event: UIStackReadyEvent) in
            self?.loadData()
        })
        
        // only work for using iCloud
        self.dependency
            .syncManager.allFilesInCloud.subscribe(onNext: { [weak self] urls in
                self?.load(files: urls)
            }).disposed(by: self.disposeBag)
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: iCloudOpeningStatusChangedEvent.self, queue: .main, action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
            self?.loadData()
        })
        
        self.dependency.eventObserver.registerForEvent(on: self, eventType: iCloudAvailabilityChangedEvent.self, queue: .main, action: { [weak self] (event: iCloudAvailabilityChangedEvent) in
            self?.loadData()
        })
    }
    
    public func loadData() {
        self.load(files: self.allFiles)
    }
    
    private var allFiles: [URL] {
        if iCloudDocumentManager.status == .on {
            return self.dependency.syncManager.allFilesInCloud.value.filter { url in
                url.path.hasSuffix(Document.fileExtension) && !url.path.contains(SyncCoordinator.Prefix.deleted.rawValue)
            }.first(20)
        } else {
            return self.dependency.syncManager.allFilesLocal.filter { url in
                url.path.hasSuffix(Document.fileExtension) && !url.path.contains(SyncCoordinator.Prefix.deleted.rawValue)
            }.first(20)
        }
    }
    
    private func load(files: [URL]) {
        let cellModels = files.filter { $0.lastModifyTimeStamp != nil && $0.path.hasSuffix(Document.fileExtension) && !$0.path.contains(SyncCoordinator.Prefix.deleted.rawValue) }
        .sorted(by: { $0.lastModifyTimeStamp! > $1.lastModifyTimeStamp! })
        .map { BrowserCellModel(url: $0) }
        
        self.output.recentDocuments.accept([RecentDocumentSection(items: cellModels)])
    }
}

extension BrowserRecentViewModel: NSFilePresenter {
    public var presentedItemURL: URL? {
        return URL.documentBaseURL
    }
    
    public var presentedItemOperationQueue: OperationQueue {
        return OperationQueue()
    }
    
    public func presentedItemDidChange() {
        DispatchQueue.runOnMainQueueSafely {
            self.loadData()
        }
    }
}
