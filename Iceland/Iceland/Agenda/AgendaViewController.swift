//
//  AgendaViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class AgendaViewController: UIViewController {
    private let viewModel: AgendaViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AgendaTableCell.self, forCellReuseIdentifier: AgendaTableCell.reuseIdentifier)
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
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI(){
        self.view.addSubview(self.besideDatesView)
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.dateView)
        
        self.besideDatesView.translatesAutoresizingMaskIntoConstraints = false
        self.dateView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.besideDatesView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.besideDatesView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        if #available(iOS 11.0, *) {
            self.besideDatesView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            self.besideDatesView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        }
        
        self.dateView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.dateView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.dateView.topAnchor.constraint(equalTo: self.besideDatesView.bottomAnchor).isActive = true
        
        self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.dateView.bottomAnchor).isActive = true
        if #available(iOS 11.0, *) {
            self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        } else {
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
    }
}

extension AgendaViewController: BesideDatesViewDelegate {
    public func didSelectDate(date: Date) {
        self.viewModel.load(date: date)
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
    var date: Date? {
        didSet {
            self.setupUI()
        }
    }
    
    private func setupUI() {
        // TODO:
    }
}
