//
//  FilteredItemsViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/2/3.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public class FilteredItemsViewController: UIViewController {
    let viewModel: AgendaViewModel
    
    public init(viewModel: AgendaViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
        
        viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FilteredItemTableCell.self, forCellReuseIdentifier: FilteredItemTableCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: Layout.edgeInsets.top, left: 0, bottom: 0, right: 0)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: Layout.edgeInsets.right)
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.backgroundColor = InterfaceTheme.Color.background1
        return tableView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = InterfaceTheme.Color.background1
        self.view.addSubview(self.tableView)
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self.viewModel.loadFiltered()
    }
}

extension FilteredItemsViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FilteredItemTableCell.reuseIdentifier, for: indexPath) as! FilteredItemTableCell
        cell.cellModel = self.viewModel.data[indexPath.row]
        return cell
    }
}

extension FilteredItemsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = self.viewModel.data[indexPath.row]
        self.viewModel.coordinator?.openDocument(url: cellModel.url, location: cellModel.heading.rawHeadingToken.range.location)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension FilteredItemsViewController: AgendaViewModelDelegate {
    public func didCompleteLoadAllData() {
        self.tableView.reloadData()
    }
    
    public func didLoadData() {
        self.tableView.reloadData()
    }
    
    public func didFailed(_ error: Error) {
        log.error(error)
    }
}
