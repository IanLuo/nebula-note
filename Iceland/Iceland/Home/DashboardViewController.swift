//
//  MasterViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/2/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public protocol DashboardViewControllerDelegate: class {
    func didSelectTab(at index: Int, viewController: UIViewController)
    func showHeadings(tag: String)
    func showHeadings(planning: String)
    func showHeadingsScheduled(headings: [DocumentHeadingSearchResult])
    func showHeadingsOverdue(headings: [DocumentHeadingSearchResult])
    func showHeadingsScheduleSoon(headings: [DocumentHeadingSearchResult])
    func showHeadingsOverdueSoon(headings: [DocumentHeadingSearchResult])
    func showHeadingsWithoutDate(headings: [DocumentHeadingSearchResult])
}

public class DashboardViewController: UIViewController {
    public weak var delegate: DashboardViewControllerDelegate?
    private let viewModel: DashboardViewModel
    
    private let settingsButton: RoundButton = {
        let button = RoundButton()
        
        button.interface({ (me, theme) in
            (me as? RoundButton)?.setIcon(Asset.Assets.document.image.fill(color: theme.color.interactive), for: .normal)
            (me as? RoundButton)?.setBackgroundColor(theme.color.background3, for: .normal)
        })
        return button
    }()
    
    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interface { me, theme in
            me.view.backgroundColor = theme.color.background2
        }
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.settingsButton)
        
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self.settingsButton.sizeAnchor(width: 60)
        self.settingsButton.sideAnchor(for: [.left, .bottom], to: self.view, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: -Layout.edgeInsets.bottom, right: 0), considerSafeArea: true)
        
        self.settingsButton.tapped { [unowned self] _ in
            self.viewModel.coordinator?.showSettings()
        }
        
        self.viewModel.loadData()
    }
    
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
    
    fileprivate var tabs: [Tab] = []
    
    public func reload() {
        self.tableView.reloadData()
    }
    
    public func addTab(tabs: [TabType]) {
        tabs.sorted {
            $0.index < $1.index
        }.forEach {
            self.tabs.append(Tab(type: $0))
        }
    }
    
    fileprivate func selectOnTab(index: Int?) {
        if let index = index {
            self.tabs.forEach { $0.isCurrent = $0 == self.tabs[index] }
            self.delegate?.didSelectTab(at: index, viewController: self.tabs[index].type.viewController)
            self.selectOnSubtab(tab: index, subtab: nil)
        } else {
            self.tabs.forEach { $0.isCurrent = false }
        }
    }
    
    fileprivate func selectOnSubtab(tab: Int, subtab: Int?) {
        self.tabs.forEach {
            $0.sub.forEach {
                $0.isCurrent = false
            }
        }
        
        if let subtab = subtab { // 到这里的时候，table view 已经把选中的 cell 高亮显示了，所以不需要做高亮的操作
            self.selectOnSubtabAction(tab: tab, subtab: subtab)
            self.selectOnTab(index: nil) // 取消 tab 上的选中效果
            self.tabs[tab].sub[subtab].isCurrent = true
        } else {
            tableView.visibleCells.forEach {
                $0.setSelected(false, animated: false)
            }
        }
    }
    
    private func selectOnSubtabAction(tab: Int, subtab: Int) {
        let type = self.tabs[tab].sub[subtab].type
        switch type {
        case .tags:
            let tagsViewController = DashboardSubtypeItemViewController(subtype: self.tabs[tab].sub[subtab].type)
            tagsViewController.didSelectAction = { title in
                self.delegate?.showHeadings(tag: title)
            }
            self.navigationController?.pushViewController(tagsViewController, animated: true)
        case .plannings:
            let tagsViewController = DashboardSubtypeItemViewController(subtype: self.tabs[tab].sub[subtab].type)
            tagsViewController.didSelectAction = { title in
                self.delegate?.showHeadings(planning: title)
            }
            self.navigationController?.pushViewController(tagsViewController, animated: true)
        case .overdue:
            self.viewModel.coordinator?.showHeadingsOverdue(headings: self.viewModel.overdue)
        case .overdueSoon:
            self.viewModel.coordinator?.showHeadingsOverdueSoon(headings: self.viewModel.overdueSoon)
        case .scheduled:
            self.viewModel.coordinator?.showHeadingsScheduled(headings: self.viewModel.scheduled)
        case .scheduledSoon:
            self.viewModel.coordinator?.showHeadingsScheduleSoon(headings: self.viewModel.startSoon)
        case .withoutTag:
            self.viewModel.coordinator?.showHeadingsWithoutDate(headings: self.viewModel.withoutTag)
        default: break
        }
    }
    
    private func selectOnTabFoldArrow(tab index: Int, isOpen: Bool) {
        let count = self.tabs[index].sub.count
        let indexPaths = Array<Int>(0..<count).map { IndexPath(row: $0, section: index) }
        if isOpen {
            self.tableView.insertRows(at: indexPaths, with: .top)
        } else {
            self.tableView.deleteRows(at: indexPaths, with: .top)
        }
    }
    
    public enum TabType {
        case agenda(UIViewController, Int)
        case captureList(UIViewController, Int)
        case search(UIViewController, Int)
        case documents(UIViewController, Int)
        
        var viewController: UIViewController {
            switch self {
            case .agenda(let viewController, _): return viewController
            case .captureList(let viewController, _): return viewController
            case .search(let viewController, _): return viewController
            case .documents(let viewController, _): return viewController
            }
        }
        
        var index: Int {
            switch self {
            case .agenda(_ , let index): return index
            case .captureList(_ , let index): return index
            case .search(_ , let index): return index
            case .documents(_ , let index): return index
            }
        }
    }
    
    // MARK: - type definition -
    public enum SubtabType {
        case tags([String])
        case plannings([String])
        case scheduled(Int)
        case scheduledSoon(Int)
        case overdue(Int)
        case overdueSoon(Int)
        case withoutTag(Int)
        case finished
        case archived
        
        public var index: Int {
            switch self {
            case .tags: return 0
            case .plannings: return 1
            case .scheduled: return 2
            case .overdue: return 3
            case .scheduledSoon: return 4
            case .overdueSoon: return 5
            case .withoutTag: return 6
            case .finished: return 7
            case .archived: return 8
            }
        }
        
        var icon: UIImage? {
            switch self {
            case .tags(_): return Asset.Assets.tag.image
            case .plannings(_): return Asset.Assets.scheduled.image
            case .scheduled: return Asset.Assets.scheduled.image
            case .overdue: return Asset.Assets.due.image
            default: return nil
            }
        }
        
        var detailIcon: UIImage? {
            switch self {
            case .tags(_): return Asset.Assets.right.image.resize(upto: CGSize(width: 10, height: 10))
            case .plannings(_): return Asset.Assets.right.image.resize(upto: CGSize(width: 10, height: 10))
            default: return nil
            }
        }
        
        var title: String {
            switch self {
            case .tags(_): return L10n.Agenda.Sub.tags
            case .plannings: return L10n.Agenda.Sub.planning
            case .overdue: return L10n.Agenda.Sub.overdue
            case .scheduled: return L10n.Agenda.Sub.scheduled
            case .overdueSoon: return L10n.Agenda.Sub.overdueSoon
            case .scheduledSoon: return L10n.Agenda.Sub.startSoon
            case .withoutTag: return L10n.Agenda.Sub.noTag
            default: return ""
            }
        }
        
        var subtitle: String {
            switch self {
            case .tags(let tags): return "\(tags.count)"
            case .plannings(let plannings): return "\(plannings.count)"
            case .overdue(let count): return "\(count)"
            case .overdueSoon(let count): return "\(count)"
            case .scheduled(let count): return "\(count)"
            case .scheduledSoon(let count): return "\(count)"
            case .withoutTag(let count): return "\(count)"
            default: return ""
            }
        }
        
        //  下一级页面的数据
        var detailItems: [String] {
            switch self {
            case .tags(let tags): return tags
            case .plannings(let plannings): return plannings
            default: return []
            }
        }
    }
    
    fileprivate class Tab: Equatable {
        public static func == (lhs: DashboardViewController.Tab, rhs: DashboardViewController.Tab) -> Bool {
            return lhs.title == rhs.title
        }
        
        let type: TabType
        var icon: UIImage? { return self.type.viewController.tabBarItem.image }
        var title: String? { return self.type.viewController.title }
        var isOpen: Bool = false { didSet { didSetIsOpen?(isOpen) } }
        var isCurrent: Bool = false { didSet { didSetIsCurrent?(isCurrent) } }
        
        var didSetIsCurrent: ((Bool) -> Void)?
        var didSetIsOpen: ((Bool) -> Void)?
        
        public init(type: TabType) {
            self.type = type
        }
        
        public var sub: [Subtab] = [] {
            didSet {
                sub.sort { (left, right) -> Bool in
                    return left.type.index < right.type.index
                }
            }
        }
    }
    
    fileprivate class Subtab: Equatable {
        var icon: UIImage? { return self.type.icon }
        var title: String { return self.type.title }
        var subtitle: String { return self.type.subtitle }
        var isCurrent: Bool = false
        let type: SubtabType
        
        public static func == (lhs: DashboardViewController.Subtab, rhs: DashboardViewController.Subtab) -> Bool {
            return lhs.title == rhs.title
        }
        
        public init(type: SubtabType) {
            self.type = type
        }
    }
}

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.tabs[section].isOpen else { return 0 }

        return self.tabs[section].sub.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return self.tabs.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SubtabCell.reuseIdentifier, for: indexPath) as! SubtabCell
        let item = self.tabs[indexPath.section].sub[indexPath.row]
        cell.titleLabel.text = item.title
        cell.iconView.image = item.icon?.withRenderingMode(.alwaysTemplate)
        cell.subtitleLabel.text = item.subtitle
        cell.detailIconView.image = item.type.detailIcon?.withRenderingMode(.alwaysTemplate)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = self.tabs[indexPath.section].sub[indexPath.row]
        cell.setSelected(item.isCurrent, animated: false)
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: TabView.reuseIdentifier) as! TabView
        let tab = self.tabs[section]
        view.tab = tab
        view.shoudShowSubtabsButton = (self.tabs[section].sub.count) > 0
        
        view.action = {
            self.selectOnTab(index: section)
        }
        
        view.showSubtabsAction = {
            tab.isOpen = !tab.isOpen
            
            self.selectOnTabFoldArrow(tab: section, isOpen: tab.isOpen)
        }
        
        return view
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectOnSubtab(tab: indexPath.section, subtab: indexPath.row)
    }
    
    public func reloadDataIfNeeded() {
        self.viewModel.loadDataIfNeeded()
    }
}

