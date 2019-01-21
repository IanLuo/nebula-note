//
//  MasterView.swift
//  Iceland
//
//  Created by ian luo on 2019/1/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol MasterViewDelegate: class {
    func didSelect(at index: Int)
}

public class MasterView: UIView {
    public init() {
        super.init(frame: .zero)
        
        self.backgroundColor = UIColor.blue
        
        self.addSubview(self.tableView)
        self.tableView.frame = self.bounds
        self.tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public weak var delegate: MasterViewDelegate?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableView
    }()

    public struct Item {
        let icon: UIImage
        let title: String
    }
    
    public private(set) var items: [Item] = []
    
    public func addItem(_ item: Item) {
        self.items.append(item)
    }
}

extension MasterView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let item = self.items[indexPath.row]
        cell.imageView?.image = item.icon
        cell.textLabel?.text = item.title
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelect(at: indexPath.row)
    }
}
