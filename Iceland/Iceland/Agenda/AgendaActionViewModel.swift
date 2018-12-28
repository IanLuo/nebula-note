//
//  AgendaActionViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/27.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol AgendaActionViewModelDelegate: class {
    func didUpdated()
}

public class AgendaActionViewModel {
    public weak var delegate: AgendaActionViewModelDelegate?
    public let editViewModel: DocumentEditViewModel
    
    public init(editViewModel: DocumentEditViewModel) {
        self.editViewModel = editViewModel
    }
    
    public func updateSchedule(date: Date?) {
        
    }
    
    public func updateDue(due: Date?) {
        
    }
    
    public func updatePlanning(planning: String?) {
        
    }
    
    public func openDocument() {
        
    }
}
