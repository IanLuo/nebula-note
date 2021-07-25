//
//  FilteredItemsViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/2/3.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import RxSwift

public class FilteredItemsViewController: UIViewController {
    var data: [AgendaCellModel] = []
    let onDocumentSelected: PublishSubject<(url: URL, location: Int)> = PublishSubject()
    
    public init(data: [AgendaCellModel]) {
        self.data = data
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let disposeBag = DisposeBag()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AgendaTableCell.self, forCellReuseIdentifier: AgendaTableCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.contentInset = UIEdgeInsets(top: Layout.edgeInsets.top, left: 0, bottom: 0, right: 0)
        tableView.separatorStyle = .none
        tableView.backgroundColor = InterfaceTheme.Color.background1
        return tableView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = InterfaceTheme.Color.background1
        self.view.addSubview(self.tableView)
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = cancelItem
            
        cancelItem.rx.tap.subscribe(onNext: { [weak self] in
            self?.dismiss(animated: true)
        }).disposed(by: self.disposeBag)
    }
}

extension FilteredItemsViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AgendaTableCell.reuseIdentifier, for: indexPath) as! AgendaTableCell
        cell.cellModel = self.data[indexPath.row]
        return cell
    }
}

extension FilteredItemsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = self.data[indexPath.row]
        
        if let dataAndTimeRange = cellModel.dateAndTimeRange {
            self.onDocumentSelected.onNext((url: cellModel.url, location: dataAndTimeRange.upperBound))
        } else {
            self.onDocumentSelected.onNext((url: cellModel.url, location: cellModel.heading.range.upperBound))
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
