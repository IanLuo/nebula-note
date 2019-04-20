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
    func didCompleteLoadAllData()
    func didFailed(_ error: Error)
}

public class AgendaViewModel {
    public weak var delegate: AgendaViewModelDelegate?
    public weak var coordinator: AgendaCoordinator? {
        didSet {
            self._setupObserver()
        }
    }
    private let _documentSearchManager: DocumentSearchManager
    
    public init(documentSearchManager: DocumentSearchManager) {
        self._documentSearchManager = documentSearchManager
        
        var dates: [Date] = []
        let today = Date()
        for i in 0..<30 {
            dates.append(today.dayBefore(30 - i))
        }
        
        for i in 0..<30 {
            dates.append(today.dayAfter(i))
        }
        
        self.dates = dates
    }
    
    /// 用于显示的数据
    public private(set) var dateOrderedData: [[AgendaCellModel]] = []
    public private(set) var data: [AgendaCellModel] = []
    public private(set) var dates: [Date] = []
    
    private var _shouldReloadData: Bool = true // 如果在这个界面打开的 document 修改了这个 heading，应该刷新
    public var isConnectingScreen: Bool = false
    
    
    private let _headingChangeObservingQueue: OperationQueue = {
        let queue = OperationQueue()
        let dispatchQueue = DispatchQueue(label: "dashboard handling heading change", qos: DispatchQoS.background, attributes: [])
        queue.underlyingQueue = dispatchQueue
        return queue
    }()
    
    public var filterType: AgendaCoordinator.FilterType?
    
    public func cellModels(at section: Int) -> [AgendaCellModel] {
        if self.dateOrderedData.count > section {
            return self.dateOrderedData[section]
        } else {
            return []
        }
    }
    
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
    
    public func loadFiltered() {
        if let filterType = self.filterType {
            var data: [DocumentHeading] = []
            let today = Date()
            let soon = Date(timeInterval: 3 * 24 * 60, since: today)
            
        }
    }
    
    // 加载 agenda 界面所有数据
    public func loadAgendaData() {
        self._documentSearchManager.searchDateAndTime(completion: { [weak self] results in
            let allData = results.map { AgendaCellModel(searchResult: $0) }
            
            self?.dateOrderedData = []
            
            self?.dates.forEach { date in
                let mappedCellModels = allData.filter { cellModel in
                    if let planning = cellModel.planning, SettingsAccessor.shared.finishedPlanning.contains(planning) // 已完成的条目不显示
                    {
                        return false
                    }
                    else if let dateAndTime = cellModel.dateAndTime
                    {
                        if dateAndTime.isSchedule || dateAndTime.isDue
                        {
                            return dateAndTime.date <= date
                        }
                        else
                        {
                            return dateAndTime.date.isSameDay(date)
                        }
                    }
                    else
                    {
                        return true
                    }
                }
                
                self?.dateOrderedData.append(mappedCellModels)
            }
            
            DispatchQueue.main.async {
                self?.delegate?.didCompleteLoadAllData()
            }
            
        }) { [weak self] error in
            self?.delegate?.didFailed(error)
        }
    }
    
    public func saveToCalendar(index: Int) {
        // TODO: save to calendar
    }
    
    public func updateDate(cellModel: AgendaCellModel, _ newDateAndTime: DateAndTimeType?) {
        if let editorService = self.coordinator?.dependency.editorContext.request(url: cellModel.url) {
            editorService.open(completion: { [unowned editorService] _ in
                if let oldDateAndTimeRange = cellModel.dateAndTimeRange {
                    _ = editorService.toggleContentCommandComposer(composer: UpdateDateAndTimeCommandComposer(location: oldDateAndTimeRange.location,
                                                                                                          dateAndTime: newDateAndTime))
                        .perform()
                    
                    self.coordinator?.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: cellModel.dateAndTime,
                                                                                            newDateAndTime: newDateAndTime))
                }
            })
        }
    }
    
    public func openDocument(cellModel: AgendaCellModel) {
        self.coordinator?.openDocument(url: cellModel.url,
                                      location: cellModel.heading.location)
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
    }
}
