//
//  AgendaActionViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/27.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol AgendaActionViewModelDelegate: class {
    func didUpdated()
}

public class AgendaActionViewModel {
    public weak var delegate: AgendaActionViewModelDelegate?
    private let service: EditorService
    private let heading: OutlineTextStorage.Heading
    
    public init(service: EditorService, heading: OutlineTextStorage.Heading) {
        self.service = service
        self.heading = heading
    }
    
    public func updateSchedule(schedule: DateAndTimeType?) {
        if let schedule = schedule {
            self.service.update(schedule: schedule, at: heading.range.location)
        } else {
            self.service.removeSchedule(at: heading.range.location)
        }
    }
    
    public func updateDue(due: DateAndTimeType?) {
        if let due = due {
            self.service.update(due: due, at: heading.range.location)
        } else {
            self.service.removeDue(at: heading.range.location)
        }
    }
    
    public func updatePlanning(planning: String?) {
        if let planning = planning {
            self.service.update(planning: planning, at: heading.range.location)
        } else {
            self.service.removePlanning(at: heading.range.location)
        }
    }
}
