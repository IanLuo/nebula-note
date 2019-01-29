//
//  MasterView.swift
//  Iceland
//
//  Created by ian luo on 2019/1/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol MasterViewDelegate: class {
    func didSelectTab(at index: Int)
    func didSelectTag(at index: Int)
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
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.register(ItemCell.self, forCellReuseIdentifier: ItemCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        return tableView
    }()

    public struct Item {
        let icon: UIImage?
        let title: String
    }
    
    public private(set) var tabs: [Item] = []
    
    public private(set) var tags: [Item] = []
    
    public func addTab(_ item: Item) {
        self.tabs.append(item)
    }
    
    public func addTag(_ item: Item) {
        self.tags.append(item)
    }
}

extension MasterView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.tabs.count
        } else if section == 1 {
            return self.tags.count
        }
        
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.reuseIdentifier, for: indexPath) as! ItemCell
        
        let item = self.tabs[indexPath.row]
        cell.iconView.image = item.icon?.withRenderingMode(.alwaysTemplate)
        cell.titleLabel.text = item.title
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelectTab(at: indexPath.row)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

private class ItemCell: UITableViewCell {
    static let reuseIdentifier = "ItemCell"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.interactive
        label.textAlignment = .left
        return label
    }()
    
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = InterfaceTheme.Color.descriptive
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = InterfaceTheme.Color.background2
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.iconView)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 10, left: 30, bottom: -10, right: 0))
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.sizeAnchor(width: 15, height: 15)
        self.iconView.rowAnchor(view: self.titleLabel, space: 20)
        self.titleLabel.sideAnchor(for: [.top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 20, left: 0, bottom: -20, right: -30))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = InterfaceTheme.Color.background3
        } else {
            self.backgroundColor = InterfaceTheme.Color.background2
        }
    }
    
    override public func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.backgroundColor = InterfaceTheme.Color.background3
        } else {
            self.backgroundColor = InterfaceTheme.Color.background2
        }
    }
}
