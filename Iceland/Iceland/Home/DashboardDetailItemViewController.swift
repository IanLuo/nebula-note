//
//  DashboardDetailItemViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/2/2.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol DashboardDetailItemViewControllerDelegate: class {
    func didSelect(index: Int)
}

public class DashboardDetailItemViewController: UIViewController {
    public struct Item {
        let icon: UIImage
        let title: String
    }
    
    public weak var delegate: DashboardDetailItemViewControllerDelegate?
    public var items: [Item] = []
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    public init(items: [Item]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
    }
    
    private let backButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background2
        
        self.view.addSubview(self.backButton)
        self.view.addSubview(self.tableView)
        
        self.backButton.sideAnchor(for: [.left, .top], to: self.view, edgeInset: 30)
        self.backButton.sizeAnchor(width: 40, height: 40)
        
        self.backButton.columnAnchor(view: self.tableView, space: 20)

        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
        
        self.backButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    }
    
    @objc private func cancel() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension DashboardDetailItemViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelect(index: indexPath.row)
    }
}

extension DashboardDetailItemViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = self.items[indexPath.row]
        cell.imageView?.image = item.icon
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = InterfaceTheme.Color.interactive
        cell.textLabel?.font = InterfaceTheme.Font.body
        cell.backgroundColor = InterfaceTheme.Color.background2
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
