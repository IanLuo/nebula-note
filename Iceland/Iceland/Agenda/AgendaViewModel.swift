//
//  AgendaViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol AgendaViewModelDelegate: class {
    func didLoadData()
    func didCompleteLoadAllData()
    func didFailed(_ error: Error)
}

public class AgendaViewModel {
    public weak var delegate: AgendaViewModelDelegate?
    public weak var coordinator: AgendaCoordinator? {
        didSet {
            self._setupHeadingChangeObserver()
        }
    }
    private let _documentSearchManager: DocumentSearchManager
    
    public init(documentSearchManager: DocumentSearchManager) {
        self._documentSearchManager = documentSearchManager
    }
    
    /// 用于显示的数据
    public private(set) var data: [AgendaCellModel] = []
    
    private var _lastLoadTime: TimeInterval = 0
    private let _reloadInterval: TimeInterval = 60
    private var _headingsHasModification: Bool = true
    public var isConnectingScreen: Bool = false
    
    /// 未经过过滤的数据
    private var _allData: [AgendaCellModel] = []
    
    private let _headingChangeObservingQueue: OperationQueue = {
        let queue = OperationQueue()
        let dispatchQueue = DispatchQueue(label: "dashboard handling heading change", qos: DispatchQoS.background, attributes: [])
        queue.underlyingQueue = dispatchQueue
        return queue
    }()
    
    public var filterType: AgendaCoordinator.FilterType?
    
    public func load(date: Date) {
        self.data = self._allData.filter {
            switch ($0.schedule?.date, $0.due?.date) {
            case (let schedule?, nil): return schedule <= date
            case (nil, let due?): return due <= date
            case (let schedule?, let due?): return schedule <= date || due <= date
            case (nil, nil): return true
            }
        }
        
        self.delegate?.didLoadData()
    }
    
    public func loadData() {
        let loadTime = Date()
        guard (loadTime.timeIntervalSince1970 - self._lastLoadTime > _reloadInterval && self._headingsHasModification)
            || (isConnectingScreen && self._headingsHasModification) else { return }
        
        if self.filterType == nil {
            self.loadAgendaData()
        } else {
            self.loadFiltered()
        }
        
        self._lastLoadTime = loadTime.timeIntervalSince1970
    }
    
    public func loadFiltered() {
        if let filterType = self.filterType {
            var data: [DocumentHeading] = []
            let today = Date()
            let soon = Date(timeInterval: 3 * 24 * 60, since: today)
            self._documentSearchManager.searchHeading(options: [.tag, .due, .schedule, .planning], filter: { [weak self] (heading: DocumentHeading) -> Bool in
                
//                self?._headingsHasModification = false
                
//                switch filterType {
//                case .tag(let tag):
//                    return heading.tags?.contains(tag) ?? false
//                case .overdue:
//                    return (heading.due?.date ?? Date.distantFuture) <= today
//                case .scheduled:
//                    return (heading.schedule?.date ?? Date.distantFuture) <= today
//                case .dueSoon:
//                    return (heading.due?.date ?? Date.distantFuture) <= soon
//                case .scheduledSoon:
//                    return (heading.schedule?.date ?? Date.distantFuture) <= soon
//                case .withoutDate:
//                    return heading.tags == nil
//                }
                return true
            }, resultAdded: { (results: [DocumentHeading]) in
                data.append(contentsOf: results)
            }, complete: { [weak self] in
                self?.data = data.map { AgendaCellModel(heading: $0) }
                self?.delegate?.didLoadData()
            }, failed: { [weak self] error in
                self?.delegate?.didFailed(error)
            })
        }
    }
    
