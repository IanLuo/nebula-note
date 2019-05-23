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
    func didDelete(viewController: DateAndTimeSelectViewController)
}

public class DateAndTimeSelectViewController: TransitionViewController {
    public var contentView: UIView {
        return self._contentView
    }
    
    public var fromView: UIView?
    
    public var didSelectAction:((DateAndTimeType) -> Void)?
    public var didCancelAction:(() -> Void)?
    public var didDeleteAction:(() -> Void)?
    
    public weak var delegate: DateAndTimeSelectViewControllerDelegate?
    
    @IBOutlet var _closeButton: UIButton!
    @IBOutlet var _calendarContainer: UIView!
    @IBOutlet var _timeContainer: UIView!
    @IBOutlet var _saveButton: UIButton!
    @IBOutlet var _deleteButton: UIButton!
    @IBOutlet var _cancelButton: UIButton!
    @IBOutlet var _titleLabel: UILabel!
    
    private var _selectedDate: Date?
    private var _selectTime: (Int, Int, Int)?
    private var _isEnabledSelectTime: Bool = false
    @IBOutlet var _contentView: UIView!
    
    private let _dateSelectViewController: DateSelectViewController = DateSelectViewController()
    private let _timeSelectViewController: TimeSelectViewController = TimeSelectViewController()
    
    private let _transitionDelegate: FadeBackgroundTransition = FadeBackgroundTransition(animator: MoveInAnimtor())
    
    public var dateAndTime: DateAndTimeType? {
        didSet {
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
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.transitioningDelegate = self._transitionDelegate
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        self._initValues()
        self._setupUI()
        self._loadSubViewControllers()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(_cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    private func _initValues() {
        self._dateSelectViewController.currentDate = self._selectedDate ?? Date()
        
        if let time = self._selectTime {
            self._timeSelectViewController.time = time
        }
        
        self._titleLabel.text = self.title
    }
    
    private func _loadSubViewControllers() {
        self.addChild(self._dateSelectViewController)
        self._dateSelectViewController.delegate = self
        self._dateSelectViewController.didMove(toParent: self)
        
        self.addChild(self._timeSelectViewController)
        self._timeSelectViewController.delegate = self
        self._timeSelectViewController.didMove(toParent: self)
    }
    
    private func _setupUI() {
        self.interface { [weak self] (me, theme) in
            self?._contentView.backgroundColor = theme.color.background2
            self?._titleLabel.textColor = theme.color.descriptive
            self?._titleLabel.font = theme.font.title
            self?._saveButton.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            self?._saveButton.tintColor = theme.color.spotlight
            self?._deleteButton.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            self?._deleteButton.tintColor = theme.color.warning
            self?._cancelButton.tintColor = theme.color.interactive
            self?._cancelButton.setImage(Asset.Assets.cross.image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
        self._calendarContainer.addSubview(self._dateSelectViewController.view)
        self._dateSelectViewController.view.allSidesAnchors(to: self._calendarContainer, edgeInset: 0)
        
        self._timeContainer.addSubview(self._timeSelectViewController.view)
        self._timeSelectViewController.view.allSidesAnchors(to: self._timeContainer, edgeInset: 0)
        
        self._saveButton.setTitle(L10n.General.Button.Title.save, for: .normal)
        self._deleteButton.setTitle(L10n.General.Button.Title.delete, for: .normal)
        
        self._timeSelectViewController.switch.isOn = self._selectTime == nil
    }
    
    @IBAction private func _save() {
        
        guard let selectedDate = self._selectedDate else { return }

        let calendar = Calendar.current
        var dateComponents: DateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        dateComponents.calendar = calendar
        
        if let time = self._selectTime {
            dateComponents.setValue(time.0, for: Calendar.Component.hour)
            dateComponents.setValue(time.1, for: Calendar.Component.minute)
            dateComponents.setValue(time.2, for: Calendar.Component.second)
            
            let dateAndTime = DateAndTimeType(date: dateComponents.date!,
                                              includeTime: self._isEnabledSelectTime)
            self.delegate?.didSelect(dateAndTime: dateAndTime,
                                     viewController: self)
            self.didSelectAction?(dateAndTime)
        } else {
            let dateAndTime = DateAndTimeType(date: selectedDate,
                                              includeTime: self._isEnabledSelectTime)
            self.delegate?.didSelect(dateAndTime: dateAndTime,
                                     viewController: self)
            self.didSelectAction?(dateAndTime)
        }
    }
    
    @IBAction func _delete() {
        self.delegate?.didDelete(viewController: self)
        self.didDeleteAction?()
    }


    @IBAction private func _cancel() {
        self.delegate?.didCancel(viewController: self)
        self.didCancelAction?()
    }
    
}

extension DateAndTimeSelectViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
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
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    public func didSelectTime(hour: Int, minute: Int, second: Int) {
        self._selectTime = (hour, minute, second)
    }
}
