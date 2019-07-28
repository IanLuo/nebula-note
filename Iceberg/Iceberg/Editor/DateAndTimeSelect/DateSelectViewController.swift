//
//  DateSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/3/16.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import KDCalendar
import Interface

public protocol DateSelectViewControllerDelegate: class {
    func didSelect(date: Date)
}

public class DateSelectViewController: UIViewController {

    public weak var delegate: DateSelectViewControllerDelegate?
    
    private let _calendarView: CalendarView = {
        let view = CalendarView()
        
        view.calendar = Calendar.current
        
        view.interface({ (me, theme) in
            me.backgroundColor = InterfaceTheme.Color.background2
        })
        return view
    }()
    
    public var currentDate: Date?
    
    public override func viewDidLoad() {
        self.view.addSubview(self._calendarView)
        
        self._calendarView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self._calendarView.delegate = self
        self._calendarView.dataSource = self
        
        CalendarView.Style.cellShape                = .round
        CalendarView.Style.cellColorDefault         = InterfaceTheme.Color.background2
        CalendarView.Style.cellSelectedBorderColor  = InterfaceTheme.Color.spotlight
        CalendarView.Style.cellSelectedColor        = InterfaceTheme.Color.spotlight
        CalendarView.Style.headerTextColor          = InterfaceTheme.Color.descriptive
        CalendarView.Style.cellTextColorDefault     = InterfaceTheme.Color.interactive
        CalendarView.Style.cellTextColorToday       = InterfaceTheme.Color.spotlight
        CalendarView.Style.cellColorToday           = InterfaceTheme.Color.background1
        CalendarView.Style.cellEventColor           = InterfaceTheme.Color.spotlight
        CalendarView.Style.headerTextColor          = InterfaceTheme.Color.descriptiveHighlighted
        
        CalendarView.Style.cellTextColorWeekend = InterfaceTheme.Color.descriptive

        self._calendarView.marksWeekends = true
        self._calendarView.multipleSelectionEnable = false
        
        CalendarView.Style.firstWeekday = Locale.current.regionCode == "CN" ? .monday : .sunday
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self._calendarView.setDisplayDate(self.currentDate ?? Date())

        if let selected = self.currentDate {
            self._calendarView.selectDate(selected)
        }
    }
}

extension DateSelectViewController: CalendarViewDelegate {
    public func calendar(_ calendar: CalendarView, didScrollToMonth date: Date) {
        
    }
    
    public func calendar(_ calendar: CalendarView, didSelectDate date: Date, withEvents events: [CalendarEvent]) {
        self.delegate?.didSelect(date: date)
        self.currentDate = date
    }
    
    public func calendar(_ calendar: CalendarView, canSelectDate date: Date) -> Bool {
        return true
    }
    
    public func calendar(_ calendar: CalendarView, didDeselectDate date: Date) {
        
    }
    
    public func calendar(_ calendar: CalendarView, didLongPressDate date: Date) {
        
    }
}

extension DateSelectViewController: CalendarViewDataSource {
    public func startDate() -> Date {
        var dateComponents = DateComponents()
        dateComponents.month = -3
        let today = Date()
        let threeMonthsAgo = self._calendarView.calendar.date(byAdding: dateComponents, to: today)
        return threeMonthsAgo!
    }
    
    public func endDate() -> Date {
        var dateComponents = DateComponents()
        dateComponents.month = 3
        let today = Date()
        let threeMonthsAgo = self._calendarView.calendar.date(byAdding: dateComponents, to: today)
        return threeMonthsAgo!
    }
}
