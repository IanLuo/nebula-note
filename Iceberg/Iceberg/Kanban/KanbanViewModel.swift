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
            let statusMap: [String: Int] = map.keys.reduce([:], { result, key in
                var result = result
                if let count = result[key] {
                    result[key] = count + 1
                } else {
                    result[key] = 1
                }
                
                return result
            })
            
            self?.status.onNext(statusMap)
            self?.documents.onNext(Array(Set(map.values.flatMap({ $0 }).map { $0.documentInfo.name })))
        }).disposed(by: self.disposeBag)
    }
    
    public func loadAllStatus() {
        for status in self.dependency.settingAccessor.allPlannings {
            self.loadHeadings(for: status)
        }
    }
    
    public func loadHeadings(for status: String) {
        self.dependency.documentSearchManager.searchPlanning(status) { [weak self] result in
            guard let strongSelf = self else { return }
            var value = strongSelf.headingsMap.value
            value[status] = result
            self?.headingsMap.accept(value)
        } failure: { (error) in
            print(error)
        }
    }
    
    public func update(heading: DocumentHeadingSearchResult, newStatus: String) -> Observable<Void> {
        return Observable.create { observer -> Disposable in
            
            let service = self.dependency.editorContext.request(url: heading.documentInfo.url)
            service.open { [service] _ in
                _ = service.toggleContentCommandComposer(composer: PlanningCommandComposer(location: heading.heading.location, kind: .addOrUpdate(newStatus)))
                
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
