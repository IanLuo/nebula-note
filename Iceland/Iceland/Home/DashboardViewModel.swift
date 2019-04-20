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
    
    public var scheduled: [DocumentHeading] = []
    
    public var overdue: [DocumentHeading] = []
    
    public var startSoon: [DocumentHeading] = []
    
    public var overdueSoon: [DocumentHeading] = []
    
    public var withoutTag: [DocumentHeading] = []
    
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
    }
    
    public func loadDataIfNeeded() {
        guard _isHeadingsNeedsReload else { return }
        _isHeadingsNeedsReload = false
        
        self.loadData()
    }
    
    public func loadData() {
        let today = Date()
        let soon = Date(timeInterval: 3 * 24 * 60, since: today)
        
        self.allTags = []
        self.allPlannings = []
        self.withoutTag = []
        self.scheduled = []
        self.startSoon = []
        self.overdue = []
        self.overdueSoon = []
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        self._documentSearchManager.searchDateAndTime(completion: { [weak self] results in
            results.forEach { result in
                if let dateAndTime = result.dateAndTime {
                    if dateAndTime.isDue {
                        if dateAndTime.date >= today {
                            self?.overdue.append(result.heading)
                        } else if dateAndTime.date >= soon {
                            self?.overdueSoon.append(result.heading)
                        }
                    } else if dateAndTime.isSchedule {
                        if dateAndTime.date >= today {
                            self?.scheduled.append(result.heading)
                        } else if dateAndTime.date >= soon {
                            self?.startSoon.append(result.heading)
                        }
                    } else {
                        if dateAndTime.date >= today {
                            self?.startSoon.append(result.heading)
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
        self._documentSearchManager.allHeadings(completion: { [weak self] headings in
            var allTags:[String] = []
            var allPlannings: [String] = []
            for heading in headings {
                if let tags = heading.tags {
                    allTags.append(contentsOf: tags)
                } else {
                    self?.withoutTag.append(heading)
                }
                
                if let planning = heading.planning {
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
