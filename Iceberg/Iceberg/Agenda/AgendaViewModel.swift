//
//  AgendaViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Core
import RxSwift
import RxCocoa
import Interface

public class AgendaViewModel: ViewModelProtocol {
    public required init() {}
    
    public typealias CoordinatorType = AgendaCoordinator
    public var context: ViewModelContext<AgendaCoordinator>!
    
    private let disposeBag = DisposeBag()
    
    /// 用于显示的数据
    public let tags: BehaviorRelay<[String: [DocumentHeadingSearchResult]]> = BehaviorRelay(value: [:])
    public let status: BehaviorRelay<[String: [DocumentHeadingSearchResult]]> = BehaviorRelay(value: [:])
    public let scheduled: BehaviorRelay<[DocumentHeadingSearchResult]> = BehaviorRelay(value: [])
    public let overdue: BehaviorRelay<[DocumentHeadingSearchResult]> = BehaviorRelay(value: [])
    public let dueSoon: BehaviorRelay<[DocumentHeadingSearchResult]> = BehaviorRelay(value: [])
    public let startSoon: BehaviorRelay<[DocumentHeadingSearchResult]> = BehaviorRelay(value: [])
    public let all: BehaviorRelay<[AgendaCellModel]> = BehaviorRelay(value: [])
    
    private var _shouldReloadData: Bool = true // 如果在这个界面打开的 document 修改了这个 heading，应该刷新
    public var isConnectingScreen: Bool = false
    
    private let _headingChangeObservingQueue: OperationQueue = {
        let queue = OperationQueue()
        let dispatchQueue = DispatchQueue(label: "dashboard handling heading change", qos: DispatchQoS.background, attributes: [])
        queue.underlyingQueue = dispatchQueue
        return queue
    }()
    
    public func didSetupContext() {
        self._setupObserver()
    }
    
    public func loadData() {
        guard self._shouldReloadData else { return }
        
        self._shouldReloadData = false
        
        self.loadAgendaData()
    }
    
    // 加载 agenda 界面所有数据
    private var isLoadingAgendaData: Bool = false
    public func loadAgendaData() {
        
        self.isLoadingAgendaData = true
        
        let today = Date().dayEnd
        var scheduled: [DocumentHeadingSearchResult] = []
        var startSoon: [DocumentHeadingSearchResult] = []
        var overdue: [DocumentHeadingSearchResult] = []
        var overdueSoon: [DocumentHeadingSearchResult] = []
        
        let dateAndTimeSearch = self.context.dependency.documentSearchManager.searchDateAndTime()
        let allHeadingSearch = self.context.dependency.documentSearchManager.allHeadings()
        let finishedPlannings = self.context.coordinator?.dependency.settingAccessor.finishedPlanning ?? []
        
        Observable.zip(dateAndTimeSearch, allHeadingSearch)
            .subscribe(onNext: { dataAndTimeResult, allResult in
                dataAndTimeResult.forEach { result in
                    
                    if let dateAndTime = result.dateAndTime {
                        guard finishedPlannings.contains(result.heading.planning ?? "") == false else { return }
                        
                        if let notice = dateAndTime.checkNotice(relative: today) {
                            if dateAndTime.isDue {
                                if notice.daysCount <= 3 && notice.daysCount >= 0{
                                    overdueSoon.append(result)
                                } else {
                                    overdue.append(result)
                                }
                            } else {
                                if notice.daysCount <= 3 && notice.daysCount >= 0 {
                                    startSoon.append(result)
                                } else {
                                    scheduled.append(result)
                                }
                            }
                        }
                    }
                }
                
                var allTags:[String: [Any]] = [:]
                var allPlannings: [String: [Any]] = [:]
                var results = allResult.filter { $0.heading.planning != nil && !finishedPlannings.contains($0.heading.planning ?? "") }

                for result in allResult {
                    if let tags = result.heading.tags {
                        for tag in tags {
                            allTags.appendToGroup(key: tag, value: result)
                        }
                    }
                    
                    if let planning = result.heading.planning {
                        allPlannings.appendToGroup(key: planning, value: result)
                    }
                }
                
                results.append(contentsOf: dataAndTimeResult)
                let allData = results.map { AgendaCellModel(searchResult: $0) }
                
                let mappedCellModels = allData.filter { cellModel in
                    // 已完成的条目不显示
                    if let planning = cellModel.planning, finishedPlannings.contains(planning) {
                        return false
                    }
                    
                    // only for item that has date and time
                    else if let dateAndTime = cellModel.dateAndTime {
                        return dateAndTime.checkNotice(relative: today) != nil
                    } else {
                        return true
                    }
                }
                
                self.tags.accept(allTags as! [String: [DocumentHeadingSearchResult]])
                self.status.accept(allPlannings as! [String: [DocumentHeadingSearchResult]])
                self.overdue.accept(overdue)
                self.startSoon.accept(startSoon)
                self.dueSoon.accept(overdueSoon)
                self.scheduled.accept(scheduled)
                self.all.accept(mappedCellModels)
                
                self.isLoadingAgendaData = false
            }).disposed(by: self.disposeBag)
    }