extension DashboardViewController: DashboardViewModelDelegate {
    public func didCompleteLoadFilteredData() {
        self.tabs[0].sub.removeAll()
        
        if self.viewModel.scheduled.count > 0 {
            self.tabs[0].sub.append(Subtab(type: DashboardViewController.SubtabType.scheduled(self.viewModel.scheduled.count)))
        }
        
        if self.viewModel.allPlannings.count > 0 {
            self.tabs[0].sub.append(Subtab(type: DashboardViewController.SubtabType.plannings(Array(Set(self.viewModel.allPlannings)))))
        }

        if self.viewModel.overdue.count > 0 {
            self.tabs[0].sub.append(Subtab(type: DashboardViewController.SubtabType.overdue(self.viewModel.overdue.count)))
        }

        if self.viewModel.startSoon.count > 0 {
            self.tabs[0].sub.append(Subtab(type: DashboardViewController.SubtabType.scheduledSoon(self.viewModel.startSoon.count)))
        }

        if self.viewModel.overdueSoon.count > 0 {
            self.tabs[0].sub.append(Subtab(type: DashboardViewController.SubtabType.overdueSoon(self.viewModel.overdueSoon.count)))
        }

        if self.viewModel.withoutTag.count > 0 {
            self.tabs[0].sub.append(Subtab(type: DashboardViewController.SubtabType.withoutTag(self.viewModel.withoutTag.count)))
        }

        if self.viewModel.allTags.count > 0 {
            self.tabs[0].sub.append(Subtab(type: DashboardViewController.SubtabType.tags(Array(Set(self.viewModel.allTags)))))
        }
        
        self.tableView.reloadSections([0], with: UITableView.RowAnimation.none)
    }
}

