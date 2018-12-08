//
//  AgendaViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol AgendaViewModelDelegate: class {
    func openDocument(url: URL, location: Int)
    func refileTo(url: URL, content: String, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func changePlanning(to: String, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func reschedule(to: DateAndTimeType, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func changeDue(to: DateAndTimeType, url: URL, headingLocation: Int, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func search(tags: [String], resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func search(due: Date, resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func search(schedule: Date, resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
    func search(planning: [String], resultAdded: @escaping ([DocumentSearchResult]) -> Void, complete: @escaping () -> Void, failure: @escaping (Error) -> Void)
}

public class AgendaViewModel {
    public weak var delegate: AgendaViewModelDelegate?
    
    public var headings: [OutlineTextStorage.Heading] = [] {
        didSet {
            self.onDataLoaded?(headings.count > 0)
        }
    }
    
    public var onDataLoaded: ((Bool) -> Void)?
    public var onError: ((Error) -> Void)?
    
    public func loadTODOs() {
        self.delegate?.search(tags: [OutlineParser.Values.Heading.Planning.todo], resultAdded: { (result: [DocumentSearchResult]) in
            
        }, complete: {
            
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }
    
    public func loadUnfinished() {
        self.delegate?.search(tags: OutlineParser.Values.Heading.Planning.unfinished, resultAdded: { (result: [DocumentSearchResult]) in
            
        }, complete: {
            
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }
    
    public func loadOverDue() {
        let calendar = Calendar.current
        let beforeToday = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: Date()))!
        self.delegate?.search(due: beforeToday, resultAdded: { (result) in
            
        }, complete: {
            
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }
    
    public func loadOverDueToday() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.setValue(23, for: Calendar.Component.hour)
        components.setValue(59, for: Calendar.Component.minute)
        components.setValue(59, for: Calendar.Component.second)
        let endOfToday = calendar.date(from: components)!
        self.delegate?.search(due: endOfToday, resultAdded: { (result) in
            
        }, complete: {
            
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }
    
    public func loadHasDueDate() {
        self.delegate?.search(due: Date.distantFuture, resultAdded: { (result) in
            
        }, complete: {
            
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }
    
    public func loadScheduled() {
        self.delegate?.search(schedule: Date.distantFuture, resultAdded: { (result) in
            
        }, complete: {
            
        }, failure: { [weak self] error in
            self?.onError?(error)
        })
    }
}
