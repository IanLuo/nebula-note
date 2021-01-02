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

public protocol AgendaViewModelDelegate: class {
    func didCompleteLoadAllData()
    func didLoadData()
    func didFailed(_ error: Error)
}

public class AgendaViewModel {

    public struct Output {
        let tasks: BehaviorSubject<[AgendaCellModel]> = BehaviorSubject(value: [])
        let filsteredData: BehaviorSubject<[AgendaCellModel]> = BehaviorSubject(value: [])
    }
    
    public weak var delegate: AgendaViewModelDelegate?
    public weak var coordinator: AgendaCoordinator? {
        didSet {
            self._setupObserver()
        }
    }
    private let _documentSearchManager: DocumentSearchManager
    
    public init(documentSearchManager: DocumentSearchManager) {
        self._documentSearchManager = documentSearchManager
        
        self.dates = self.generateDates()
    }
    
    /// 用于显示的数据
    public private(set) var dateOrderedData: [Date: [AgendaCellModel]] = [:]
    public private(set) var data: [AgendaCellModel] = []
    public private(set) var dates: [Date] = []
    
    private var _shouldReloadData: Bool = true // 如果在这个界面打开的 document 修改了这个 heading，应该刷新
    public var isConnectingScreen: Bool = false
    
    public let output: Output = Output()
    
    private func generateDates() -> [Date] {
        var dates: [Date] = []
        let today = Date() // current date and time
        dates.append(today)
        for i in 1..<30 {
            dates.append(today.dayAfter(i).dayEnd) // after today use day end time
        }

        return dates
    }
    
    public func regenerateDatesIfNeeded() -> Bool {
        if self.checkShouldRegenerateDates(dates: self.dates) {
            self.dates = self.generateDates()
            return true
        }
        
        return false
    }
    
    private func checkShouldRegenerateDates(dates: [Date]) -> Bool {
        if dates.first?.isSameDay(Date()) == false {
            self._shouldReloadData = true
            return true
        }
        
        return false
    }
    
    private let _headingChangeObservingQueue: OperationQueue = {
        let queue = OperationQueue()
        let dispatchQueue = DispatchQueue(label: "dashboard handling heading change", qos: DispatchQoS.background, attributes: [])
        queue.underlyingQueue = dispatchQueue
        return queue
    }()
    
    public var filterType: AgendaCoordinator.FilterType?
    
    public var indexOfToday: Int {
        let today = Date()
        for (index, date) in self.dates.enumerated() {
            if date.isSameDay(today) {
                return index
            }
        }
        return 0
    }
    
    public func loadData() {
        guard (isConnectingScreen || isMacOrPad) && self._shouldReloadData else { return }
        
        self._shouldReloadData = false
        
        if self.filterType == nil {
            self.loadAgendaData()
        } else {
            self.loadFiltered()
        }
    }
    
    // 加载过滤之后的数据，也就是在 dashboard 中显示的，子分类里面所显示的那些
    public func loadFiltered() {
        if let filterType = self.filterType {
            switch filterType {
            case .tag(let tag):
                self._documentSearchManager.searchTag(tag, completion: { [weak self] results in
                    var __data: [AgendaCellModel] = []
                    
                    for result in results {
                        let children = result.getWholdTree()
                            .map {
                                AgendaCellModel(searchResult: $0)
                            }.sortedByPriority.reversed().sortedByPlanning
                        
                        __data.append(contentsOf: children)
                    }
                    
                    self?.data = __data
                    self?.delegate?.didCompleteLoadAllData()
                }) { error in
                    log.error(error)
                }
            case .planning(let planning):
                self._documentSearchManager.searchPlanning(planning, completion: { [weak self] results in
                    self?.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                    self?.delegate?.didCompleteLoadAllData()
                }) { error in
                    log.error(error)
                }
            case .dueSoon(let results):
                self.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                self.delegate?.didCompleteLoadAllData()
            case .overdue(let results):
                self.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                self.delegate?.didCompleteLoadAllData()
            case .scheduled(let results):
                self.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                self.delegate?.didCompleteLoadAllData()
            case .startSoon(let results):
                self.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                self.delegate?.didCompleteLoadAllData()
            case .unfinished(let results):
                self.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                self.delegate?.didCompleteLoadAllData()
            case .finished(let results):
                self.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                self.delegate?.didCompleteLoadAllData()
            case .today(let results):
                self.data = results.map { AgendaCellModel(searchResult: $0) }.sortedByPriority
                self.delegate?.didCompleteLoadAllData()
            }
        }
    }
    
