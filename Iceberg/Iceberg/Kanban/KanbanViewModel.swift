//
//  KanbanViewModel.swift
//  x3Note
//
//  Created by ian luo on 2021/3/22.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Core
import Interface

private let keyIgnoredStatus = "keyIgnoredStatus"
private let keyIgnoredDocuments = "keyIgnoredDocuments"

public class KanbanViewModel: ViewModelProtocol {
    public var context: ViewModelContext<KanbanCoordinator>!
    
    public typealias CoordinatorType = KanbanCoordinator
    
    public let status: PublishSubject<[String: Int]> = PublishSubject()
    
    public let documents: PublishSubject<[String]> = PublishSubject()
    
    public let headingsMap: BehaviorRelay<[String: [DocumentHeadingSearchResult]]> = BehaviorRelay(value: [:])
    
    private let disposeBag = DisposeBag()
    
    public let ignoredStatus: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    
    public let ignoredDocuments: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    
    private var ignoredEntryStore: KeyValueStore {
        return dependency.storeContainer.get(store: .ignoredDocumentsInKanban)
    }
    
    public var shouldReloadData: Bool = false
    
    private var isLoadingAllData = false
        
    public required init() {
        self.headingsMap.subscribe(onNext: { [weak self] map in
            let statusMap: [String: Int] = map.mapValues({
                $0.count
            })
                                    
            self?.status.onNext(statusMap)
            self?.documents.onNext(Array(Set(map.values.flatMap({ $0 }).map { $0.documentInfo.name })))
        }).disposed(by: self.disposeBag)
    }
    
    public func didSetupContext() {
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentHeadingChangeEvent.self,
                                                                    queue: .main) { [weak self] (event: DocumentHeadingChangeEvent) -> Void in
            self?.shouldReloadData = true
        }
        
        self.dependency.purchaseManager.isMember.subscribe(onNext: { [weak self] in
            guard $0 else { return }
            
            self?.loadIgnoreStatus()
        }).disposed(by: self.disposeBag)
    }
    
    public func loadAllStatus() {
        guard self.isLoadingAllData == false else { return }
        
        self.loadIgnoreStatus()
        
        self.isLoadingAllData = true
        
        self.loadheadings(self.dependency.settingAccessor.allPlannings)
        
        self.shouldReloadData = false
        self.isLoadingAllData = false
    }
    
    public func loadheadings(_ status: [String]) {
        Observable.zip(status.map {
            self.loadHeadings(for: $0)
        }).subscribe(onNext: { result in
            self.headingsMap.accept(result.reduce(self.headingsMap.value) { result, next in
                var result = result

                result[next.0] = next.1
                return result
            })
        }).disposed(by: self.disposeBag)
    }
    
    private func loadIgnoreStatus() {
        if let savedIgnoredStatus = self.ignoredEntryStore.get(key: keyIgnoredStatus, type: [String].self) {
            self.ignoredStatus.accept(savedIgnoredStatus)
        }
        
        if let savedIgnoredDocuments = self.ignoredEntryStore.get(key: keyIgnoredDocuments, type: [String].self) {
            self.ignoredDocuments.accept(savedIgnoredDocuments)
        }
    }
    
    public func isFinishedStatus(status: String) -> Bool {
        return self.dependency.settingAccessor.finishedPlanning.contains(status)
    }
    
    public func loadHeadings(for status: String) -> Observable<(String, [DocumentHeadingSearchResult])> {
        return Observable.create { observer -> Disposable in
            self.dependency.documentSearchManager.searchPlanning(status) { result in
                observer.onNext((status, result))
                observer.onCompleted()
            } failure: { (error) in
                observer.onError(error)
                log.error(error)
            }
            
            return Disposables.create()
        }
    }
    
    public func updateIgnoredStatus(status: String, add: Bool) {
        var a = self.ignoredStatus.value
        if add {
            a.append(status)
            self.ignoredStatus.accept(Array(Set(a)))
        } else {
            for case let (i, s) in a.enumerated() where s == status {
                a.remove(at: i)
            }
            self.ignoredStatus.accept(a)
        }
        
        self.ignoredEntryStore.set(value: self.ignoredStatus.value, key: keyIgnoredStatus, completion: {})
    }
    
    public func updateIgnoredDocument(document: String, add: Bool) {
        var a = self.ignoredDocuments.value
        if add {
            a.append(document)
            self.ignoredDocuments.accept(Array(Set(a)))
        } else {
            for case let (i, d) in a.enumerated() where d == document {
                a.remove(at: i)
            }
            self.ignoredDocuments.accept(a)
        }
        
        self.ignoredEntryStore.set(value: self.ignoredDocuments.value, key: keyIgnoredDocuments, completion: {})
    }
    
    public func update(heading: DocumentHeading, newStatus: String) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            
            let service = self.dependency.editorContext.request(url: heading.url)
            service.open { [service] _ in
                _ = service.toggleContentCommandComposer(composer: PlanningCommandComposer(location: heading.location, kind: .addOrUpdate(newStatus))).perform()
                
                service.save { _ in
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    public func open(heading: DocumentHeadingSearchResult) {
        self.openDocument(url: heading.documentInfo.url, location: heading.heading.range.upperBound)
    }
}
