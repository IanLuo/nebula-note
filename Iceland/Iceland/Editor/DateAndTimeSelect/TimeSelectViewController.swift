//
//  TimeSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/3/16.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public protocol TimeSelectViewControllerDelegate: class {
    func didSelectTime(hour: Int, minute: Int, second: Int)
    func didEnableSelectTime(_ enabled: Bool)
}

public class TimeSelectViewController: UIViewController {
    
    public weak var delegate: TimeSelectViewControllerDelegate?

    public var time: (Int, Int, Int)?
    
    @IBOutlet var _timePickerContainer: UIView!
    @IBOutlet var _allDayLabel: UILabel!
    @IBOutlet var _datePicker: UIDatePicker!
    
    public override func viewDidLoad() {
        self.view.backgroundColor = InterfaceTheme.Color.background2
        
        self._allDayLabel.textColor = InterfaceTheme.Color.interactive
        self._allDayLabel.font = InterfaceTheme.Font.body
        
        self._timePickerContainer.sizeAnchor(height: 0)
        self._timePickerContainer.backgroundColor = InterfaceTheme.Color.background2
        
        self._enableTimeView(self.time == nil)
        
        self._datePicker.datePickerMode = .time
        self._datePicker.setValue(InterfaceTheme.Color.interactive, forKey: "textColor")
    }
    
    @IBAction func _enableTime(_ sender: UISwitch) {
        self._enableTimeView(sender.isOn)
    }
    
    private func _enableTimeView(_ enabled: Bool) {
        self._timePickerContainer.constraint(for: .height)?.constant = enabled ? 0 : 120
        self._timePickerContainer.isHidden = enabled
        self.delegate?.didEnableSelectTime(!enabled)
        
        if enabled {
            self._allDayLabel.text = L10n.Document.Edit.Date.allDay
        } else {
            self._allDayLabel.text = self._datePicker.date.timeString
            self._updateTime(datePicker: self._datePicker)
        }
    }
    
    @IBAction func timeValueChanged(datePicker: UIDatePicker) {
        self._updateTime(datePicker: datePicker)
    }
    
    private func _updateTime(datePicker: UIDatePicker) {
        let components = datePicker.calendar.dateComponents([.hour, .minute, .second], from: datePicker.date)
        
        self.delegate?.didSelectTime(hour: components.hour!, minute: components.minute!, second: components.second!)
        
        self._allDayLabel.text = datePicker.date.timeString
    }
}

extension Date {
    internal var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        return formatter.string(from: self)
    }
}
