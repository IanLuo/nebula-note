//
//  CatpureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class CaptureListViewController: UIViewController {
    let viewModel: CaptureListViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CaptureTableCell.self, forCellReuseIdentifier: CaptureTableCell.reuseIdentifier)
        return tableView
    }()
    
    public init(viewModel: CaptureListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
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
            self.viewModel.chooseRefileLocation(index: index)
        }
    }
}

extension CaptureListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cellModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CaptureTableCell.reuseIdentifier, for: indexPath) as! CaptureTableCell
        cell.cellModel = self.viewModel.cellModels[indexPath.row]
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.viewModel.cellModels[indexPath.row].attachmentView.size(for: tableView.bounds.width - 60).height
    }
}

extension CaptureListViewController: UITableViewDelegate {
    // nothing to do yet
}

extension CaptureListViewController: CaptureListViewModelDelegate {
    public func didStartRefile(at index: Int) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.showProcessingAnimation()
        }
    }
    
    public func didDeleteCapture(index: Int) {
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
    }
    
    public func didFail(error: Error) {
        
    }
        
    public func didCompleteRefile(index: Int) {
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? CaptureTableCell {
            cell.hideProcessingAnimation()
        }
        
        self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .right)
    }
    
    public func didLoadData() {
        self.tableView.reloadData()
    }
}
