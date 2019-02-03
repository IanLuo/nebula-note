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
    
    /// 在 agenda view controller 中，首先加载所有的数据，根据选择的日期来过滤要显示的 heading
    private var allData: [AgendaCellModel] = []
    
    var filterType: AgendaCoordinator.FilterType?
    
    public func load(date: Date) {
        self.data = self.allData.filter {
            switch ($0.schedule?.date, $0.due?.date) {
            case (let schedule?, nil): return schedule <= date
            default: return true
            }
        }
        
        self.delegate?.didLoadData()
    }
    
    public func loadFiltered() {
        if let filterType = self.filterType {
            switch filterType {
            case .tag(let tag):
                var data: [DocumentSearchResult] = []
                self.documentSearchManager.search(tags: [tag], resultAdded: { (searchResults: [DocumentSearchResult]) -> Void in
                    data.append(contentsOf: searchResults)
                }, complete: {
                    self.data = data.map { AgendaCellModel(heading: $0.heading!, paragraph: $0.context, url: $0.url, textTrimmer: self.textTrimmer) }
                    self.delegate?.didLoadData()
                }, failed: {
                    self.delegate?.didFailed($0)
                })
            default: break
            }
        }
    }
    
    public func loadAllData() {
        self.documentSearchManager.loadAllHeadingsThatIsUnfinished(complete: { searchResults in
            self.allData = searchResults.map { AgendaCellModel(heading: $0.heading!, paragraph: $0.context, url: $0.url, textTrimmer: self.textTrimmer) }
            self.delegate?.didCompleteLoadAllData()
        }) { error in
            self.delegate?.didFailed(error)
        }
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
