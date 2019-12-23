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
import Business

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

public class BrowserRecentViewModel {
    public struct Output {
        public let recentDocuments: BehaviorRelay<[RecentDocumentSection]> = BehaviorRelay(value: [])
    }
    
    public weak var coordinator: BrowserCoordinator? {
        didSet {
            self.setupObservers()
        }
    }
    
    public let output: Output = Output()
    
    private let disposeBag = DisposeBag()
    
    private func setupObservers() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: UpdateDocumentEvent.self, queue: .main, action: { [weak self] (event: UpdateDocumentEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: DeleteDocumentEvent.self, queue: .main, action: { [weak self] (event: DeleteDocumentEvent) in
            self?.coordinator?.dependency.editorContext.recentFilesManager.removeRecentFile(url: event.url, completion: {
                self?.loadData()
            })
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
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: DocumentRemovedFromiCloudEvent.self, queue: .main, action: { [weak self] (event: DocumentRemovedFromiCloudEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: NewRecentFilesListDownloadedEvent.self, queue: .main, action: { [weak self] (event: NewRecentFilesListDownloadedEvent) in
            self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self, eventType: UIStackReadyEvent.self, queue: .main, action: { [weak self] (event: UIStackReadyEvent) in
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
        
        self.output.recentDocuments.accept([RecentDocumentSection(items: section)])
    }
}
