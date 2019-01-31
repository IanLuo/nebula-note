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
    public weak var coordinator: AgendaCoordinator?
    private let documentSearchManager: DocumentSearchManager
    private let textTrimmer: OutlineTextTrimmer
    
    public init(documentSearchManager: DocumentSearchManager, textTrimmer: OutlineTextTrimmer) {
        self.documentSearchManager = documentSearchManager
        self.textTrimmer = textTrimmer
    }
    
    public var data: [AgendaCellModel] = []
    
    private var allData: [AgendaCellModel] = []
    
    public func load(date: Date) {
        self.data = self.allData.filter {
            switch ($0.schedule?.date, $0.due?.date) {
            case (let schedule?, nil): return schedule <= date
            default: return true
            }
        }
        
        self.delegate?.didLoadData()
    }
    
    public func loadAllData() {
        self.documentSearchManager.loadAllHeadingsThatIsUnfinished(complete: { searchResults in
            self.allData = searchResults.map { AgendaCellModel(heading: $0.heading!, paragraph: $0.context, url: $0.url, textTrimmer: self.textTrimmer) }
            self.delegate?.didCompleteLoadAllData()
        }) { error in
            self.delegate?.didFailed(error)
        }
    }
    
    public func showActions(index: Int) {
        self.coordinator?.openAgendaActions(url: self.data[index].url, heading: self.data[index].heading)
    }
    
    public func load(plannings: [String]) {
        var newData: [AgendaCellModel] = []
        self.documentSearchManager
            .search(plannings: plannings,
                    resultAdded: { (result) in
                        newData.append(contentsOf: result
                            .filter { $0.heading != nil }
                            .map { AgendaCellModel(heading: $0.heading!, paragraph: $0.context, url: $0.url, textTrimmer: self.textTrimmer) }
                        )
            }, complete: { [weak self] in
                self?.data = newData
            }, failed: { [weak self] error in
                self?.delegate?.didFailed(error)
            }
        )
    }
    
    public func saveToCalendar(index: Int) {
        // TODO: save to calendar
    }
    
    public func openDocument(index: Int) {
        self.coordinator?.openDocument(url: self.data[index].url,
                                      location: self.data[index].headingLocation)
    }
}
