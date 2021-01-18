//
//  BrowserFolderViewModel.swift
//  Iceberg
//
//  Created by ian luo on 2019/9/29.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import Core
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

public class BrowserFolderViewModel: NSObject, ViewModelProtocol {
    public var context: ViewModelContext<BrowserCoordinator>!
    
    public typealias CoordinatorType = BrowserCoordinator
    
    public enum Mode {
        case chooser
        case browser
        case favorite
        
        public var showActions: Bool {
            return self == .browser || self == .favorite
        }
        
        public var showChooseIndicator: Bool {
            return self == .chooser
        }
    }
    
    public struct Input {
        let addDocument: PublishSubject<String> = PublishSubject()
    }
    
    public struct Output {
        public let documents: BehaviorRelay<[BrowserDocumentSection]> = BehaviorRelay(value: [])
        public let onCreatededDocument: PublishSubject<URL> = PublishSubject()
        public let onCreatingDocumentFailed: PublishSubject<String> = PublishSubject()
    }
    
    private var _documentRelativePath: String = ""
    public var url: URL {
        return self._documentRelativePath.count > 0
            ? URL.documentBaseURL.appendingPathComponent(self._documentRelativePath)
            : URL.documentBaseURL
    }
    public var title: BehaviorRelay<String>!
    public var mode: Mode = .browser
    public var isRoot: Bool!
    public var levelsToRoot: Int!
    
    private let disposeBag = DisposeBag()
    
    public let input: Input = Input()
    public let output: Output = Output()
    
    override public required init() {}
    
    public convenience init(url: URL, mode: Mode, coordinator: BrowserCoordinator) {
        self.init(coordinator: coordinator)
        
        self._documentRelativePath = url.documentRelativePath
        self.mode = mode
        self.isRoot = url.levelsToRoot == 0
        self.levelsToRoot = url.levelsToRoot
        self.title = BehaviorRelay(value: self.isRoot ? "" : url.packageName)
        
        self.bind()
        
        self._setupObservers()
    }
    
