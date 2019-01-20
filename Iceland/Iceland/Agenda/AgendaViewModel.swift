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
    public weak var dependency: AgendaCoordinator?
    private let documentSearchManager: DocumentSearchManager
    private let headingTrimmer: OutlineTextTrimmer
    
    public init(documentSearchManager: DocumentSearchManager, headingTrimmer: OutlineTextTrimmer) {
        self.documentSearchManager = documentSearchManager
        self.headingTrimmer = headingTrimmer
    }
    
    public var data: [AgendaCellModel] = []
    
    private var allData: [AgendaCellModel] = []
    
    public func load(date: Date) {
        self.data = self.allData.filter {
            switch ($0.schedule?.date, $0.due?.date) {
            case (nil, nil): return true
            case (let schedule?, nil):
                return schedule >= date
            case (nil, let due?):
                return due <= date
            case (let schedule?, let due?):
                return schedule <= date || due <= date
            }
        }
    }
    
    public func loadAllData() {
        self.documentSearchManager.loadAllHeadingsThatIsUnfinished(complete: { searchResults in
            self.allData = searchResults.map { AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url, trimmedHeading: self.headingTrimmer.trim(string: $0.context, range: NSRange(location: 0, length: $0.context.count))) }
            self.delegate?.didCompleteLoadAllData()
        }) { error in
            self.delegate?.didFailed(error)
        }
    }
    
    public func showActions(index: Int) {
        dependency?.openAgendaActions(url: self.data[index].url, heading: self.data[index].heading)
    }
    
    public func load(plannings: [String]) {
        var newData: [AgendaCellModel] = []
        self.documentSearchManager
            .search(plannings: plannings,
                    resultAdded: { (result) in
                        newData.append(contentsOf: result
                            .filter {
                                $0.heading != nil
                            }
                            .map {
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url, trimmedHeading: self.headingTrimmer.trim(string: $0.context, range: NSRange(location: 0, length: $0.context.count)))
                            }
                        )
            }, complete: { [weak self] in
                self?.data = newData
            }, failed: { [weak self] error in
                self?.delegate?.didFailed(error)
            }
        )
    }
    
    public func loadOverDue() {
        let calendar = Calendar.current
        let beforeToday = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: Date()))!
        var newData: [AgendaCellModel] = []
        self.documentSearchManager
            .search(due: beforeToday,
                    resultAdded: { (result) in
                        newData.append(contentsOf: result
                            .filter {
                                $0.heading != nil
                            }
                            .map {
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url, trimmedHeading: self.headingTrimmer.trim(string: $0.context, range: NSRange(location: 0, length: $0.context.count)))
                            }
                        )
            }, complete: { [weak self] in
                self?.data = newData
                }, failed: { [weak self] error in
                    self?.delegate?.didFailed(error)
            })
    }
    
    public func loadOverDueToday() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.setValue(23, for: Calendar.Component.hour)
        components.setValue(59, for: Calendar.Component.minute)
        components.setValue(59, for: Calendar.Component.second)
        let endOfToday = calendar.date(from: components)!
        var newData: [AgendaCellModel] = []
        self.documentSearchManager
            .search(due: endOfToday,
                    resultAdded: { (result) in
                        newData.append(contentsOf: result
                            .filter {
                                $0.heading != nil
                            }
                            .map {
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url, trimmedHeading: self.headingTrimmer.trim(string: $0.context, range: NSRange(location: 0, length: $0.context.count)))
                            }
                        )
            }, complete: { [weak self] in
                self?.data = newData
                }, failed: { [weak self] error in
                    self?.delegate?.didFailed(error)
            })
    }
    
    public func loadHasDueDate() {
        var newData: [AgendaCellModel] = []
        self.documentSearchManager
            .search(due: Date.distantFuture,
                    resultAdded: { (result) in
                        newData.append(contentsOf: result
                            .filter {
                                $0.heading != nil
                            }
                            .map {
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url, trimmedHeading: self.headingTrimmer.trim(string: $0.context, range: NSRange(location: 0, length: $0.context.count)))
                            }
                        )
            }, complete: { [weak self] in
                self?.data = newData
                }, failed: { [weak self] error in
                    self?.delegate?.didFailed(error)
            })
    }
    
    public func loadScheduled() {
        var newData: [AgendaCellModel] = []
        self.documentSearchManager
            .search(schedule: Date.distantFuture,
                    resultAdded: { (result) in
                        newData.append(contentsOf: result
                            .filter {
                                $0.heading != nil
                            }
                            .map {
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url, trimmedHeading: self.headingTrimmer.trim(string: $0.context, range: NSRange(location: 0, length: $0.context.count)))
                            }
                        )
            }, complete: { [weak self] in
                self?.data = newData
                }, failed: { [weak self] error in
                    self?.delegate?.didFailed(error)
            })
    }
    
    public func saveToCalendar(index: Int) {
        // TODO: save to calendar
    }
    
    public func openDocument(index: Int) {
        self.dependency?.openDocument(url: self.data[index].url,
                                      location: self.data[index].headingLocation)
    }
}