    public func loadData(for index: Int) {
        self.output.tasks.onNext(self.dateOrderedData[self.dates[index]] ?? [])
        self.data = self.dateOrderedData[self.dates[index]] ?? []
        self.delegate?.didLoadData()
    }
    
    // 加载 agenda 界面所有数据
    private var isLoadingAgendaData: Bool = false
    public func loadAgendaData() {
        
        self.isLoadingAgendaData = true
        
        let finishedPlainings = SettingsAccessor.shared.finishedPlanning
        
        self._documentSearchManager.allHeadings(completion: { [weak self] (results1) in
            self?._documentSearchManager.searchDateAndTime(completion: { (results2) in
                var results = results1.filter { $0.heading.planning != nil }
                results.append(contentsOf: results2)
                let allData = results.map { AgendaCellModel(searchResult: $0) }

                self?.dateOrderedData = [:]

                // filter data for each date
                self?.dates.forEach { date in
                    let mappedCellModels = allData.filter { cellModel in
                        // 已完成的条目不显示
                        if let planning = cellModel.planning, finishedPlainings.contains(planning) {
                            return false
                        }
                        
                        // only for item that has date and time
                        else if let dateAndTime = cellModel.dateAndTime {
                            return dateAndTime.checkNotice(relative: date) != nil
                        } else {
                            return true
                        }
                    }

                    DispatchQueue.runOnMainQueueSafely {
                        self?.dateOrderedData[date] = mappedCellModels._trim()._sort()
                        self?.delegate?.didCompleteLoadAllData()
                        self?.isLoadingAgendaData = false
                    }
                }
                    
            }, failure: { [weak self] (error) in
                self?.delegate?.didFailed(error)
                self?.isLoadingAgendaData = false
            })
            
        }, failure: { [weak self] (error) in
            self?.delegate?.didFailed(error)
            self?.isLoadingAgendaData = false
        })
    }
        
    
    private var _runningForHeadingChangeReload: Bool = false
    private func _setupObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentHeadingChangeEvent.self,
                                                                    queue: .main) { [weak self] (event: DocumentHeadingChangeEvent) -> Void in
                                                                        self?._shouldReloadData = true
                                                                        
                                                                        if isMacOrPad {
                                                                            guard self?.isLoadingAgendaData == false else { return }
                                                                            self?.loadData()
                                                                        }
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentAgendaRelatedChangeEvent.self,
                                                                    queue: .main) { [weak self] (event: DocumentAgendaRelatedChangeEvent) -> Void in
                                                                        self?._shouldReloadData = true
                                                                        
                                                                        if isMacOrPad {
                                                                            self?.loadData()
                                                                        }
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DateAndTimeChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: DateAndTimeChangedEvent) -> Void in
                                                                        self?._shouldReloadData = true
                                                                        
                                                                        if isMacOrPad {
                                                                            self?.loadData()
                                                                        }
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudOpeningStatusChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                                                        self?._shouldReloadData = true
                                                                        
                                                                        if isMacOrPad {
                                                                            self?.loadData()
                                                                        }
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudOpeningStatusChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                                                        self?._shouldReloadData = true
                                                                        
                                                                        if isMacOrPad {
                                                                            self?.loadData()
                                                                        }
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: NewDocumentPackageDownloadedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
                                                                        self?._shouldReloadData = true
                                                                        self?.loadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
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
