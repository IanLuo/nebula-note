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
    func didSelectSubtab(at index: Int, for tabIndex: Int)
}

public class MasterView: UIView {
    public init() {
        super.init(frame: .zero)
        
        self.backgroundColor = UIColor.blue
        
        self.addSubview(self.tableView)
        self.tableView.fill(view: self)
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
        tableView.separatorStyle = .none
        tableView.register(TabView.self, forHeaderFooterViewReuseIdentifier: TabView.reuseIdentifier)
        tableView.register(SubtabCell.self, forCellReuseIdentifier: SubtabCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    public class Tab: Equatable {
        public static func == (lhs: MasterView.Tab, rhs: MasterView.Tab) -> Bool {
            return lhs.title == rhs.title
        }
        
        let icon: UIImage?
        let title: String
        var isOpen: Bool = false { didSet { didSetIsOpen?(isOpen) } }
        var isCurrent: Bool = false { didSet { didSetIsCurrent?(isCurrent) } }
        
        var didSetIsCurrent: ((Bool) -> Void)?
        var didSetIsOpen: ((Bool) -> Void)?
        
        public init(icon: UIImage?, title: String) {
            self.icon = icon
            self.title = title
        }
    }
    
    public class Subtab: Equatable {
        let icon: UIImage?
        let title: String
        let subtitle: String
        var isCurrent: Bool = false
        
        public static func == (lhs: MasterView.Subtab, rhs: MasterView.Subtab) -> Bool {
            return lhs.title == rhs.title
        }
        
        public init(icon: UIImage?, title: String, subtitle: String) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
        }
    }
    
    public private(set) var tabs: [Tab] = []
    
    public func reload() {
        self.tableView.reloadData()
    }
    
    public private(set) var subtabs: [Int: [Subtab]] = [:]
    
    public func addTab(_ item: Tab) {
        self.tabs.append(item)
    }
    
    public func addSubTab(_ subTabs: [Subtab], for tabIndex: Int) {
        self.subtabs[tabIndex] = subTabs
    }
    
    fileprivate func selectOnTab(index: Int?) {
        if let index = index {
            self.tabs.forEach { $0.isCurrent = $0 == self.tabs[index] }
            self.delegate?.didSelectTab(at: index)
            self.selectOnSubtab(tab: index, subtab: nil)
        } else {
            self.tabs.forEach { $0.isCurrent = false }
        }
    }
    
    fileprivate func selectOnSubtab(tab: Int, subtab: Int?) {
        self.subtabs.forEach {
            $0.value.forEach {
                $0.isCurrent = false
            }
        }
        
        if let subtab = subtab { // 到这里的时候，table view 已经把选中的 cell 高亮显示了，所以不需要做高亮的操作
            self.delegate?.didSelectSubtab(at: tab, for: subtab)
            self.selectOnTab(index: nil)
            self.subtabs[tab]![subtab].isCurrent = true
        } else {
            tableView.visibleCells.forEach {
                $0.setSelected(false, animated: false)
            }
        }
    }
}

extension MasterView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.tabs[section].isOpen else { return 0 }
        return self.subtabs[section]?.count ?? 0
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.tabs.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubtabCell.reuseIdentifier, for: indexPath) as! SubtabCell
        let item = self.subtabs[indexPath.section]![indexPath.row]
        cell.titleLabel.text = item.title
        cell.iconView.image = item.icon?.withRenderingMode(.alwaysTemplate)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = self.subtabs[indexPath.section]![indexPath.row]
        cell.setSelected(item.isCurrent, animated: false)
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: TabView.reuseIdentifier) as! TabView
        let tab = self.tabs[section]
        view.tab = tab
        view.shoudShowSubtabsButton = (self.subtabs[section]?.count ?? 0) > 0

        view.action = {
            self.selectOnTab(index: section)
        }
        
        view.showSubtabsAction = {
            tab.isOpen = !tab.isOpen
            
            if let count = self.subtabs[section]?.count {
                let indexPaths = Array<Int>(0..<count).map { IndexPath(row: $0, section: section) }
                if tab.isOpen {
                    self.tableView.insertRows(at: indexPaths, with: .top)
                } else {
                    self.tableView.deleteRows(at: indexPaths, with: .top)
                }
            }
        }
        
        return view
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectOnSubtab(tab: indexPath.section, subtab: indexPath.row)
    }
}

