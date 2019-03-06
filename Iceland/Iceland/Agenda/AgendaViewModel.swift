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
    
    public var data: [AgendaCellModel] = []
    
    /// 在 agenda view controller 中，首先加载所有的数据，根据选择的日期来过滤要显示的 heading
    private var _allData: [AgendaCellModel] = []
    
    private let _headingChangeObservingQueue: OperationQueue = {
        let queue = OperationQueue()
        let dispatchQueue = DispatchQueue(label: "dashboard handling heading change", qos: DispatchQoS.background, attributes: [])
        queue.underlyingQueue = dispatchQueue
        return queue
    }()
    
    private var _isHeadingsNeedsReload: Bool = true
    
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
    
    public func loadDataIfNeed() {
        guard _isHeadingsNeedsReload else { return }
        
        if self.filterType == nil {
            self.loadAllData()
        } else {
            self.loadFiltered()
        }
    }
    
    public func loadFiltered() {
        if let filterType = self.filterType {
            var data: [DocumentHeading] = []
            let today = Date()
            let soon = Date(timeInterval: 3 * 24 * 60, since: today)
            self._documentSearchManager.searchHeading(options: [.tag, .due, .schedule, .planning], filter: { [weak self] (heading: DocumentHeading) -> Bool in
                self?._isHeadingsNeedsReload = false
                switch filterType {
                case .tag(let tag):
                    return heading.tags?.contains(tag) ?? false
                case .overdue:
                    return (heading.due?.date ?? Date.distantFuture) <= today
                case .scheduled:
                    return (heading.schedule?.date ?? Date.distantFuture) <= today
                case .dueSoon:
                    return (heading.due?.date ?? Date.distantFuture) <= soon
                case .scheduledSoon:
                    return (heading.schedule?.date ?? Date.distantFuture) <= soon
                case .withoutDate:
                    return heading.tags == nil
                }
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
    public func loadAllData() {
        var searchResults: [DocumentHeading] = []
        let today = Date()
        self._documentSearchManager.searchHeading(options: [.tag, .due, .schedule, .planning], filter: { (heading: DocumentHeading) -> Bool in
            if let planning = heading.planning {
                if SettingsAccessor.shared.unfinishedPlanning.contains(planning) {
                    return true
                }
            }
            if let due = heading.due, due.date >= today {
                return true
            }
            if let schedule = heading.schedule, schedule.date >= today {
                return true
            }
            
            return false
        }, resultAdded: { (results: [DocumentHeading]) in
            let sorted = results.sorted { left, right in
                switch (left.due, left.schedule, right.due, right.schedule) {
                case (let leftDue?, _, let rightDue?, _): return leftDue.date.timeIntervalSince1970 < rightDue.date.timeIntervalSince1970
                case (_?, _, nil, _): return true
                case (nil, _, _?, _): return false
                case (nil, let leftSchedule?, nil, let rightSchedule?): return leftSchedule.date.timeIntervalSince1970 < rightSchedule.date.timeIntervalSince1970
                case (_, _?, _, nil): return true
                case (_, nil, _, _?): return false
                default: return true
                }
            }
            
            searchResults.append(contentsOf: sorted)
        }, complete: { [weak self] in
            self?._isHeadingsNeedsReload = false
            self?._allData = searchResults.map { AgendaCellModel(heading: $0) }
            self?.delegate?.didCompleteLoadAllData()
        }, failed: { [weak self] error in
            self?.delegate?.didFailed(error)
        })
    }
    
    public func saveToCalendar(index: Int) {
        // TODO: save to calendar
    }
    
    public func openDocument(index: Int) {
        self.coordinator?.openDocument(url: self.data[index].url,
                                      location: self.data[index].headingLocation)
    }
    
    private func _setupHeadingChangeObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentSearchHeadingUpdateEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: DocumentSearchHeadingUpdateEvent) -> Void in
                                                                        self?._isHeadingsNeedsReload = true
        }
    }
}
