//
//  DateAndTimeSelectViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/3/16.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface
import Core
import UIKit
import RxSwift

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
    
    private let disposeBag = DisposeBag()
    
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
    private var repeatType: DateAndTimeType.RepeatMode = .none
    
    @IBOutlet var _contentView: UIScrollView!
    
    private let _dateSelectViewController: DateSelectViewController = DateSelectViewController()
    
    private lazy var _transitionDelegate: FadeBackgroundTransition = {
        return FadeBackgroundTransition(animator: MoveToAnimtor())
    }()
    
    public var passInDateAndTime: DateAndTimeType? {
        didSet {
            if let dateAndTime = passInDateAndTime {
                self._selectedDate = dateAndTime.date
                self.repeatType = dateAndTime.repeateMode
                self._isEnabledSelectTime = dateAndTime.includeTime
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
        
        if isMacOrPad {
            self.modalPresentationStyle = UIModalPresentationStyle.popover
        } else {
            self.modalPresentationStyle = .custom
            self.transitioningDelegate = self._transitionDelegate
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let viewHeight = self.view.bounds.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom
        self._contentView.frame = CGRect(x: (self.view.bounds.width - self._contentView.contentSize.width) / 2,
                                         y: max(0, viewHeight - self._contentView.contentSize.height) + self.view.safeAreaInsets.top,
                                         width: self._contentView.contentSize.width,
                                         height: min(self._contentView.contentSize.height, viewHeight))
    }
    
    public override func viewDidLoad() {
        self._initValues()
        self._setupUI()
        self._loadSubViewControllers()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(_cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.view.layoutIfNeeded()
        
        self._dateSelectViewController.repeatType.subscribe(onNext: { type in
            self.repeatType = type
        }).disposed(by: self.disposeBag)
        
        if isMacOrPad {
            self._closeButton.isHidden = true
            if self.fromView == nil {
                self.popoverPresentationController?.sourceView = self.view
                self.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 0, height: 0)
            }
            self.preferredContentSize = self._contentView.contentSize
        }
    }
    
    private func _initValues() {
        self._dateSelectViewController.currentDate = self._selectedDate ?? Date()
        self._dateSelectViewController.includeTime = _isEnabledSelectTime
        self._dateSelectViewController.repeatType.accept(self.repeatType)
        self._titleLabel.text = self.title
    }
    
    private func _loadSubViewControllers() {
        self.addChild(self._dateSelectViewController)
        self._dateSelectViewController.delegate = self
        self._dateSelectViewController.didMove(toParent: self)
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
            self?._cancelButton.setImage(Asset.SFSymbols.xmark.image.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
        self.view.backgroundColor = .clear
        
        self._calendarContainer.addSubview(self._dateSelectViewController.view)
        self._dateSelectViewController.view.allSidesAnchors(to: self._calendarContainer, edgeInset: 0)
        
        self._saveButton.setTitle(L10n.General.Button.Title.save, for: .normal)
        self._deleteButton.setTitle(L10n.General.Button.Title.delete, for: .normal)
        
        // hide time selector for now for Mac
        if isMac {
            self._timeContainer.isHidden = true
        }
        
        self._contentView.roundConer(radius: 10)
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
            
            dateAndTime.isDue = self.passInDateAndTime?.isDue ?? false
            dateAndTime.isSchedule = self.passInDateAndTime?.isSchedule ?? false
            dateAndTime.repeateMode = self.repeatType
            
            self.delegate?.didSelect(dateAndTime: dateAndTime,
                                     viewController: self)
            self.didSelectAction?(dateAndTime)
        } else {
            let dateAndTime = DateAndTimeType(date: selectedDate,
                                              includeTime: self._isEnabledSelectTime)
            dateAndTime.isDue = self.passInDateAndTime?.isDue ?? false
            dateAndTime.isSchedule = self.passInDateAndTime?.isSchedule ?? false
            dateAndTime.repeateMode = self.repeatType
            
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
    public func didSelectRepeatType(_ type: DateAndTimeType.RepeatMode) {
        self.repeatType = type
    }
    
    public func didSelectTime(_ time: (hour: Int, minute: Int, second: Int)?) {
        self._selectTime = time
        self._isEnabledSelectTime = time != nil
    }
    public func didSelect(date: Date) {
        self._selectedDate = date
    }
}
