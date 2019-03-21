//
//  AgendaViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public class AgendaViewController: UIViewController {
    public struct Constants {
        static let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: Layout.edgeInsets.top, left: 120, bottom: Layout.edgeInsets.bottom, right: Layout.edgeInsets.right)
        static let besideDateBarHeight: CGFloat = edgeInsets.left
        static let dateLabelHeight: CGFloat = DateView.Constants.height
    }
    
    private let viewModel: AgendaViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AgendaTableCell.self, forCellReuseIdentifier: AgendaTableCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.edgeInsets.left, bottom: 0, right: Constants.edgeInsets.right)
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.backgroundColor = InterfaceTheme.Color.background1
        return tableView
    }()
    
    private lazy var besideDatesView: BesideDatesView = {
        let besideDatesView = BesideDatesView()
        besideDatesView.delegate = self
        return besideDatesView
    }()
    
    private lazy var dateView: DateView = {
        let dateView = DateView()
        return dateView
    }()
    
    public init(viewModel: AgendaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        viewModel.delegate = self
        
        self.title = "Agenda".localizable
        self.tabBarItem = UITabBarItem(title: "Agenda".localizable, image: Asset.Assets.agenda.image, tag: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        self.viewModel.loadData()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isMovingToParent {
            self.besideDatesView.moveToToday(animated: false)
        }
        
        self.viewModel.loadData()
        self.viewModel.isConnectingScreen = true
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.isConnectingScreen = false
    }
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.besideDatesView)
        self.view.addSubview(self.dateView)
        
        self.besideDatesView.sideAnchor(for: [.top, .left, .right],
                                        to: self.view,
                                        edgeInsets: .init(top: Constants.edgeInsets.top, left: 0, bottom: 0, right: 0),
                                        considerSafeArea: true)
        self.besideDatesView.sizeAnchor(height: Constants.besideDateBarHeight)
        
        self.besideDatesView.columnAnchor(view: self.dateView)
        
        self.dateView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.dateView.sizeAnchor(height: Constants.dateLabelHeight)
        
        self.tableView.contentInset = UIEdgeInsets(top: Constants.edgeInsets.top + Constants.besideDateBarHeight + Constants.dateLabelHeight,
                                                   left: 0, bottom: 0, right: 0)
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
    }
    
    @objc private func cancel() {
        self.viewModel.coordinator?.stop()
    }
}

extension AgendaViewController: BesideDatesViewDelegate {
    public func didSelectDate(date: Date) {
        self.viewModel.load(date: date)
        self.dateView.date = date
        self.tableView.reloadData()
    }
}

extension AgendaViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AgendaTableCell.reuseIdentifier, for: indexPath) as! AgendaTableCell
        cell.cellModel = self.viewModel.data[indexPath.row]
        return cell
    }
}

