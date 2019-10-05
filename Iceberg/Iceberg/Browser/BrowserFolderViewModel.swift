//
//  BrowserFolderViewModel.swift
//  Iceberg
//
//  Created by ian luo on 2019/9/29.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import Business
import RxCocoa
import RxDataSources

public struct BrowserDocumentSection {
    public var items: [BrowserCellModel]
    public var identity: String = UUID().uuidString
}

extension BrowserDocumentSection: SectionModelType {
    public init(original: BrowserDocumentSection, items: [Item]) {
        self = original
        self.items = items
    }
    
    public typealias Item = BrowserCellModel
}

extension BrowserDocumentSection: AnimatableSectionModelType {
    public typealias Identity = String
}

public class BrowserFolderViewModel {
    public enum Mode {
        case chooser
        case browser
        
        public var showActions: Bool {
            return self == .browser
        }
        
        public var showChooseIndicator: Bool {
            return self == .chooser
        }
    }
    
    public struct Input {
        let addDocument: PublishSubject<String> = PublishSubject()
    }
    
    public struct Output {
        public let documents: Variable<[BrowserDocumentSection]> = Variable([])
        public let createdDocument: PublishSubject<URL> = PublishSubject()
    }
    
    public let title: Variable<String>
    public let url: Variable<URL>
    public weak var coordinator: BrowserCoordinator? { didSet { self._setupObservers() }}
    public let mode: Mode
    public let isRoot: Bool
    
    private let disposeBag = DisposeBag()
    
    public let input: Input = Input()
    public let output: Output = Output()
    
    public init(url: URL, mode: Mode) {
        self.url = Variable(url)
        self.mode = mode
        self.isRoot = url.levelsToRoot == 0
        self.title = Variable(self.isRoot ? "" : url.packageName)
        
        self.bind()
    }
    
    deinit {
        self.coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public func createChildDocument(title: String) -> Observable<URL> {
        return Observable.create { observer -> Disposable in
            self.coordinator?.dependency.documentManager.add(title: title, below: self.url.value) { [weak self] url in
                if let url = url {
                    let sections = self?.output.documents.value
                    if var secion = sections?.first {
                        let cellModel = BrowserCellModel(url: url)
                        cellModel.coordinator = self?.coordinator
                        secion.items.append(cellModel)
                        secion.items.sort(by: { $0.updateDate.timeIntervalSince1970 > $1.updateDate.timeIntervalSince1970 })
                        self?.output.documents.value = [secion] // trigger reload table
                        observer.onNext(url)
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    public func reload() {
        self._loadFolderData(url: self.url.value)
            .subscribe(onNext: { [weak self] in
                self?.output.documents.value = [BrowserDocumentSection(items: $0)]
            })
            .disposed(by: self.disposeBag)
    }
    
    public func indexPath(for url: URL) -> IndexPath? {
        let items = self.output.documents.value.first?.items ?? []
        for case let (index, cellModel) in items.enumerated() where url == cellModel.url {
            return IndexPath(row: index, section: 0)
        }
        
        return nil
    }
    
    private func _loadFolderData(url: URL) -> Observable<[BrowserCellModel]> {
        return Observable.create { observer -> Disposable in
            var cellModels: [BrowserCellModel] = []
            
            do {
                let urls = try self.coordinator?.dependency.documentManager.query(in: url.convertoFolderURL)
                
                urls?.forEach {
                    let cellModel = BrowserCellModel(url: $0)
                    cellModel.shouldShowActions = self.mode.showActions
                    cellModel.shouldShowChooseHeadingIndicator = self.mode.showChooseIndicator
                    cellModel.coordinator = self.coordinator
                    cellModels.append(cellModel)
                }
            } catch {
                log.error(error)
            }
            
            cellModels.sort(by: { $0.updateDate.timeIntervalSince1970 > $1.updateDate.timeIntervalSince1970 })
            
            observer.onNext(cellModels)
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    private func bind() {
        self.input
            .addDocument
            .asObserver()
            .flatMap { [unowned self] in self.createChildDocument(title: $0) }
            .subscribe(onNext: { [unowned self] in self.output.createdDocument.onNext($0)})
            .disposed(by: self.disposeBag)
    }
    
    private func _setupObservers() {
        
        let eventObserver = self.coordinator?.dependency.eventObserver
        
        eventObserver?.registerForEvent(on: self, eventType: iCloudEnabledEvent.self, queue: nil, action: { [weak self] (event: iCloudEnabledEvent) in
            self?.reload()
        })
        
        eventObserver?.registerForEvent(on: self, eventType: iCloudDisabledEvent.self, queue: nil, action: { [weak self] (event: iCloudDisabledEvent) in
            self?.reload()
        })
        
        eventObserver?.registerForEvent(on: self, eventType: AddDocumentEvent.self, queue: nil, action: { [weak self] (event: AddDocumentEvent) -> Void in
            // if new document is in current folder, reload
            if event.url.convertoFolderURL == self?.url.value.convertoFolderURL {
                self?.reload()
            } else if let items = self?.output.documents.value.first?.items {
                // if new document is in current folder's items, reload current folder, because the folder enter indicator might need update
                for case let cellModel in items where cellModel.url.parentDocumentURL == event.url.parentDocumentURL {
                    self?.reload()
                }
            }
        })
        
        eventObserver?.registerForEvent(on: self,
                                        eventType: iCloudOpeningStatusChangedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                            self?.reload()
        })
        
        eventObserver?.registerForEvent(on: self,
                                        eventType: NewDocumentPackageDownloadedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
                                            self?.reload()
        })
        
        eventObserver?.registerForEvent(on: self,
                                        eventType: DocumentRemovedFromiCloudEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: DocumentRemovedFromiCloudEvent) in
                                            self?.reload()
        })
    }
}

