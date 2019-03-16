//
//  DateAndTimeSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/3/16.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface
import Business
import UIKit

public protocol DateAndTimeSelectViewControllerDelegate: class {
    func didSelect(dateAndTime: DateAndTimeType, viewController: DateAndTimeSelectViewController)
    func didCancel(viewController: DateAndTimeSelectViewController)
}

public class DateAndTimeSelectViewController: UIViewController {
    
    public weak var delegate: DateAndTimeSelectViewControllerDelegate?
    
    private var _selectedDate: Date?
    private var _selectTime: (Int, Int, Int)?
    private var _isEnabledSelectTime: Bool = false
    
    private let _dateSelectViewController: DateSelectViewController = DateSelectViewController()
    private let _timeSelectViewController: TimeSelectViewController = TimeSelectViewController()
    
    public init(dateAndTime: DateAndTimeType?) {
        super.init(nibName: nil, bundle: nil)
        
        if let dateAndTime = dateAndTime {
            self._selectedDate = dateAndTime.date
            
            if dateAndTime.includeTime {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute, .second], from: dateAndTime.date)
                if let hour = components.hour, let minute = components.minute, let second = components.second {
                    self._selectTime = (hour, minute, second)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        self.addChild(self._dateSelectViewController)
        self._dateSelectViewController.didMove(toParent: self)
        
        self.addChild(self._timeSelectViewController)
        self._timeSelectViewController.didMove(toParent: self)
        
        self.view.addSubview(self._dateSelectViewController.view)
        self.view.addSubview(self._timeSelectViewController.view)
        
        if let selectedDate = self._selectedDate {
            self._dateSelectViewController.selectedDates = [selectedDate]
        }
        
        if let time = self._selectTime {
            self._timeSelectViewController.hour = time.0
            self._timeSelectViewController.minute = time.1
            self._timeSelectViewController.second = time.2
        }
    }
    
    @objc private func _save() {
        
        guard let selectedDate = self._selectedDate else { return }

        let calendar = Calendar.current
        var dateComponents: DateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        if let time = self._selectTime {
            dateComponents.setValue(time.0, for: Calendar.Component.hour)
            dateComponents.setValue(time.1, for: Calendar.Component.minute)
            dateComponents.setValue(time.2, for: Calendar.Component.second)
            
            self.delegate?.didSelect(dateAndTime: DateAndTimeType(date: dateComponents.date!,
                                                                  includeTime: true),
                                     viewController: self)
        } else {
            self.delegate?.didSelect(dateAndTime: DateAndTimeType(date: dateComponents.date!,
                                                                  includeTime: false),
                                     viewController: self)
        }
    }
    
    @objc private func _cancel() {
        self.delegate?.didCancel(viewController: self)
    }
}

extension DateAndTimeSelectViewController: DateSelectViewControllerDelegate {
    public func didSelect(date: Date) {
        self._selectedDate = date
    }
}

extension DateAndTimeSelectViewController: TimeSelectViewControllerDelegate {
    public func didEnableSelectTime(_ enabled: Bool) {
        self._isEnabledSelectTime = enabled
    }
    
    public func didSelectTime(hour: Int, minute: Int, second: Int) {
        self._selectTime = (hour, minute, second)
    }
}