extension AgendaViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let heading = self.viewModel.data[indexPath.row]
        
        let actionsViewController = ActionsViewController()
        
        actionsViewController.title = L10n.Agenda.Actions.title
        
        actionsViewController.addAction(icon: nil, title: L10n.Agenda.Actions.schedule) { viewController in
            self.viewModel.coordinator?.dismisTempModal(viewController, completion: {
                
                self.viewModel.coordinator?.showDateSelector(title: L10n.Agenda.Actions.schedule, current: heading.schedule, add: { [unowned self] dateAndTime in
                    
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                    self.viewModel.updateSchedule(index: indexPath.row, dateAndTime)
                }, delete: { [unowned self] in
                    
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                    self.viewModel.updateSchedule(index: indexPath.row, nil)
                }, cancel: {
                    tableView.deselectRow(at: indexPath, animated: true)
                })
            })
        }
        
        actionsViewController.addAction(icon: nil, title: L10n.Agenda.Actions.due) { viewController in
            self.viewModel.coordinator?.dismisTempModal(viewController, completion: {
               
                self.viewModel.coordinator?.showDateSelector(title: L10n.Agenda.Actions.due, current: heading.due, add: { [unowned self] dateAndTime in
                    
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    
                    tableView.deselectRow(at: indexPath, animated: true)
                    self.viewModel.updateDue(index: indexPath.row, dateAndTime)
                }, delete: { [unowned self] in
                    
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    
                   tableView.deselectRow(at: indexPath, animated: true)
                    self.viewModel.updateDue(index: indexPath.row, nil)
                }, cancel: {
                    tableView.deselectRow(at: indexPath, animated: true)
                })
            })
        }
        
        actionsViewController.addAction(icon: nil, title: L10n.Agenda.Actions.changeStatus) { viewController in
            self.viewModel.coordinator?.dismisTempModal(viewController, completion: { [unowned self] in
                
                let selectorViewController = SelectorViewController()
                let allPlannings = self.viewModel.coordinator?.dependency.settingAccessor.allPlannings ?? []
                for title in allPlannings {
                    selectorViewController.addItem(title: title)
                }
                
                selectorViewController.currentTitle = heading.planning
                
                selectorViewController.onSelection = { index in
                    self.viewModel.coordinator?.dismisTempModal(selectorViewController) { [unowned self] in
                        
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                        
                        self.viewModel.updatePlanning(index: indexPath.row, allPlannings[index])
                        
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
                
                selectorViewController.onCancel = {
                    self.viewModel.coordinator?.dismisTempModal(selectorViewController) { [unowned self] in
                        
                        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                        
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
                
                self.viewModel.coordinator?.showTempModal(selectorViewController)
            })
        }
        
        actionsViewController.addAction(icon: Asset.Assets.up.image, title: L10n.General.Button.Title.open, style: ActionsViewController.Style.highlight) { viewController in
            self.viewModel.coordinator?.dismisTempModal(viewController, completion: { [unowned self] in
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                tableView.deselectRow(at: indexPath, animated: true)
                let data = self.viewModel.data[indexPath.row]
                self.viewModel.coordinator?.openDocument(url: data.url, location: data.heading.location)
            })
        }
        
        actionsViewController.setCancel { viewController in
            self.viewModel.coordinator?.dismisTempModal(viewController, completion: { [unowned self] in
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                tableView.deselectRow(at: indexPath, animated: true)
            })
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            self.viewModel.coordinator?.showTempModal(actionsViewController)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
        }
    }
    
    /// 当向上滚动时，同时滚动日期选择和日期显示 view，往下则不动
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.contentInset.top + Constants.dateLabelHeight > 0 {
            self.besideDatesView.constraint(for: Position.top)?.constant = Constants.edgeInsets.top - scrollView.contentOffset.y  - scrollView.contentInset.top - Constants.dateLabelHeight
            self.view.layoutIfNeeded()
        } else {
            self.besideDatesView.constraint(for: Position.top)?.constant = Constants.edgeInsets.top
            self.view.layoutIfNeeded()
        }
    }
}

extension AgendaViewController: AgendaViewModelDelegate {
    public func didCompleteLoadAllData() {
        self.viewModel.load(date: self.besideDatesView.currentDate)
    }
    
    public func didLoadData() {
        self.tableView.reloadData()
    }
    
    public func didFailed(_ error: Error) {
        log.error(error)
    }
}

private class DateView: UIView {
    public struct Constants {
        static let height: CGFloat = 80
    }
    
    private let weekdayLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptiveHighlighted
        label.font = InterfaceTheme.Font.title
        label.textAlignment = .center
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptiveHighlighted
        label.font = InterfaceTheme.Font.subtitle
        label.textAlignment = .left
        return label
    }()
    
    public init() {
        super.init(frame: .zero)
        
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var date: Date? {
        didSet {
            guard let date = date else { return }
            
            self.dateLabel.text = "\(date.day), \(date.monthStringLong),  \(date.weekOfYearString), \(date.year)"
            self.weekdayLabel.text = date.weekDayString
        }
    }
    
    private func setupUI() {
        self.addSubview(self.dateLabel)
        self.addSubview(self.weekdayLabel)
        
        self.weekdayLabel.sideAnchor(for: [.left, .bottom],
                                     to: self,
                                     edgeInsets: .init(top: 0, left: 0, bottom: -20, right: 0))
        self.weekdayLabel.sizeAnchor(width: AgendaViewController.Constants.edgeInsets.left)
        
        self.dateLabel.sideAnchor(for: [.left, .right],
                                  to: self,
                                  edgeInsets: .init(top: 0, left: AgendaViewController.Constants.edgeInsets.left, bottom: -20, right: 0))
        
        self.weekdayLabel.lastBaselineAnchor.constraint(equalTo: self.dateLabel.lastBaselineAnchor).isActive = true
        
        self.setBorder(position: .bottom, color: InterfaceTheme.Color.background3, width: 0.5)
    }
}
