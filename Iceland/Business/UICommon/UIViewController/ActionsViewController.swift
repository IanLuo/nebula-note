//
//  ActionsViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class ActionsViewController: UIViewController {
    private struct Constants {
        static let rowHeight = 80
    }
    
    public enum Style {
        case `default`
        case highlight
        case warning
    }
    
    public func addAction(icon: UIImage?, title: String, style: Style = .default, action: @escaping (ActionsViewController) -> Void) {
        self.items.append(Item(icon: icon, title: title, action: action, style: style))
        
        if self.isInitialized {
            self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: UITableView.RowAnimation.none)
            UIView.animate(withDuration: 0.25, animations: {
                self.tableView.constraint(for: Position.height)?.constant = CGFloat(self.items.count * Constants.rowHeight)
                self.view.layoutIfNeeded()
            })
        }
    }
    
    public func removeAction(with title: String) {
        var index = -1
        for (i, item) in self.items.enumerated() {
            if item.title == title {
                index = i
                break
            }
        }
        
        guard index >= 0 else { return }
        
        self.items.remove(at: index)
        
        if self.isInitialized {
            UIView.animate(withDuration: 0.25, animations: {
                self.tableView.constraint(for: Position.height)?.constant = CGFloat(self.items.count * Constants.rowHeight)
                self.view.layoutIfNeeded()
            }, completion: {
                if $0 {
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: UITableView.RowAnimation.bottom)
                }
            })
        }
    }
    
    public func setCancel(action: @escaping (UIViewController) -> Void) {
        self.cancelAction = action
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private var items: [Item] = []
    
    private var isInitialized: Bool = false
    
    private var cancelAction: ((UIViewController) -> Void)?
    
    public var accessoryView: UIView? {
        didSet {
            // 如果没有，则隐藏 accessoryViewContainer
            accessoryViewContainer.isHidden = accessoryView == nil
            
            if let accessoryView = accessoryView {
                accessoryViewContainer.subviews.forEach { $0.removeFromSuperview() }
                accessoryViewContainer.addSubview(accessoryView)
            } else {
                let emptyView = UIView()
                accessoryViewContainer.addSubview(emptyView)
                emptyView.sizeAnchor(height: 0)
                emptyView.allSidesAnchors(to: accessoryViewContainer, edgeInset: 0)
            }
        }
    }
    
    private let accessoryViewContainer: UIView = UIView()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background2
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("x", for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.separatorStyle = .none
        tableView.register(ActionCell.self, forCellReuseIdentifier: ActionCell.reuseIdentifier)
        return tableView
    }()
    
    private func setupUI() {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.accessoryViewContainer.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.contentView)
        
        self.contentView.addSubview(self.tableView)
        self.contentView.addSubview(self.accessoryViewContainer)
        self.contentView.addSubview(self.cancelButton)
        
        self.contentView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
        
        self.cancelButton.sideAnchor(for: [.top, .right], to: self.contentView, edgeInset: 0)
        self.cancelButton.columnAnchor(view: self.accessoryViewContainer, space: 10)
        self.cancelButton.sizeAnchor(width: 44, height: 44)
        
        self.accessoryViewContainer.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        self.accessoryViewContainer.columnAnchor(view: self.tableView)
        
        self.tableView.sizeAnchor(height: CGFloat(self.items.count * Constants.rowHeight))
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: -20, right: 0))
        
        self.isInitialized = true
    }
    
    @objc func cancel() {
        self.cancelAction?(self)
    }
    
    fileprivate struct Item {
        let icon: UIImage?
        let title: String
        let action: (ActionsViewController) -> Void
        let style: ActionsViewController.Style
    }
}

extension ActionsViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActionCell.reuseIdentifier, for: indexPath) as! ActionCell
        
        let item = self.items[indexPath.row]
        cell.item = item

        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.items[indexPath.row].action(self)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(Constants.rowHeight)
    }
}

fileprivate class ActionCell: UITableViewCell {
    fileprivate var item: ActionsViewController.Item? {
        didSet {
            guard let item = item else { return }
            
            self.iconView.image = item.icon
            self.titleLabel.text = item.title
            
            switch item.style {
            case .default:
                self.backgroundColor = InterfaceTheme.Color.background2
            case .highlight:
                self.backgroundColor = InterfaceTheme.Color.backgroundHighlight
            case .warning:
                self.backgroundColor = UIColor.red
            }
        }
    }
    
    static let reuseIdentifier = "ActionCell"
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.interactive
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = InterfaceTheme.Color.background2
        
        self.iconView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.titleLabel)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInset: 30)
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        
        self.titleLabel.centerAnchors(position: [.centerX, .centerY], to: self.contentView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