    private var _runningForHeadingChangeReload: Bool = false
    private func _setupObserver() {
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentHeadingChangeEvent.self,
                                                                    queue: .main) { [weak self] (event: DocumentHeadingChangeEvent) -> Void in
                                                                        self?._shouldReloadData = true
        }
        
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentAgendaRelatedChangeEvent.self,
                                                                    queue: .main) { [weak self] (event: DocumentAgendaRelatedChangeEvent) -> Void in
                                                                        self?._shouldReloadData = true
        }
        
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DateAndTimeChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: DateAndTimeChangedEvent) -> Void in
                                                                        self?._shouldReloadData = true
        })
        
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudOpeningStatusChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                                                        self?._shouldReloadData = true
        })
        
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudOpeningStatusChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                                                        self?._shouldReloadData = true
                                                                        
                                                                        if isMacOrPad {
                                                                            self?.loadData()
                                                                        }
        })
        
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: NewDocumentPackageDownloadedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
                                                                        self?._shouldReloadData = true
                                                                        self?.loadData()
        })
        
        self.context.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudAvailabilityChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudAvailabilityChangedEvent) in
                                                                        self?._shouldReloadData = true
                                                                        self?.loadData()
        })
    }
}

extension Array where Element == AgendaCellModel {
    fileprivate func _trim() -> [AgendaCellModel] {
        var tempDic: [String: AgendaCellModel] = [:]
        self.forEach {
            let key = "\($0.url.path)\($0.heading.range)"
            tempDic[key] = $0
        }
        
        return Array(tempDic.values)
    }
    
    fileprivate func _sort() -> [AgendaCellModel] {
        return self.sorted { $0.headingText < $1.headingText }
            .sorted { (cm1, cm2) -> Bool in
                switch (cm1.priority, cm2.priority, cm1.dateAndTime?.date, cm2.dateAndTime?.date) {
                case let (cm1p?, cm2p?, _, _): return cm1p < cm2p
                case (_?, nil, _, _): return true
                case (nil, _?, _, _): return false
                case let (nil, nil, cm1d?, cm2d?): return cm1d < cm2d
                case (nil, nil, _?, nil): return true
                case (nil, nil, nil, _?): return false
                case (nil, nil, nil, nil): return false
                }
        }
    }

    var sortedByPriority: [Element] {
        return self.sorted { (cellModel1: Element, cellModel2: Element) -> Bool in
            // 按照 priority 排序
            switch (cellModel1.priority, cellModel2.priority) {
            case (nil, nil): // 如果都没有添加 priority 则直接使用文档中的顺序
                return true
            case (_?, nil): // 如果其中一个有 priority，则排在前面
                return true
            case (nil, _?): // 如果其中一个有 priority，则排在前面
                return false
            case let (p1?, p2?): // 都有 priority，则比较 priority
                return p1 < p2
            }
        }
    }
    
    var sortedByPlanning: [Element] {
        return self.sorted { (cellModel1: Element, cellModel2: Element) -> Bool in
            switch (cellModel1.isFinished, cellModel2.isFinished) {
            case (nil, nil):
                return true
            case (let f1?, nil):
                return !f1
            case (nil, let f1?):
                return f1
            case let (f1?, f2?):
                if f1 && f2 {
                    return true
                } else if f1 && !f2 {
                    return false
                } else {
                    return true
                }
            }
        }
    }
}
