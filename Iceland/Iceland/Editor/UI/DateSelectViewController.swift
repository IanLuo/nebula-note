//
//  DateSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/3/16.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import JTAppleCalendar
import Interface

public protocol DateSelectViewControllerDelegate: class {
    func didSelect(date: Date)
}

public class DateSelectViewController: UIViewController {

    public weak var delgate: DateSelectViewControllerDelegate?
    
    private let _calendarView: JTAppleCalendarView = {
        let view = JTAppleCalendarView()
        view.register(viewClass: DateCell.self, forDecorationViewOfKind: DateCell.reuseIdentifier)
        return view
    }()
    
    public override func loadView() {
        super.loadView()
        
    }
    
    public var selectedDates: [Date] {
        set { self._calendarView.selectDates(newValue, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: false) }
        get { return self._calendarView.selectedDates }
    }
    
    public override func viewDidLoad() {
        self.view.addSubview(self._calendarView)
        
        self._calendarView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self._calendarView.calendarDelegate = self
        self._calendarView.calendarDataSource = self
    }
}

extension DateSelectViewController: JTAppleCalendarViewDelegate {
    public func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let cell = cell as! DateCell
        
        cell.isUserSelected = cellState.isSelected
        cell.dateLabel.text = "\(date.day)"
    }
    
    public func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: DateCell.reuseIdentifier, for: indexPath) as! DateCell
        return cell
    }
}

extension DateSelectViewController: JTAppleCalendarViewDataSource {
    public func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        return ConfigurationParameters(startDate: Date.distantPast,
                                       endDate: Date.distantFuture,
                                       numberOfRows: 7,
                                       calendar: Calendar.current,
                                       generateInDates: InDateCellGeneration.forAllMonths,
                                       generateOutDates: OutDateCellGeneration.tillEndOfRow,
                                       firstDayOfWeek: DaysOfWeek.monday,
                                       hasStrictBoundaries: true)
    }
}


private class DateCell: JTAppleCell {
    public static let reuseIdentifier: String = "JTAppleCell"
    
    public let dateLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    public var isUserSelected: Bool = false {
        didSet {
            if isUserSelected {
                self.dateLabel.backgroundColor = InterfaceTheme.Color.spotlight
                self.dateLabel.textColor = InterfaceTheme.Color.interactive
            } else {
                self.dateLabel.backgroundColor = InterfaceTheme.Color.background1
                self.dateLabel.textColor = InterfaceTheme.Color.interactive
            }
        }
    }
}
