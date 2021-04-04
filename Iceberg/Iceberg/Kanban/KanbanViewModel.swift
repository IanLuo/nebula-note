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

public class KanbanViewModel: ViewModelProtocol {
    public var context: ViewModelContext<KanbanCoordinator>!
    
    public typealias CoordinatorType = KanbanCoordinator
    
    public let status: PublishSubject<[String: Int]> = PublishSubject()
    
    public let documents: PublishSubject<[String]> = PublishSubject()
    
    public let headingsMap: BehaviorRelay<[String: [DocumentHeadingSearchResult]]> = BehaviorRelay(value: [:])
    
    private let disposeBag = DisposeBag()
    
    public required init() {
        self.headingsMap.subscribe(onNext: { [weak self] map in
            let statusMap: [String: Int] = map.mapValues({
                $0.count
            })
            
            self?.status.onNext(statusMap)
            self?.documents.onNext(Array(Set(map.values.flatMap({ $0 }).map { $0.documentInfo.name })))
        }).disposed(by: self.disposeBag)
    }
    
    public func loadAllStatus() {
        self.loadheadings(self.dependency.settingAccessor.allPlannings)
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
