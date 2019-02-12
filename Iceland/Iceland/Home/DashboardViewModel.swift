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
    func didLoadAllTags()
    func didLoadScheduled()
    func didLoadOverdue()
    func didLoadScheduledSoon()
    func didLoadOverdueSoon()
    func didLoadWithoutTag()
}

public class DashboardViewModel {
    public weak var coordinator: HomeCoordinator?
    private let documentSearchManager: DocumentSearchManager
    public weak var delegate: DashboardViewModelDelegate?
    
    public init(documentSearchManager: DocumentSearchManager) {
        self.documentSearchManager = documentSearchManager
    }
    
    public var allTags: [String] = []
    
    public var scheduled: [Date] = []
    
    public var overdue: [Date] = []
    
    public var scheduledSoon: [Date] = []
    
    public var overdueSoon: [Date] = []
    
    public var withoutTag: [Date] = []
    
    public func loadAllTags() {
        self.documentSearchManager.loadAllTags { [weak self] searchResult in
            self?.allTags = searchResult.map { $0.context }
            self?.delegate?.didLoadAllTags()
        }
    }
    
    public func loadPlanned() {
        self.documentSearchManager.loadAllHeadingsThatIsUnfinished(complete: { [weak self] searchResults in
            self?.scheduled = [Date()]
            self?.delegate?.didLoadScheduled()
            self?.overdue = [Date()]
            self?.delegate?.didLoadOverdue()
            self?.scheduledSoon = [Date()]
            self?.delegate?.didLoadScheduledSoon()
            self?.overdueSoon = [Date()]
            self?.delegate?.didLoadOverdueSoon()
            self?.withoutTag = [Date()]
            self?.delegate?.didLoadWithoutTag()
        }) { error in
            log.error(error)
        }
    }
}
