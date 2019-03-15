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
import Interface

public protocol DashboardSubtypeItemViewControllerDelegate: class {
    func didSelect(title: String)
}

public class DashboardSubtypeItemViewController: UIViewController {
    public struct Item {
        let icon: UIImage
        let title: String
    }
    
    public weak var delegate: DashboardSubtypeItemViewControllerDelegate?
    private let subtype: DashboardViewController.SubtabType
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ItemCell.self, forCellReuseIdentifier: ItemCell.reuseIdentifier)
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    public init(subtype: DashboardViewController.SubtabType) {
        self.subtype = subtype
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
        button.setImage(Asset.Assets.left.image.withRenderingMode(.alwaysTemplate), for: .normal)
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

extension DashboardSubtypeItemViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelect(title: self.subtype.detailItems[indexPath.row])
    }
}

extension DashboardSubtypeItemViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.subtype.detailItems.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemCell.reuseIdentifier, for: indexPath)
        let title = self.subtype.detailItems[indexPath.row]
        cell.imageView?.image = self.subtype.icon
        cell.textLabel?.text = title
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

private class ItemCell: UITableViewCell {
    static let reuseIdentifier: String = "ItemCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.textLabel?.textColor = InterfaceTheme.Color.interactive
        self.textLabel?.font = InterfaceTheme.Font.body
        self.backgroundColor = InterfaceTheme.Color.background2
        self.imageView?.contentMode = .scaleAspectFit
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
