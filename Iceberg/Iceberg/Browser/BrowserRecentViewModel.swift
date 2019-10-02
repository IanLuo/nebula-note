//
//  BrowserRecentViewModel.swift
//  Iceberg
//
//  Created by ian luo on 2019/10/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources
import Business

public struct RecentDocumentSection: SectionModelType {
    public var items: [BrowserCellModel]
}

extension RecentDocumentSection {
    public init(original: RecentDocumentSection, items: [BrowserCellModel]) {
        self = original
        self.items = items
    }
    
    public typealias Item = BrowserCellModel
}

public class BrowserRecentViewModel {
    public struct Output {
        public let recentDocuments: BehaviorSubject<[RecentDocumentSection]> = BehaviorSubject(value: [])
    }
    
    public weak var coordinator: BrowserCoordinator? {
        didSet {
            self.setupObservers()
        }
    }
    
    public let output: Output = Output()
    
    private func setupObservers() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: UpdateDocumentEvent.self, queue: .main, action: { [weak self] (event: UpdateDocumentEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: DeleteDocumentEvent.self, queue: .main, action: { [weak self] (event: DeleteDocumentEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: OpenDocumentEvent.self, queue: .main, action: { [weak self] (event: OpenDocumentEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: RecentDocumentRenamedEvent.self, queue: .main, action: { [weak self] (event: RecentDocumentRenamedEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: ChangeDocumentCoverEvent.self, queue: .main, action: { [weak self] (changeDocumentEvent: ChangeDocumentCoverEvent) in
            self?.loadData()
        })

        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: iCloudOpeningStatusChangedEvent.self, queue: .main, action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: NewRecentFilesListDownloadedEvent.self, queue: .main, action: { [weak self] (event: NewRecentFilesListDownloadedEvent) in
            self?.loadData()
        })
    }
    
    deinit {
        self.coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public func loadData() {
        let section = self.coordinator?
            .dependency
            .editorContext
            .recentFilesManager
            .recentFiles.map { BrowserCellModel(url: $0.url) } ?? []
        
        self.output.recentDocuments.onNext([RecentDocumentSection(items: section)])
    }
}
