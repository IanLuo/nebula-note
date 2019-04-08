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
    private var _headingsHasModification: Bool = true // 如果在这个界面打开的 document 修改了这个 heading，应该刷新
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
        self.data = self._allData.filter { searchResult in
            if let planning = searchResult.planning {
                return SettingsAccessor.shared.unfinishedPlanning.contains(planning)
            } else if let dateAndTime = searchResult.dateAndTime {
                return dateAndTime.date >= date
            } else {
                return false
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
            
        }
    }
    
    // 加载 agenda 界面所有数据
    public func loadAgendaData() {
        self._documentSearchManager.searchDateAndTime(completion: { [weak self] results in
            self?._allData = results.map { AgendaCellModel(searchResult: $0) }
        }) { [weak self] error in
            self?.delegate?.didFailed(error)
        }
    }
    
    public func saveToCalendar(index: Int) {
        // TODO: save to calendar
    }
    
    public func updateDate(index: Int, _ schedule: DateAndTimeType?) {
        let cellModel = self.data[index]
        if let editorService = self.coordinator?.dependency.editorContext.request(url: cellModel.url) {
            editorService.open(completion: { [unowned editorService] _ in
                
            })
        }
    }
    
    public func openDocument(index: Int) {
        self.coordinator?.openDocument(url: self.data[index].url,
                                      location: self.data[index].heading.location)
    }
    
    private func _setupHeadingChangeObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentSearchHeadingUpdateEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: DocumentSearchHeadingUpdateEvent) -> Void in
                                                                        self?._headingsHasModification = true
        }
    }
}