    deinit {
        self.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public func createChildDocument(title: String) -> Observable<URL> {
        return Observable.create { observer -> Disposable in
            self.dependency.documentManager.add(title: title, below: self.url) { [weak self] url in
                if let url = url {
                    let sections = self?.output.documents.value
                    if var secion = sections?.first {
                        let cellModel = BrowserCellModel(url: url)
                        cellModel.coordinator = self?.context.coordinator
                        secion.items.append(cellModel)
                        secion.items.sort(by: { $0.updateDate.timeIntervalSince1970 > $1.updateDate.timeIntervalSince1970 })
                        self?.output.documents.accept([secion]) // trigger reload table
                        observer.onNext(url)
                        observer.onCompleted()
                    }
                } else {
                    self?.output.onCreatingDocumentFailed.onNext(title)
                }
            }
            
            return Disposables.create()
        }
    }
    
    public func reload() {
        // when loading data, for root page, laoding favorite list for favorite, others load from root directory
        if self.isRoot {
            switch self.mode {
            case .favorite:
                self.loadFavorites().subscribe(onNext: { [weak self] in
                    self?.output.documents.accept([BrowserDocumentSection(items: $0)])
                }).disposed(by: self.disposeBag)
                return
            case .browser, .chooser: break
            }
        }
        
        self._loadFolderData(url: self.url)
            .subscribe(onNext: { [weak self] in
                self?.output.documents.accept([BrowserDocumentSection(items: $0)])
            })
            .disposed(by: self.disposeBag)
    }
    
    private func loadFavorites() -> Observable<[BrowserCellModel]> {
        guard let favorites = self.dependency.settingAccessor.getSetting(item: .favoriteDocuments, type: [String].self) else {
            return Observable.just([])
        }
        
        let searchManager = self.dependency.documentSearchManager
        
        let allSearchs: [Observable<URL>] = favorites
            .map { searchManager.searchLog(containing: $0, onlyTakeFirst: true).compactMap { $0.first } }
        
        return Observable.merge(allSearchs).toArray().asObservable().map { urls in
            return urls.map {
                let cellModel = BrowserCellModel(url: $0)
                cellModel.shouldShowActions = self.mode.showActions
                cellModel.shouldShowChooseHeadingIndicator = self.mode.showChooseIndicator
                cellModel.coordinator = self.context.coordinator
                return cellModel
            }
        }
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
                let urls = try self.dependency.documentManager.query(in: url.convertoFolderURL)
                urls.forEach {
                    let cellModel = BrowserCellModel(url: $0)
                    cellModel.shouldShowActions = self.mode.showActions
                    cellModel.shouldShowChooseHeadingIndicator = self.mode.showChooseIndicator
                    cellModel.coordinator = self.context.coordinator
                    cellModels.append(cellModel)
                }
                
                //find from downloading urls
                for url in Array(self.dependency.syncManager.onDownloadingUpdates.value.keys.filter { $0.pathExtension == Document.fileExtension && !$0.packageName
                    .hasPrefix(SyncCoordinator.Prefix.deleted.rawValue) }) {
                    if url.parentDocumentURL == self.url && !urls.contains(where: { $0.documentRelativePath == url.documentRelativePath }) {
                        let cellModel = BrowserCellModel(url: url, isDownloading: true)
                        cellModel.shouldShowActions = self.mode.showActions
                        cellModel.shouldShowChooseHeadingIndicator = self.mode.showChooseIndicator
                        cellModel.coordinator = self.context.coordinator
                        cellModels.append(cellModel)
                    }
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
            .subscribe(onNext: { [unowned self] in self.output.onCreatededDocument.onNext($0)})
            .disposed(by: self.disposeBag)
    }
    
    /// convenienct variable to access table data for rxDataSource
    private var _tableDocuments: [BrowserCellModel] {
        get {
            return self.output.documents.value.first?.items ?? []
        }
        
        set {
            self.output.documents.accept([BrowserDocumentSection(items: newValue)])
        }
    }
    
    private func _setupObservers() {
        
        let eventObserver = self.dependency.eventObserver
        
        /// observe disable, but not observe enable, because enabled will send iCloudAvailabilityChangedEvent when iCloud files are ready
        eventObserver.registerForEvent(on: self, eventType: iCloudDisabledEvent.self, queue: nil, action: { [weak self] (event: iCloudDisabledEvent) in
            guard let strongSelf = self else { return }
            strongSelf.reload()
        })
        
        eventObserver.registerForEvent(on: self, eventType: iCloudAvailabilityChangedEvent.self, queue: nil, action: { [weak self] (event: iCloudAvailabilityChangedEvent) in
            guard let strongSelf = self else { return }
            strongSelf.reload()
        })
        
        eventObserver.registerForEvent(on: self, eventType: AddDocumentEvent.self, queue: nil, action: { [weak self] (event: AddDocumentEvent) -> Void in
            // if new document is in current folder, reload
            if event.url.deletingLastPathComponent() == self?.url {
                self?.reload()
            } else if let items = self?.output.documents.value.first?.items {
                // if new document is in current folder's items, reload current folder, because the folder enter indicator might need update
                for case let cellModel in items where cellModel.url.parentDocumentURL == event.url.parentDocumentURL {
                    self?.reload()
                }
            }
        })
        
        eventObserver.registerForEvent(on: self, eventType: DeleteDocumentEvent.self, queue: nil, action: { [weak self] (event: DeleteDocumentEvent) -> Void in
            self?.reload()
        })
        
        eventObserver.registerForEvent(on: self, eventType: RenameDocumentEvent.self, queue: nil, action: { [weak self] (event: RenameDocumentEvent) -> Void in
            self?.reload()
        })
        
        eventObserver.registerForEvent(on: self,
                                        eventType: iCloudOpeningStatusChangedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                            self?.reload()
        })
        
        eventObserver.registerForEvent(on: self,
                                        eventType: NewDocumentPackageDownloadedEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
                                            self?.reload()
        })
        
        eventObserver.registerForEvent(on: self,
                                        eventType: DocumentRemovedFromiCloudEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: DocumentRemovedFromiCloudEvent) in
                                            self?.reload()
        })
        
        /// this event is sent by SyncCoordinator
        eventObserver.registerForEvent(on: self,
                                        eventType: NewFilesAvailableEvent.self,
                                        queue: OperationQueue.main,
                                        action: { [weak self] (event: NewFilesAvailableEvent) in
                                            self?.reload()
        })
        
        NotificationCenter.default
            .rx
            .notification(UIApplication.didBecomeActiveNotification)
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: { _ in
                self.reload()
            })
            .disposed(by: self.disposeBag)
        
        // add new cell for downloading document
        self.dependency.syncManager.onDownloadingUpdates.subscribe(onNext: { [weak self] downloadingItemMap in
            guard let strongSelf = self else { return }
            
            let urlsBelongsToCurrentFolder = downloadingItemMap.keys.filter { $0.pathExtension == Document.fileExtension && $0.parentDocumentURL == strongSelf.url }
            
            if urlsBelongsToCurrentFolder.count > 0 {
                strongSelf.reload()
            }
        }).disposed(by: self.disposeBag)
        
        self.dependency.syncManager.onDownloadingCompletes.subscribe(onNext: { [weak self] url in
            guard let strongSelf = self else { return }
            
            if (url.pathExtension == Document.fileExtension && url.parentDocumentURL == strongSelf.url) {
                strongSelf.reload()
            }
            
        }).disposed(by: self.disposeBag)
    }
}

extension BrowserFolderViewModel {
    override public var debugDescription: String {
        return "\(self.url)"
    }
}
