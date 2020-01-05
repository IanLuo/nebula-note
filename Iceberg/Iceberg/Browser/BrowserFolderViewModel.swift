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

public class BrowserFolderViewModel: ViewModelProtocol {
    public var context: ViewModelContext<BrowserCoordinator>!
    
    public typealias CoordinatorType = BrowserCoordinator
    
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
        public let documents: BehaviorRelay<[BrowserDocumentSection]> = BehaviorRelay(value: [])
        public let createdDocument: PublishSubject<URL> = PublishSubject()
        public let createDocumentFailed: PublishSubject<String> = PublishSubject()
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
    
    public required init() {}
    
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
                    self?.output.createDocumentFailed.onNext(title)
                }
            }
            
            return Disposables.create()
        }
    }
    
    public func reload() {
        self._loadFolderData(url: self.url)
            .subscribe(onNext: { [weak self] in
                self?.output.documents.accept([BrowserDocumentSection(items: $0)])
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
                let urls = try self.dependency.documentManager.query(in: url.convertoFolderURL)
                
                urls.forEach {
                    let cellModel = BrowserCellModel(url: $0)
                    cellModel.shouldShowActions = self.mode.showActions
                    cellModel.shouldShowChooseHeadingIndicator = self.mode.showChooseIndicator
                    cellModel.coordinator = self.context.coordinator
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
            if event.url.convertoFolderURL == self?.url.convertoFolderURL {
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
    }
}

extension BrowserFolderViewModel: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self.url)"
    }
}
