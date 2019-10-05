//
//  AgendaViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business
import RxSwift
import RxCocoa

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
        let today = Date()
        for i in 0..<30 {
            dates.append(today.dayAfter(i))
        }

        return dates
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
        guard isConnectingScreen && self._shouldReloadData else { return }
        
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
            }
        }
    }
    
    public func loadData(for index: Int) {
        self.output.tasks.onNext(self.dateOrderedData[self.dates[index]] ?? [])
        self.data = self.dateOrderedData[self.dates[index]] ?? []
        self.delegate?.didLoadData()
    }
    
    // 加载 agenda 界面所有数据
    public func loadAgendaData() {
        
        self._documentSearchManager.searchDateAndTime(completion: { [weak self] results in
            let allData = results.map { AgendaCellModel(searchResult: $0) }
            self?.dateOrderedData = [:]
            let today = Date().dayEnd
            
            // filter data for each date
            self?.dates.forEach { date in
                let mappedCellModels = allData.filter { cellModel in
                    // 已完成的条目不显示
                    if let planning = cellModel.planning, SettingsAccessor.shared.finishedPlanning.contains(planning) {
                        return false
                    }
                        // only for item that has date and time
                    else if let dateAndTime = cellModel.dateAndTime {
                        if dateAndTime.isSchedule || dateAndTime.isDue {
                            if date.isSameDay(today) {
                                return dateAndTime.date.dayEnd <= date.dayEnd
                            } else {
                                return dateAndTime.date.dayEnd.isSameDay(date.dayEnd)
                            }
                        }
                        return dateAndTime.date.isSameDay(date)
                    } else {
                        return true
                    }
                }
                
                self?.dateOrderedData[date] = mappedCellModels
            }
            
            DispatchQueue.main.async {
                self?.delegate?.didCompleteLoadAllData()
            }
            
        }) { [weak self] error in
            self?.delegate?.didFailed(error)
        }
    }
    
    private func _setupObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentSearchHeadingUpdateEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: DocumentSearchHeadingUpdateEvent) -> Void in
                                                                        self?._shouldReloadData = true
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DateAndTimeChangedEvent.self,
                                                                    queue: self._headingChangeObservingQueue,
                                                                    action: { [weak self] (event: DateAndTimeChangedEvent) -> Void in
                                                                        self?._shouldReloadData = true
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudOpeningStatusChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
            self?._shouldReloadData = true
        })
    }
}

extension Array where Element == AgendaCellModel {
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
