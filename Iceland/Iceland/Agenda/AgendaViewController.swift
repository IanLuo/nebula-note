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

public class AgendaViewController: UIViewController {
    private let viewModel: AgendaViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AgendaTableCell.self, forCellReuseIdentifier: AgendaTableCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 120, bottom: 0, right: 30)
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
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        self.viewModel.loadAllData()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isMovingToParent {
            self.besideDatesView.moveToToday(animated: false)
        }
    }
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.besideDatesView)
        self.view.addSubview(self.dateView)
        
        self.besideDatesView.sideAnchor(for: [.top, .left, .right], to: self.view, edgeInsets: .init(top: 80, left: 0, bottom: 0, right: 0))
        self.besideDatesView.sizeAnchor(height: 120)
        
        self.besideDatesView.columnAnchor(view: self.dateView)
        
        self.dateView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.dateView.sizeAnchor(height: 80)
        
        self.tableView.contentInset = UIEdgeInsets(top: 280, left: 0, bottom: 0, right: 0)
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
        
        let actionsViewController = ActionsViewController()
        
        actionsViewController.addAction(icon: nil, title: "Reschedule") { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        actionsViewController.addAction(icon: nil, title: "Delay") { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        actionsViewController.addAction(icon: nil, title: "Change Status") { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        actionsViewController.addAction(icon: nil, title: "Open", style: ActionsViewController.Style.highlight) { viewController in
            viewController.dismiss(animated: true, completion: nil)
            let data = self.viewModel.data[indexPath.row]
            self.viewModel.coordinator?.openDocument(url: data.url, location: data.heading.range.location)
        }
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.present(actionsViewController, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    /// 当向上滚动时，同时滚动日期选择和日期显示 view，往下则不动
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.contentInset.top > 0 {
            self.besideDatesView.constraint(for: Position.top)?.constant = 80 - scrollView.contentOffset.y  - scrollView.contentInset.top
            self.view.layoutIfNeeded()
        } else {
            self.besideDatesView.constraint(for: Position.top)?.constant = 80
            self.view.layoutIfNeeded()
        }
    }
}

extension AgendaViewController: AgendaViewModelDelegate {
    public func didCompleteLoadAllData() {
        self.viewModel.load(date: self.besideDatesView.currentDate)
        self.tableView.reloadData()
    }
    
    public func didLoadData() {
        self.tableView.reloadData()
    }
    
    public func didFailed(_ error: Error) {
        log.error(error)
    }
}

private class DateView: UIView {
    private let weekdayLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.title
        label.textAlignment = .center
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.subTitle
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
        self.weekdayLabel.sizeAnchor(width: 120)
        
        self.dateLabel.sideAnchor(for: [.left, .right],
                                  to: self,
                                  edgeInsets: .init(top: 0, left: 120, bottom: -20, right: 0))
        
        self.weekdayLabel.lastBaselineAnchor.constraint(equalTo: self.dateLabel.lastBaselineAnchor).isActive = true
        
        self.setBorder(position: .bottom, color: InterfaceTheme.Color.background3, width: 0.5)
    }
}
