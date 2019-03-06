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
    
    public var scheduled: [DocumentHeading] = []
    
    public var overdue: [DocumentHeading] = []
    
    public var scheduledSoon: [DocumentHeading] = []
    
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
        self.loadData()
    }
    
    public func loadData() {
        let today = Date()
        let soon = Date(timeInterval: 3 * 24 * 60, since: today)
        
        self.allTags = []
        self.withoutTag = []
        self.scheduled = []
        self.scheduledSoon = []
        self.overdue = []
        self.overdueSoon = []
        self._documentSearchManager.searchHeading(options: [.tag, .due, .schedule, .planning],
        resultAdded: { headings in
            headings.forEach { heading in
                if let tags = heading.tags {
                    self.allTags.append(contentsOf: tags)
                } else {
                    self.withoutTag.append(heading)
                }
                
                if let schedule = heading.schedule {
                    if schedule.date <= today {
                        self.scheduled.append(heading)
                    } else if schedule.date <= soon {
                        self.scheduledSoon.append(heading)
                    }
                }
                
                if let due = heading.due {
                    if due.date <= today {
                        self.overdue.append(heading)
                    } else if due.date <= soon {
                        self.overdueSoon.append(heading)
                    }
                }
            }
        }, complete: {
            self._isHeadingsNeedsReload = false
            self.delegate?.didCompleteLoadFilteredData()
        }, failed: { error in
            print(error)
        })
    }
}
