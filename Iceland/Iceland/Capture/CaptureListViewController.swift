//
//  CatpureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class CaptureListViewController: UIViewController {
    let viewModel: CaptureListViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CaptureTableCell.self, forCellReuseIdentifier: "CaptureTableCell")
        return tableView
    }()
    
    public init(viewModel: CaptureListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension CaptureListViewController: CaptureTableCellDelegate {
    public func didTapDelete(cell: CaptureTableCell) {
        if let index = self.tableView.indexPath(for: cell)?.row {
            self.viewModel.delete(index: index)
        }
    }
    
    public func didTapRefile(cell: CaptureTableCell) {
        if let index = self.tableView.indexPath(for: cell)?.row {
            self.viewModel.prepareForRefile(index: index)
        }
    }
}

extension CaptureListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CaptureTableCell", for: indexPath) as! CaptureTableCell
        cell.attachment = self.viewModel.data[indexPath.row]
        return cell
    }
}

extension CaptureListViewController: UITableViewDelegate {

}

extension CaptureListViewController: CaptureListViewModelDelegate {
    public func didDeleteCapture(index: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
    }
    
    public func didFail(error: Error) {
        
    }
    
    public func didFailToLoadCaptureList(error: Error) {
        
    }
    
    public func didRefileAttachment(index: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .right)
    }
    
    public func didLoadData() {
        self.tableView.reloadData()
    }
}
