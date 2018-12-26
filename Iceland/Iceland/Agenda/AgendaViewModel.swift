//
//  AgendaViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol AgendaViewModelDelegate: class {
    func didLoadData()
    func didFailed(_ error: Error)
}

public class AgendaViewModel {
    public weak var delegate: AgendaViewModelDelegate?
    public weak var dependency: AgendaCoordinator?
    private let documentSearchManager: DocumentSearchManager
    
    public init(documentSearchManager: DocumentSearchManager) {
        self.documentSearchManager = documentSearchManager
    }
    
    public var data: [AgendaCellModel] = [] {
        didSet {
            self.delegate?.didLoadData()
        }
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
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url)
                            }
                        )
            }, complete: { [weak self] in
                self?.data = newData
                }, failed: { [weak self] error in
                    self?.delegate?.didFailed(error)
            })
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
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url)
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
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url)
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
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url)
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
                                AgendaCellModel(heading: $0.heading!, text: $0.context, url: $0.url)
                            }
                        )
            }, complete: { [weak self] in
                self?.data = newData
                }, failed: { [weak self] error in
                    self?.delegate?.didFailed(error)
            })
    }
    
    public func openDocument(index: Int) {
        self.dependency?.openDocument(url: self.data[index].url,
                                      location: self.data[index].headingLocation)
    }
}
