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
            self._setupHeadingChangeObserver()
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
        
        dates.append(today)
        
        for i in 0..<30 {
            dates.append(today.dayAfter(i))
        }
        
        self.dates = dates
    }
    
    /// 用于显示的数据
    public private(set) var dateOrderedData: [[AgendaCellModel]] = []
    public private(set) var data: [AgendaCellModel] = []
    public private(set) var dates: [Date] = []
    
    private var _lastLoadTime: TimeInterval = 0
    private let _reloadInterval: TimeInterval = 60
    private var _headingsHasModification: Bool = true // 如果在这个界面打开的 document 修改了这个 heading，应该刷新
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
            
        }
    }
    
    // 加载 agenda 界面所有数据
    public func loadAgendaData() {
        self._documentSearchManager.searchDateAndTime(completion: { [weak self] results in
            let allData = results.map { AgendaCellModel(searchResult: $0) }
            
            self?.dates.forEach { date in
                let mappedCellModels = allData.filter { cellModel in
                    if let planning = cellModel.planning {
                        return SettingsAccessor.shared.unfinishedPlanning.contains(planning)
                    } else if let dateAndTime = cellModel.dateAndTime {
                        return dateAndTime.date >= date
                    } else {
                        return false
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
    
    public func updateDate(cellModel: AgendaCellModel, _ schedule: DateAndTimeType?) {
        if let editorService = self.coordinator?.dependency.editorContext.request(url: cellModel.url) {
            editorService.open(completion: { [unowned editorService] _ in
                
            })
        }
    }
    
    public func openDocument(cellModel: AgendaCellModel) {
        self.coordinator?.openDocument(url: cellModel.url,
                                      location: cellModel.heading.location)
    }
    
    private func _setupHeadingChangeObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentSearchHeadingUpdateEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: DocumentSearchHeadingUpdateEvent) -> Void in
                                                                        self?._headingsHasModification = true
        }
    }
}
