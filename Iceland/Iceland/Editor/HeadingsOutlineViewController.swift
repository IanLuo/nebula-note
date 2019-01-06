//
//  HeadingsOutlineViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol HeadingsOutlineViewControllerDelegate: class {
    func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading)
}

public class HeadingsOutlineViewController: UIViewController {
    private let viewModel: DocumentEditViewModel
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HeadingOutlineTableViewCell.self, forCellReuseIdentifier: HeadingOutlineTableViewCell.reuseIdentifier)
        return tableView
    }()
    
    public weak var delegate: HeadingsOutlineViewControllerDelegate?
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
        
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        self.view.addSubview(self.tableView)
        
        self.view.backgroundColor = InterfaceTheme.Color.background2
        self.tableView.backgroundColor = InterfaceTheme.Color.background2
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.allSidesAnchors(to: self.view, edgeInsets: .zero)
    }
}

extension HeadingsOutlineViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectHeading(url: self.viewModel.url, heading: self.viewModel.headings[indexPath.row])
    }
}

extension HeadingsOutlineViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.headings.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HeadingOutlineTableViewCell.reuseIdentifier, for: indexPath) as! HeadingOutlineTableViewCell
        cell.level = self.viewModel.level(index: indexPath.row)
        cell.string = self.viewModel.headingString(index: indexPath.row)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

extension HeadingsOutlineViewController: DocumentEditViewModelDelegate {
    public func didReadToEdit() {
        self.tableView.reloadData()
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func showLink(url: URL) {
        
    }
    
    public func updateHeadingInfo(heading: OutlineTextStorage.Heading?) {
        
    }
}