// MARK: - TabView -

private class TabView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "TabView"
    
    var tab: MasterView.Tab? {
        didSet {
            guard let tab = tab else { return }
            self.iconView.image = tab.icon
            self.titleButton.setTitle(tab.title, for: .normal)
            self.isHighlighted = tab.isCurrent
            self.isOpen = tab.isOpen
            
            tab.didSetIsCurrent = {
                self.isHighlighted = $0
            }
            
            tab.didSetIsOpen = {
                self.isOpen = $0
            }
        }
    }
    
    let titleButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = InterfaceTheme.Font.title
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background3, size: .singlePoint), for: .selected)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        return button
    }()
    
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = InterfaceTheme.Color.descriptive
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let showSubtabsButton: UIButton = {
        let button = UIButton()
        button.tintColor = InterfaceTheme.Color.interactive
        button.addTarget(self, action: #selector(subtabActionTapped), for: .touchUpInside)
        button.setTitle("▽", for: UIControl.State.normal)
        return button
    }()
    
    var action: (() -> Void)?
    var showSubtabsAction: (() -> Void)?
    
    var isOpen: Bool = false {
        didSet {
            var transform = CATransform3DIdentity
            if isOpen {
                transform = CATransform3DRotate(transform, CGFloat.pi, 1, 0, 0)
            }

            var perspective = CATransform3DIdentity
            perspective.m34 = 1.0 / -1800.0;
            self.showSubtabsButton.superview!.layer.sublayerTransform = perspective
            self.showSubtabsButton.layer.zPosition = 100
            
            UIView.animate(withDuration: 0.5) {
                self.showSubtabsButton.layer.transform = transform
            }
        }
    }
    
    var isHighlighted: Bool {
        get { return self.titleButton.isSelected }
        set { self.titleButton.isSelected = newValue }
    }
    
    var shoudShowSubtabsButton: Bool = false {
        didSet {
            showSubtabsButton.constraint(for: .width)?.constant = shoudShowSubtabsButton ? 40 : 0
            showSubtabsButton.isHidden = !shoudShowSubtabsButton
            self.layoutIfNeeded()
        }
    }
    
    @objc private func actionTapped() {
        self.action?()
    }
    
    @objc private func subtabActionTapped() {
        self.showSubtabsAction?()
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        self.contentView.backgroundColor = InterfaceTheme.Color.background2
        self.contentView.addSubview(self.titleButton)
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.showSubtabsButton)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: 30, bottom: 0, right: 0))
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.sizeAnchor(width: 15, height: 15)
        
        self.titleButton.allSidesAnchors(to: self.contentView, edgeInset: 0)
        self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 55, bottom: 20, right: 0)
        
        self.showSubtabsButton.sizeAnchor(width: 0)
        self.showSubtabsButton.centerAnchors(position: .centerY, to: self.contentView)
        self.showSubtabsButton.sideAnchor(for: [.top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -30))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - SubtabCell -

private class SubtabCell: UITableViewCell {
    static let reuseIdentifier: String = "SubtabCell"
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.body
        label.textColor = InterfaceTheme.Color.interactive
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.footnote
        label.textColor = InterfaceTheme.Color.descriptive
        return label
    }()
    
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = InterfaceTheme.Color.descriptive
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = InterfaceTheme.Color.background2
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.subtitleLabel)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: 60, bottom: 0, right: 0))
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.sizeAnchor(width: 15, height: 15)
        self.iconView.rowAnchor(view: self.titleLabel, space: 10)
        self.titleLabel.sideAnchor(for: [.top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 15, left: 0, bottom: -15, right: -30))
        
        self.titleLabel.rowAnchor(view: self.subtitleLabel)
        self.subtitleLabel.sideAnchor(for: [.top, .bottom, .right], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: 30))
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
