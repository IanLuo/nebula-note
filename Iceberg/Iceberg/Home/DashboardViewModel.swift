//
//  HomeViewModel.swift
//  Iceland
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Business

public protocol DashboardViewModelDelegate: class {
    func didCompleteLoadFilteredData()
}

public class DashboardViewModel {
    public weak var coordinator: HomeCoordinator? {
        didSet {
            self._setupHeadingChangeObserver()
        }
    }
    private let _documentSearchManager: DocumentSearchManager
    public weak var delegate: DashboardViewModelDelegate?
    
    public init(documentSearchManager: DocumentSearchManager) {
        self._documentSearchManager = documentSearchManager
    }
    
    deinit {
        self.coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
    
    public var allTags: [String] = []
    
    public var allPlannings: [String] = []
    
    public var scheduled: [DocumentHeadingSearchResult] = []
    
    public var overdue: [DocumentHeadingSearchResult] = []
    
    public var startSoon: [DocumentHeadingSearchResult] = []
    
    public var overdueSoon: [DocumentHeadingSearchResult] = []
    
    private var _isHeadingsNeedsReload: Bool = true
    
    private let _headingChangeObservingQueue: OperationQueue = {
        let queue = OperationQueue()
        let dispatchQueue = DispatchQueue(label: "dashboard handling heading change", qos: DispatchQoS.background, attributes: [])
        queue.underlyingQueue = dispatchQueue
        return queue
    }()
    
    private func _setupHeadingChangeObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentSearchHeadingUpdateEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: DocumentSearchHeadingUpdateEvent) -> Void in
            self?._isHeadingsNeedsReload = true
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: NewAttachmentDownloadedEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: NewAttachmentDownloadedEvent) -> Void in
                                                                        self?._isHeadingsNeedsReload = true
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: AppStartedEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: AppStartedEvent) -> Void in
                                                                        self?.loadDataIfNeeded()
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: TagAddedEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: TagAddedEvent) -> Void in
                                                                        self?._isHeadingsNeedsReload = true
                                                                        if self?.allTags.contains(event.tag) == false {
                                                                            self?.allTags.append(event.tag)
                                                                        }
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: TagDeleteEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: TagDeleteEvent) -> Void in
                                                                        self?._isHeadingsNeedsReload = true
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DateAndTimeChangedEvent.self,
                                                                    queue: self._headingChangeObservingQueue,
                                                                    action: { [weak self] (event: DateAndTimeChangedEvent) -> Void in
                                                                        self?._isHeadingsNeedsReload = true
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudOpeningStatusChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
            self?._isHeadingsNeedsReload = true
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: NewDocumentPackageDownloadedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
            self?._isHeadingsNeedsReload = true
        })
    }
    
    public func loadDataIfNeeded() {
        guard _isHeadingsNeedsReload else { return }
        _isHeadingsNeedsReload = false
        
        self.loadData()
    }
    
    public func loadData() {
        let today = Date().dayEnd
        
        self.allTags = []
        self.allPlannings = []
        self.scheduled = []
        self.startSoon = []
        self.overdue = []
        self.overdueSoon = []
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        self._documentSearchManager.searchDateAndTime(completion: { [weak self] results in
            results.forEach { result in
                if let planning = result.heading.planning,
                    let finishedPlannings = self?.coordinator?.dependency.settingAccessor.finishedPlanning,
                    finishedPlannings.contains(planning) {
                    return
                }
                
                if let dateAndTime = result.dateAndTime {
                    let daysFromToday = dateAndTime.date.daysFrom(today) // date from the date to today
                    
                    if dateAndTime.isDue {
                        if daysFromToday < 0 {
                            self?.overdue.append(result)
                        } else if daysFromToday <= 3 {
                            self?.overdueSoon.append(result)
                        }
                    } else if dateAndTime.isSchedule {
                        if daysFromToday <= 3 && daysFromToday > 0 {
                            self?.startSoon.append(result)
                        } else {
                            self?.scheduled.append(result)
                        }
                    } else {
                        if daysFromToday <= 3 && daysFromToday > 0 {
                            self?.startSoon.append(result)
                        } else {
                            self?.scheduled.append(result)
                        }
                    }
                }
            }
            dispatchGroup.leave()
        }) { error in
            log.error(error)
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self._documentSearchManager.allHeadings(completion: { [weak self] results in
            var allTags:[String] = []
            var allPlannings: [String] = []
            for result in results {
                if let tags = result.heading.tags {
                    allTags.append(contentsOf: tags)
                }
                
                if let planning = result.heading.planning {
                    allPlannings.append(planning)
                }
            }
            
            self?.allTags = Array<String>(Set(allTags))
            self?.allPlannings = Array<String>(Set(allPlannings))
            
            dispatchGroup.leave()
        }) { error in
            log.error(error)
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.delegate?.didCompleteLoadFilteredData()
        }
    }
}