    // 加载 agenda 界面所有数据
    public func loadAgendaData() {
        var searchResults: [DocumentHeading] = []
        let today = Date()
        self._documentSearchManager.searchHeading(options: [.tag, .due, .schedule, .planning], filter: { [weak self] (heading: DocumentHeading) -> Bool in
            
            self?._headingsHasModification = false
            
            if let planning = heading.planning {
                if SettingsAccessor.shared.unfinishedPlanning.contains(planning) {
                    return true
                }
            }
//            if let due = heading.due, due.date >= today {
//                return true
//            }
//            if let schedule = heading.schedule, schedule.date >= today {
//                return true
//            }
            
            return false
        }, resultAdded: { (results: [DocumentHeading]) in
//            let sorted = results.sorted { left, right in
//                switch (left.due, left.schedule, right.due, right.schedule) {
//                case (let leftDue?, _, let rightDue?, _): return leftDue.date.timeIntervalSince1970 < rightDue.date.timeIntervalSince1970
//                case (_?, _, nil, _): return true
//                case (nil, _, _?, _): return false
//                case (nil, let leftSchedule?, nil, let rightSchedule?): return leftSchedule.date.timeIntervalSince1970 < rightSchedule.date.timeIntervalSince1970
//                case (_, _?, _, nil): return true
//                case (_, nil, _, _?): return false
//                default: return true
//                }
//            }
            
//            searchResults.append(contentsOf: sorted)
        }, complete: { [weak self] in
            self?._allData = searchResults.map { AgendaCellModel(heading: $0) }
            self?.delegate?.didCompleteLoadAllData()
        }, failed: { [weak self] error in
            self?.delegate?.didFailed(error)
        })
    }
    
    public func saveToCalendar(index: Int) {
        // TODO: save to calendar
    }
    
    public func updateSchedule(index: Int, _ schedule: DateAndTimeType?) {
        let heading = self.data[index]
        
//        if let editorService = self.coordinator?.dependency.editorContext.request(url: heading.url) {
//            editorService.open(completion: { [unowned editorService] _ in
//                if let schedule = schedule {
//                    if editorService.toggleContentAction(command: ScheduleCommand(location: heading.headingLocation, kind: .addOrUpdate(schedule)), foreceWriteToFile: true) {
//                        heading.schedule = schedule
//                        self.delegate?.didLoadData()
//                    }
//                } else {
//                    if editorService.toggleContentAction(command: ScheduleCommand(location: heading.headingLocation, kind: .remove), foreceWriteToFile: true) {
//                        heading.schedule = nil
//                        self.delegate?.didLoadData()
//                    }
//                }
//            })
//        }
    }
    
    public func updateDue(index: Int, _ due: DateAndTimeType?) {
        let heading = self.data[index]
        
//        if let editorService = self.coordinator?.dependency.editorContext.request(url: heading.url) {
//            editorService.open(completion: { [unowned editorService] _ in
//                if let due = due {
//                    if editorService.toggleContentAction(command: DueCommand(location: heading.headingLocation, kind: .addOrUpdate(due)), foreceWriteToFile: true) {
//                        heading.due = due
//                        self.delegate?.didLoadData()
//                    }
//                } else {
//                    if editorService.toggleContentAction(command: DueCommand(location: heading.headingLocation, kind: .remove), foreceWriteToFile: true) {
//                        heading.due = nil
//                        self.delegate?.didLoadData()
//                    }
//                }
//            })
//        }
    }
    
    public func updatePlanning(index: Int, _ planning: String?) {
        let heading = self.data[index]
        
        if let editorService = self.coordinator?.dependency.editorContext.request(url: heading.url) {
            editorService.open(completion: { [unowned editorService] _ in
                if let planning = planning {
                    if editorService.toggleContentAction(command: PlanningCommand(location: heading.headingLocation, kind: .addOrUpdate(planning)), foreceWriteToFile: true) {
                        heading.planning = planning
                        self.delegate?.didLoadData()
                    }
                }
            })
        }
    }
    
    public func openDocument(index: Int) {
        self.coordinator?.openDocument(url: self.data[index].url,
                                      location: self.data[index].headingLocation)
    }
    
    private func _setupHeadingChangeObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentSearchHeadingUpdateEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: DocumentSearchHeadingUpdateEvent) -> Void in
                                                                        self?._headingsHasModification = true
        }
    }
}
