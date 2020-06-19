//
//  HomeViewModel.swift
//  Iceland
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Core
import Interface

public protocol DashboardViewModelDelegate: class {
    func didCompleteLoadFilteredData()
}

public class DashboardViewModel: ViewModelProtocol {
    public required init() {
        
    }
    
    public var context: ViewModelContext<CoordinatorType>!
    
    public typealias CoordinatorType = HomeCoordinator
    
    public enum DahsboardItemData {
        case scheduled([DocumentHeadingSearchResult])
        case overdue([DocumentHeadingSearchResult])
        case startSoon([DocumentHeadingSearchResult])
        case overdueSoon([DocumentHeadingSearchResult])
        case today([DocumentHeadingSearchResult])
        case allTags([String])
        case allStatus([String])
    }
    
    public weak var coordinator: HomeCoordinator? {
        didSet {
            self._setupHeadingChangeObserver()
        }
    }

    public weak var delegate: DashboardViewModelDelegate?
    
    deinit {
        self.coordinator?.dependency.eventObserver.unregister(for: self, eventType: nil)
    }
        
    public var itemsData: [DahsboardItemData] = []
    
    public var allTags: [String] {
        for itemData in self.itemsData {
            switch itemData {
            case .allTags(let tags):
                return tags
            default: break
            }
        }
        
        return []
    }
    
    private var _isHeadingsNeedsReload: Bool = true
    
    private let _headingChangeObservingQueue: OperationQueue = {
        let queue = OperationQueue()
        let dispatchQueue = DispatchQueue(label: "dashboard handling heading change", qos: DispatchQoS.background, attributes: [])
        queue.underlyingQueue = dispatchQueue
        return queue
    }()
    
    private func markNeedReloadData() {
        self._isHeadingsNeedsReload = true
        
        if isMacOrPad {
            self.loadDataIfNeeded()
        }
    }
    
    private func _setupHeadingChangeObserver() {
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DocumentHeadingChangeEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: DocumentHeadingChangeEvent) -> Void in
                                                                        self?.markNeedReloadData()
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: NewAttachmentDownloadedEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: NewAttachmentDownloadedEvent) -> Void in
                                                                        self?.markNeedReloadData()
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: AppStartedEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: AppStartedEvent) -> Void in
                                                                        self?.markNeedReloadData()
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: TagAddedEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: TagAddedEvent) -> Void in
                                                                        self?._isHeadingsNeedsReload = true
                                                                        
                                                                        for (index, itemData) in (self?.itemsData ?? []).enumerated() {
                                                                            switch itemData {
                                                                            case .allTags(let tags):
                                                                                if tags.contains(event.tag) == false {
                                                                                    self?.itemsData.remove(at: index)
                                                                                    var tags = tags
                                                                                    tags.append(event.tag)
                                                                                    self?.itemsData.insert(DahsboardItemData.allTags(tags), at: index)
                                                                                }
                                                                            default: break
                                                                            }
                                                                        }
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: TagDeleteEvent.self,
                                                                    queue: self._headingChangeObservingQueue) { [weak self] (event: TagDeleteEvent) -> Void in
                                                                        self?.markNeedReloadData()
        }
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: DateAndTimeChangedEvent.self,
                                                                    queue: self._headingChangeObservingQueue,
                                                                    action: { [weak self] (event: DateAndTimeChangedEvent) -> Void in
                                                                        self?.markNeedReloadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudOpeningStatusChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudOpeningStatusChangedEvent) in
                                                                        self?.markNeedReloadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: NewDocumentPackageDownloadedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: NewDocumentPackageDownloadedEvent) in
                                                                        self?.markNeedReloadData()
        })
        
        self.coordinator?.dependency.eventObserver.registerForEvent(on: self,
                                                                    eventType: iCloudAvailabilityChangedEvent.self,
                                                                    queue: .main,
                                                                    action: { [weak self] (event: iCloudAvailabilityChangedEvent) in
                                                                        self?._isHeadingsNeedsReload = true
                                                                        self?.loadDataIfNeeded()
        })
    }
    
    public func loadDataIfNeeded() {
        guard _isHeadingsNeedsReload else { return }
        _isHeadingsNeedsReload = false
        
        self.loadData()
    }
    
    private var isLoading: Bool = false
    public func loadData() {
        guard self.isLoading == false else { return }
        self.isLoading = true
        
        let today = Date().dayEnd
        
        var scheduled: [DocumentHeadingSearchResult] = []
        var startSoon: [DocumentHeadingSearchResult] = []
        var overdue: [DocumentHeadingSearchResult] = []
        var overdueSoon: [DocumentHeadingSearchResult] = []
        var todayData: [DocumentHeadingSearchResult] = []
        
        self.itemsData = []
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        self.context.dependency.documentSearchManager.searchDateAndTime(completion: { [weak self] results in
            results.forEach { result in
                if let planning = result.heading.planning,
                    let finishedPlannings = self?.coordinator?.dependency.settingAccessor.finishedPlanning,
                    finishedPlannings.contains(planning) {
                    return
                }
                
                if let dateAndTime = result.dateAndTime {
                    let daysFromToday = dateAndTime.date.daysFrom(today) // date from the date to today
                    
                    if dateAndTime.date.isToday() {
                        todayData.append(result)
                    } else if dateAndTime.isDue {
                        if daysFromToday < 0 {
                            overdue.append(result)
                        } else if daysFromToday <= 3 {
                            overdueSoon.append(result)
                        }
                    } else if dateAndTime.isSchedule {
                        if daysFromToday <= 3 && daysFromToday > 0 {
                            startSoon.append(result)
                        } else {
                            scheduled.append(result)
                        }
                    } else {
                        if daysFromToday <= 3 && daysFromToday > 0 {
                            startSoon.append(result)
                        } else {
                            scheduled.append(result)
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
        self.context.dependency.documentSearchManager.allHeadings(completion: { [weak self] results in
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
            
            if allTags.count > 0 {
                self?.itemsData.append(DahsboardItemData.allTags(Array<String>(Set(allTags))))
            }
            
            if allPlannings.count > 0 {
                self?.itemsData.append(DahsboardItemData.allStatus(Array<String>(Set(allPlannings))))
            }
            
            dispatchGroup.leave()
        }) { error in
            log.error(error)
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            if overdue.count > 0 {
                self.itemsData.append(DahsboardItemData.overdue(overdue))
            }
            
            if startSoon.count > 0 {
                self.itemsData.append(DahsboardItemData.startSoon(startSoon))
            }
            
            if overdueSoon.count > 0 {
                self.itemsData.append(DahsboardItemData.overdueSoon(overdueSoon))
            }
            
            if todayData.count > 0 {
                self.itemsData.append(DahsboardItemData.today(todayData))
            }
            
            if scheduled.count > 0 {
                self.itemsData.append(DahsboardItemData.scheduled(scheduled))
            }
            
            self.delegate?.didCompleteLoadFilteredData()
            self.isLoading = false
        }
    }
}
