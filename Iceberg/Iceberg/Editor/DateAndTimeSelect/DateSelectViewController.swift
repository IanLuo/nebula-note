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
import RxSwift
import RxCocoa
import Core
    

public protocol DateSelectViewControllerDelegate: class {
    func didSelect(date: Date)
    func didSelectTime(_ time: (hour: Int, minute: Int, second: Int)?)
}

public class DateSelectViewController: UIViewController {

    public weak var delegate: DateSelectViewControllerDelegate?
    
    private let disposeBag = DisposeBag()
    
    private let calendarView: CalendarView = {
        let view = CalendarView()
        
        view.calendar = Calendar.current
        
        view.interface({ (me, theme) in
            me.backgroundColor = InterfaceTheme.Color.background2
        })
        return view
    }()
    
    public var currentDate: Date?
    public var includeTime: Bool = false
    public var repeatType: BehaviorRelay<DateAndTimeType.RepeatMode>  = BehaviorRelay(value: .none)
    
    private let monthLabel: UILabel = UILabel().font(UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)).textAlignment(.center).textColor(InterfaceTheme.Color.descriptive)
    
    public override func viewDidLoad() {
        let lastMonthButton = UIButton().title("←", for: .normal).titleColor(InterfaceTheme.Color.interactive, for: .normal)
        lastMonthButton.rx.tap.subscribe(onNext: {
            self.calendarView.goToPreviousMonth()
        }).disposed(by: disposeBag)
        let nextMonthButton = UIButton().title("→", for: .normal).titleColor(InterfaceTheme.Color.interactive, for: .normal)
        nextMonthButton.rx.tap.subscribe(onNext: {
            self.calendarView.goToNextMonth()
        }).disposed(by: disposeBag)
        
        let container = UIStackView()
        container.distribution = .fillEqually
        container.addArrangedSubview(lastMonthButton)
        container.addArrangedSubview(monthLabel)
        container.addArrangedSubview(nextMonthButton)
        
        self.view.addSubview(container)
        
        container.sideAnchor(for: [.top, .left, .right], to: self.view, edgeInset: 0)
        container.sizeAnchor(height: 44)
        
        self.view.addSubview(self.calendarView)
        
        container.columnAnchor(view: self.calendarView, space: 0)
        self.calendarView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        
        self.calendarView.delegate = self
        self.calendarView.dataSource = self
        
        CalendarView.Style.cellShape                = .round
        CalendarView.Style.cellColorDefault         = InterfaceTheme.Color.background2
        CalendarView.Style.cellSelectedBorderColor  = InterfaceTheme.Color.spotlight
        CalendarView.Style.cellSelectedColor        = InterfaceTheme.Color.spotlight
        CalendarView.Style.headerTextColor          = InterfaceTheme.Color.descriptive
        CalendarView.Style.cellTextColorDefault     = InterfaceTheme.Color.interactive
        CalendarView.Style.cellTextColorToday       = InterfaceTheme.Color.spotlight
        CalendarView.Style.cellColorToday           = InterfaceTheme.Color.background1
        CalendarView.Style.cellEventColor           = InterfaceTheme.Color.spotlight
        CalendarView.Style.headerTextColor          = InterfaceTheme.Color.background2
        CalendarView.Style.headerHeight = 0
        
        CalendarView.Style.cellTextColorWeekend = InterfaceTheme.Color.descriptive

        self.calendarView.marksWeekends = true
        self.calendarView.multipleSelectionEnable = false
        
        CalendarView.Style.firstWeekday = Locale.current.regionCode == "CN" ? .monday : .sunday
        
        let timeSelectButton = UIButton()
            .titleColor(InterfaceTheme.Color.interactive, for: .normal)
            .border(color: InterfaceTheme.Color.descriptive, width: 0.5)
            .roundConer(radius: 8)
            .title(self.includeTime ? self.currentDate?.timeString ?? "" : L10n.Document.Edit.Date.allDay, for: .normal)
        
        timeSelectButton.rx.tap.subscribe(onNext:  { [weak timeSelectButton] in
            guard let timeSelectButton = timeSelectButton else { return }
            self.showTimePicker(button: timeSelectButton)
        }).disposed(by: self.disposeBag)
        
        let repeatTypeButton = UIButton()
            .titleColor(InterfaceTheme.Color.interactive, for: .normal)
            .border(color: InterfaceTheme.Color.descriptive, width: 0.5)
            .roundConer(radius: 8)
        
        repeatTypeButton.rx.tap.subscribe(onNext:  { [weak repeatTypeButton] in
            guard let repeatTypeButton = repeatTypeButton else { return }
            self.showRepeatTypePicker(button: repeatTypeButton)
        }).disposed(by: self.disposeBag)
        
        let buttonsContainer = UIStackView()
        buttonsContainer.distribution = .fillEqually
        buttonsContainer.spacing = 10
        buttonsContainer.addArrangedSubview(timeSelectButton)
        buttonsContainer.addArrangedSubview(repeatTypeButton)
        
        self.view.addSubview(buttonsContainer)
        self.calendarView.columnAnchor(view: buttonsContainer, space: 0)
        buttonsContainer.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: Layout.edgeInsets.left)
        buttonsContainer.sizeAnchor(height: 44)
        
        repeatType.subscribe(onNext: { type in
            repeatTypeButton.setTitle(type.content, for: .normal)
        }).disposed(by: self.disposeBag)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.calendarView.setDisplayDate(self.currentDate ?? Date())

        if let selected = self.currentDate {
            self.calendarView.selectDate(selected)
        }
    }
    
    
    private func showTimePicker(button: UIButton) {
        let timeAction = ActionsViewController()
        let timePicker = UIDatePicker()
        if #available(iOS 13.4, *) {
            timePicker.preferredDatePickerStyle = .wheels
        }
        
        timePicker.tintColor = InterfaceTheme.Color.interactive
        
        timePicker.rx.date.skip(1).subscribe(onNext: { date in
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            button.setTitle(date.timeString, for: .normal)
            self.delegate?.didSelectTime((hour: components.hour ?? 0,
                                          minute: components.minute ?? 0,
                                          second: components.second ?? 0))
        }).disposed(by: self.disposeBag)
        timePicker.datePickerMode = .time
        timePicker.sizeAnchor(height: 300)
        timePicker.setValue(InterfaceTheme.Color.interactive, forKey: "textColor");

        timeAction.accessoryView = timePicker
        timeAction.addActionAutoDismiss(icon: nil, title: L10n.Document.Edit.Date.allDay) {
            button.setTitle(L10n.Document.Edit.Date.allDay, for: .normal)
            self.delegate?.didSelectTime(nil)
        }
        
        timeAction.present(from: self, at: button)
    }
    
    private func showRepeatTypePicker(button: UIButton) {
        let actionsController = ActionsViewController()
        
        let textView = UITextField()
        let number = UIStepper()
        let repeatTypeLabel = UILabel().textColor(InterfaceTheme.Color.interactive)
        
        _ = self.repeatType.take(until: actionsController.rx.deallocated).subscribe(onNext: { type in
            switch type {
            
            case .none:
                textView.text = ""
                repeatTypeLabel.text = ""
            case .day(let value):
                textView.text = "\(value)"
                repeatTypeLabel.text = L10n.Document.DateAndTime.Repeat.daily
            case .week(let value):
                textView.text = "\(value)"
                repeatTypeLabel.text = L10n.Document.DateAndTime.Repeat.weekly
            case .month(let value):
                textView.text = "\(value)"
                repeatTypeLabel.text = L10n.Document.DateAndTime.Repeat.monthly
            case .quarter(let value):
                textView.text = "\(value)"
                repeatTypeLabel.text = L10n.Document.DateAndTime.Repeat.quarterly
            case .year(let value):
                textView.text = "\(value)"
                repeatTypeLabel.text = L10n.Document.DateAndTime.Repeat.yearly
            }
        })
        
        number.minimumValue = 1
        number.maximumValue = Double.greatestFiniteMagnitude
        number.stepValue = 1
        number.tintColor = InterfaceTheme.Color.interactive
        number.rx.value.skip(1).subscribe(onNext: { newValue in
            switch self.repeatType.value {
            case .none:
                textView.text = self.repeatType.value.title
            default:
                textView.text = "\(Int(newValue))"
            }
            self.repeatType.accept(self.repeatType.value.updatingValue(Int(newValue)))
        }).disposed(by: self.disposeBag)
        
        textView.keyboardType = .numberPad
        textView.textColor = InterfaceTheme.Color.interactive
        textView.tintColor = InterfaceTheme.Color.interactive
        textView.textAlignment = .right
        textView.rx.text.subscribe(onNext: { text in
            number.value = Double(Int(text ?? "1") ?? 0)
        }).disposed(by: self.disposeBag)
        
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.addArrangedSubview(textView)
        stackView.addArrangedSubview(repeatTypeLabel)
        stackView.addArrangedSubview(number)
        
        actionsController.accessoryView = stackView
        
        actionsController.addAction(icon: nil, title: L10n.Document.DateAndTime.Repeat.daily) { _ in
            self.repeatType.accept(DateAndTimeType.RepeatMode.day(Int(number.value)))
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.DateAndTime.Repeat.weekly) { _ in
            self.repeatType.accept(DateAndTimeType.RepeatMode.week(Int(number.value)))
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.DateAndTime.Repeat.monthly) { _ in
            self.repeatType.accept(DateAndTimeType.RepeatMode.month(Int(number.value)))
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.DateAndTime.Repeat.quarterly) { _ in
            self.repeatType.accept(DateAndTimeType.RepeatMode.quarter(Int(number.value)))
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.DateAndTime.Repeat.yearly) { _ in
            self.repeatType.accept(DateAndTimeType.RepeatMode.year(Int(number.value)))
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.DateAndTime.Repeat.none) { _ in
            self.repeatType.accept(DateAndTimeType.RepeatMode.none)
        }
        
        actionsController.present(from: self, at: button)
    }
    
    private func updateRepeatType(_ repeatType: DateAndTimeType.RepeatMode) {
        
    }
}

extension DateSelectViewController: CalendarViewDelegate {
    public func calendar(_ calendar: CalendarView, didScrollToMonth date: Date) {
        self.monthLabel.text = date.monthStringLong
    }
    
    public func calendar(_ calendar: CalendarView, didSelectDate date: Date, withEvents events: [CalendarEvent]) {
        self.delegate?.didSelect(date: date)
        self.currentDate = date
        self.monthLabel.text = date.monthStringLong
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
        let threeMonthsAgo = self.calendarView.calendar.date(byAdding: dateComponents, to: today)
        return threeMonthsAgo!
    }
    
    public func endDate() -> Date {
        var dateComponents = DateComponents()
        dateComponents.month = 3
        let today = Date()
        let threeMonthsAgo = self.calendarView.calendar.date(byAdding: dateComponents, to: today)
        return threeMonthsAgo!
    }
}

extension Date {
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        return formatter.string(from: self)
    }
}