// MARK: - TabView -

private class TabView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "TabView"
    
    var tab: DashboardViewController.Tab? {
        didSet {
            guard let tab = tab else { return }
            self.iconView.image = tab.icon?.withRenderingMode(.alwaysTemplate)
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
        button.tintColor = InterfaceTheme.Color.descriptiveHighlighted
        button.addTarget(self, action: #selector(subtabActionTapped), for: .touchUpInside)
        button.setImage(Asset.Assets.down.image.resize(upto: CGSize(width: 10, height: 10)).withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    var action: (() -> Void)?
    var showSubtabsAction: (() -> Void)?
    
    var isOpen: Bool = false {
        didSet {
            if isOpen {
                self.showSubtabsButton.perspectiveRotate(angel: CGFloat.pi)
            } else {
                self.showSubtabsButton.perspectiveRotate(angel: 0)
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
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: 0))
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.sizeAnchor(width: 15, height: 15)
        
        self.titleButton.allSidesAnchors(to: self.contentView, edgeInset: 0)
        self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 70, bottom: 20, right: 0)
        
        self.showSubtabsButton.sizeAnchor(width: 0)
        self.showSubtabsButton.lastBaselineAnchor.constraint(equalTo: self.titleButton.lastBaselineAnchor).isActive = true
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
    
    let detailIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = InterfaceTheme.Color.descriptive
        imageView.contentMode = .scaleAspectFit
        return imageView
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
        self.contentView.addSubview(self.detailIconView)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: 60, bottom: 0, right: 0))
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.sizeAnchor(width: 15, height: 15)
        self.iconView.rowAnchor(view: self.titleLabel, space: 20)
        self.titleLabel.sideAnchor(for: [.top, .bottom], to: self.contentView, edgeInsets: .init(top: 15, left: 0, bottom: -15, right: 0))
        
        self.titleLabel.rowAnchor(view: self.subtitleLabel, space: 3)
        self.subtitleLabel.sideAnchor(for: [.top, .bottom], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        self.subtitleLabel.rowAnchor(view: self.detailIconView, space: 3)
        self.detailIconView.sideAnchor(for: .right, to: self.contentView, edgeInset: Layout.edgeInsets.right)
        self.detailIconView.sizeAnchor(width: 10, height: 10)
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
