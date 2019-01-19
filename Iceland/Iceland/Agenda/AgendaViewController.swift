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
        tableView.contentInset = UIEdgeInsets(top: self.view.bounds.height / 4, left: 0, bottom: 0, right: 0)
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
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("✕".localizable, for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint),
                                  for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    public init(viewModel: AgendaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        self.besideDatesView.moveToToday(animated: false)
    }
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        self.view.addSubview(self.besideDatesView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.dateView)
        self.view.addSubview(self.cancelButton)
        
        self.cancelButton.sideAnchor(for: [.right, .top], to: self.view, edgeInset: 0)
        self.cancelButton.sizeAnchor(width: 80, height: 80)
        
        self.cancelButton.columnAnchor(view: self.besideDatesView)

        self.besideDatesView.sideAnchor(for: [.top, .left, .right], to: self.view, edgeInsets: .init(top: 80, left: 0, bottom: 0, right: 0))
        self.besideDatesView.sizeAnchor(height: 120)
        
        self.besideDatesView.columnAnchor(view: self.dateView, space: 30)
        
        self.dateView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.dateView.sizeAnchor(height: 80)
        
        self.dateView.columnAnchor(view: self.tableView, space: 30)
        
        self.tableView.sideAnchor(for: [.left, .bottom, .right], to: self.view, edgeInset: 0)
    }
    
    @objc private func cancel() {
        self.viewModel.dependency?.stop()
    }
}

extension AgendaViewController: BesideDatesViewDelegate {
    public func didSelectDate(date: Date) {
        self.viewModel.load(date: date)
        self.dateView.date = date
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
        self.viewModel.showActions(index: indexPath.row)
    }
}

extension AgendaViewController: AgendaViewModelDelegate {
    public func didLoadData() {
        self.tableView.reloadData()
    }
    
    public func didFailed(_ error: Error) {
        
    }
}

private class DateView: UIView {
    private let weekdayLabel: UILabel = {
        let label = UILabel()
        label.textColor = InterfaceTheme.Color.descriptive
        label.font = InterfaceTheme.Font.largeTitle
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
            self.weekdayLabel.text = date.weekDayShortString
        }
    }
    
    private func setupUI() {
        self.addSubview(self.dateLabel)
        self.addSubview(self.weekdayLabel)
        
        self.weekdayLabel.sideAnchor(for: [.left, .bottom],
                                     to: self,
                                     edgeInset: 0)
        self.weekdayLabel.sizeAnchor(width: 120)
        
        self.dateLabel.sideAnchor(for: [.left, .right],
                                  to: self,
                                  edgeInsets: .init(top: 0, left: 120, bottom: 0, right: 0))
        
        self.weekdayLabel.lastBaselineAnchor.constraint(equalTo: self.dateLabel.lastBaselineAnchor).isActive = true
        
        
    }
}
