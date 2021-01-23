//
//  MasterViewController.swift
//  Iceland
//
//  Created by ian luo on 2019/2/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import RxSwift
import RxCocoa

public protocol DashboardViewControllerDelegate: class {
    func didSelectTab(at index: Int, viewController: UIViewController)
    func showHeadings(tag: String)
    func showHeadings(planning: String)
    func showHeadings(subTabType: DashboardViewModel.DahsboardItemData)
}

public class DashboardViewController: UIViewController {
    public weak var delegate: DashboardViewControllerDelegate?
    private let viewModel: DashboardViewModel
    private let disposeBag = DisposeBag()
    
    private let settingsButton: RoundButton = {
        let button = RoundButton()
        
        button.interface({ (me, theme) in
            (me as? RoundButton)?.setIcon(Asset.SFSymbols.gear.image.fill(color: theme.color.interactive), for: .normal)
            (me as? RoundButton)?.setBackgroundColor(theme.color.background2, for: .normal)
        })
        return button
    }()
    
    private let trashButton: RoundButton = {
        let button = RoundButton()
        
        button.interface({ (me, theme) in
            (me as? RoundButton)?.setIcon(Asset.SFSymbols.trash.image.fill(color: theme.color.interactive), for: .normal)
            (me as? RoundButton)?.setBackgroundColor(theme.color.background2, for: .normal)
        })
        return button
    }()
    
    private let membershipButton: UIButton = {
        let button = UIButton()
        
        button.interface { (me, theme) in
            let button = me as! UIButton
            button.setBackgroundImage(UIImage.create(with: theme.color.background2, size: .singlePoint), for: .normal)
            button.titleLabel?.font = theme.font.footnote
            button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
            button.setTitleColor(theme.color.interactive, for: .normal)
        }
        
        button.roundConer(radius: 8)
        button.setTitle(L10n.Membership.title, for: .normal)
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
        title = L10n.dashboard
        
        super.viewDidLoad()
        
        self.interface { me, theme in
            let me = me as! DashboardViewController
            me.setNeedsStatusBarAppearanceUpdate()
            me.view.backgroundColor = theme.color.background1
            me.navigationController?.navigationBar.setBackgroundImage(UIImage.create(with: theme.color.background1, size: .singlePoint), for: .default)
        }
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.settingsButton)
        self.view.addSubview(self.trashButton)
        self.view.addSubview(self.membershipButton)
        
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0)
        
        self.settingsButton.sizeAnchor(width: 60)
        self.settingsButton.sideAnchor(for: [.left, .bottom], to: self.view, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: -Layout.edgeInsets.bottom, right: 0), considerSafeArea: true)
        
        self.trashButton.sizeAnchor(width: 60)
        self.trashButton.sideAnchor(for: [.right, .bottom], to: self.view, edgeInsets: .init(top: 0, left: 0, bottom: -Layout.edgeInsets.bottom, right: -Layout.edgeInsets.right), considerSafeArea: true)
        
        self.membershipButton.bottomAnchor.constraint(equalTo: self.settingsButton.topAnchor, constant: -20).isActive = true
        self.membershipButton.sideAnchor(for: .left, to: self.view, edgeInset: Layout.edgeInsets.left, considerSafeArea: true)
        self.membershipButton.sizeAnchor(height: 30)
        
        self.trashButton.tapped { [unowned self] _ in
            self.viewModel.coordinator?.showTrash()
        }
        
        self.settingsButton.tapped { [unowned self] _ in
            self.viewModel.coordinator?.showSettings()
        }
        
        self.membershipButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.viewModel.coordinator?.showMembershipView()
        }).disposed(by: self.disposeBag)
        
        self.viewModel
            .coordinator?
            .dependency
            .purchaseManager
            .isMember
            .subscribe(onNext: { [weak self] isMember in
                self?.membershipButton.isHidden = isMember
        }).disposed(by: self.disposeBag)
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.interface({ (me, theme) in
            let tableView = me as! UITableView
            tableView.backgroundColor = theme.color.background1
        })
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
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
    
    public func selectOnTab(index: Int?) {
        if let index = index {
            self.tabs.forEach { $0.isCurrent = $0 == self.tabs[index] }
            self.delegate?.didSelectTab(at: index, viewController: self.tabs[index].type.viewController)
            self.selectOnSubtab(tab: index, subtab: nil)
        } else {
            self.tabs.forEach { $0.isCurrent = false }
        }
    }
    
    public func viewController(at index: Int) -> UIViewController? {
        return self.tabs[index].type.viewController
    }
    
    public func selectOnSubtab(tab: Int, subtab: Int?) {
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
        case .allTags:
            let tagsViewController = DashboardSubtypeItemViewController(subtype: self.tabs[tab].sub[subtab].type)
            tagsViewController.title = type.title
            tagsViewController.didSelectAction = { title in
                self.delegate?.showHeadings(tag: title)
            }
            self.navigationController?.pushViewController(tagsViewController, animated: true)
        case .allStatus:
            let tagsViewController = DashboardSubtypeItemViewController(subtype: self.tabs[tab].sub[subtab].type)
            tagsViewController.title = type.title
            tagsViewController.didSelectAction = { title in
                self.delegate?.showHeadings(planning: title)
            }
            self.navigationController?.pushViewController(tagsViewController, animated: true)
        default:
            self.delegate?.showHeadings(subTabType: type)
        }
    }
    
    public enum TabType {
        case agenda(UIViewController, Int)
        case captureList(UIViewController, Int)
        case search(UIViewController, Int)
        case documents(UIViewController, Int)
        case favorite(UIViewController, Int)
        
        var viewController: UIViewController {
            switch self {
            case .agenda(let viewController, _): return viewController
            case .captureList(let viewController, _): return viewController
            case .search(let viewController, _): return viewController
            case .documents(let viewController, _): return viewController
            case .favorite(let viewController, _): return viewController
            }
        }
        
        var index: Int {
            switch self {
            case .agenda(_ , let index): return index
            case .captureList(_ , let index): return index
            case .search(_ , let index): return index
            case .documents(_ , let index): return index
            case .favorite(_, let index): return index
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
        let type: DashboardViewModel.DahsboardItemData
        
        public static func == (lhs: DashboardViewController.Subtab, rhs: DashboardViewController.Subtab) -> Bool {
            return lhs.title == rhs.title
        }
        
        public init(type: DashboardViewModel.DahsboardItemData) {
            self.type = type
        }
    }
}

// MARK: - type definition -
extension DashboardViewModel.DahsboardItemData {
    public var index: Int {
        switch self {
        case .allTags: return 0
        case .allStatus: return 1
        case .scheduled: return 2
        case .overdue: return 3
        case .overdueSoon: return 5
        case .startSoon: return 6
        case .today: return 9
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .allTags(_): return Asset.SFSymbols.tag.image
        case .allStatus(_): return Asset.Assets.planning.image
        case .scheduled: return Asset.SFSymbols.calendarBadgePlus.image
        case .overdue: return Asset.SFSymbols.calendarBadgeExclamationmark.image
        default: return nil
        }
    }
    
    var detailIcon: UIImage? {
        switch self {
        case .allTags(_): return Asset.SFSymbols.chevronRight.image.resize(upto: CGSize(width: 10, height: 10))
        case .allStatus(_): return Asset.SFSymbols.chevronRight.image.resize(upto: CGSize(width: 10, height: 10))
        default: return nil
        }
    }
    
    var title: String {
        switch self {
        case .allTags(_): return L10n.Agenda.Sub.tags
        case .allStatus: return L10n.Agenda.Sub.planning
        case .overdue: return L10n.Agenda.Sub.overdue
        case .scheduled: return L10n.Agenda.Sub.scheduled
        case .overdueSoon: return L10n.Agenda.Sub.overdueSoon
        case .startSoon: return L10n.Agenda.Sub.startSoon
        case .today: return L10n.Agenda.Sub.today
        }
    }
    
    var subtitle: String {
        switch self {
        case .allTags(let tags): return "\(tags.count)"
        case .allStatus(let plannings): return "\(plannings.count)"
        case .overdue(let headings): return "\(headings.count)"
        case .overdueSoon(let headings): return "\(headings.count)"
        case .scheduled(let headings): return "\(headings.count)"
        case .startSoon(let headings): return "\(headings.count)"
        case .today(let headings): return "\(headings.count)"
        }
    }
    
    //  下一级页面的数据
    var detailItems: [String] {
        switch self {
        case .allTags(let tags): return tags
        case .allStatus(let status): return status
        default: return []
        }
    }
}

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        
        view.action = {
            self.selectOnTab(index: section)
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
        
        self.viewModel.itemsData.forEach { data in
            self.tabs[0].sub.append(Subtab(type: data))
        }
        
        self.tableView.reloadSections([0], with: UITableView.RowAnimation.none)
    }
}

// MARK: - TabView -

private class TabView: UITableViewHeaderFooterView {
    static let reuseIdentifier = "TabView"
    private let disposeBag = DisposeBag()
    
    var tab: DashboardViewController.Tab? {
        didSet {
            guard let tab = tab else { return }
            self.titleButton.setTitle(tab.title, for: .normal)
            self.isHighlighted = tab.isCurrent
            self.iconView.image = tab.icon?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            
            tab.didSetIsCurrent = {
                self.isHighlighted = $0
            }
            
        }
    }
    
    lazy var titleButton: UIButton = {
        let button = UIButton()
        button.interface({ (me, theme) in
            let button = me as! UIButton
            button.titleLabel?.font = theme.font.title
            button.setTitleColor(theme.color.interactive, for: .normal)
            button.setTitleColor(theme.color.spotlitTitle, for: .selected)
            button.setBackgroundImage(UIImage.create(with: theme.color.spotlight, size: .singlePoint), for: .selected)
            button.setBackgroundImage(UIImage.create(with: theme.color.background1, size: .singlePoint), for: .normal)
        })
        button.contentHorizontalAlignment = .left
        button.rx.tap.subscribe(onNext: { [weak self] in
            self?.action?()
        }).disposed(by: self.disposeBag)
        return button
    }()
    
    lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.interface({ [weak self] (me, theme) in
            let imageView = me as! UIImageView
            imageView.tintColor = self?.isHighlighted == true ? theme.color.spotlitTitle : theme.color.descriptive
        })
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
        
    var action: (() -> Void)?
    var isHighlighted: Bool {
        get { return self.titleButton.isSelected }
        set {
            self.titleButton.isSelected = newValue
            self.iconView.tintColor = newValue ? InterfaceTheme.Color.spotlitTitle : InterfaceTheme.Color.interactive
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.interface { (me, theme) in
            let tabView = me as! TabView
            tabView.contentView.backgroundColor = InterfaceTheme.Color.background1
            tabView.backgroundColor = InterfaceTheme.Color.background1
        }
        self.contentView.addSubview(self.titleButton)
        self.contentView.addSubview(self.iconView)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInsets: .init(top: 0, left: Layout.innerViewEdgeInsets.left, bottom: 0, right: 0))
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.sizeAnchor(width: 20, height: 20)
        
        self.titleButton.roundConer(radius: 8)
        self.titleButton.allSidesAnchors(to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: Layout.innerViewEdgeInsets.left + 20 + 20, bottom: 20, right: 0)
        
        #if targetEnvironment(macCatalyst)
        #else
        self.interface { (view, theme) in
            let me = view as! TabView
            if #available(iOS 14.0, *) {
                me.backgroundConfiguration?.backgroundColor = theme.color.background1
            }
        }
        #endif

        self.titleButton.enableHover { [weak self] isHoving in
            if isHoving {
                self?.titleButton.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background3, size: .singlePoint), for: .normal)
            } else {
                self?.titleButton.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background1, size: .singlePoint), for: .normal)
            }
        }
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
        
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.body
            label.textColor = theme.color.interactive
        })
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        
        label.interface({ (me, theme) in
            let label = me as! UILabel
            label.font = theme.font.footnote
            label.textColor = theme.color.descriptive
        })
        
        label.textAlignment = .right
        return label
    }()
    
    let detailIconView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.interface({ (me, theme) in
            let imageView = me as! UIImageView
            imageView.tintColor = InterfaceTheme.Color.descriptive
        })
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let iconView: UIImageView = {
        let imageView = UIImageView()
        
        imageView.interface({ (me, theme) in
            let imageView = me as! UIImageView
            imageView.tintColor = InterfaceTheme.Color.descriptive
        })
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let innerContentView: UIView = {
        let view = UIView()
        
        view.interface ({ (me, interface) in
            me.backgroundColor = interface.color.background1
        })
        
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.interface { (me, theme) in
            me.backgroundColor = theme.color.background1
        }
        
        self.contentView.addSubview(self.innerContentView)
        self.innerContentView.addSubview(self.titleLabel)
        self.innerContentView.addSubview(self.iconView)
        self.innerContentView.addSubview(self.subtitleLabel)
        self.innerContentView.addSubview(self.detailIconView)
        
        self.innerContentView.allSidesAnchors(to: self.contentView, edgeInsets: .init(top: 0, left: 60, bottom: 0, right: -Layout.edgeInsets.right))
        self.innerContentView.roundConer(radius: 8)
        
        self.iconView.sideAnchor(for: .left, to: self.innerContentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: 0))
        self.iconView.centerAnchors(position: .centerY, to: self.innerContentView)
        self.iconView.sizeAnchor(width: 15, height: 15)
        self.iconView.rowAnchor(view: self.titleLabel, space: 20)
        
        self.titleLabel.rowAnchor(view: self.subtitleLabel, space: 3)
        
        self.subtitleLabel.rowAnchor(view: self.detailIconView, space: 3)
        self.subtitleLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)
        self.detailIconView.sideAnchor(for: .right, to: self.innerContentView, edgeInset: Layout.edgeInsets.right)
        self.detailIconView.sizeAnchor(width: 10, height: 10)
        
        self.enableHover(on: self.innerContentView, hoverColor: InterfaceTheme.Color.background3)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.innerContentView.backgroundColor = InterfaceTheme.Color.spotlight
            self.subtitleLabel.textColor = InterfaceTheme.Color.spotlitTitle
            self.titleLabel.textColor = InterfaceTheme.Color.spotlitTitle
            self.detailIconView.tintColor = InterfaceTheme.Color.spotlitTitle
            self.iconView.tintColor = InterfaceTheme.Color.spotlitTitle
        } else {
            self.innerContentView.backgroundColor = InterfaceTheme.Color.background1
            self.subtitleLabel.textColor = InterfaceTheme.Color.interactive
            self.titleLabel.textColor = InterfaceTheme.Color.interactive
            self.detailIconView.tintColor = InterfaceTheme.Color.interactive
            self.iconView.tintColor = InterfaceTheme.Color.interactive
        }
    }
    
    override public func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.innerContentView.backgroundColor = InterfaceTheme.Color.spotlight
            self.subtitleLabel.textColor = InterfaceTheme.Color.spotlitTitle
            self.titleLabel.textColor = InterfaceTheme.Color.spotlitTitle
            self.detailIconView.tintColor = InterfaceTheme.Color.spotlitTitle
            self.iconView.tintColor = InterfaceTheme.Color.spotlitTitle
        } else {
            self.innerContentView.backgroundColor = InterfaceTheme.Color.background1
            self.subtitleLabel.textColor = InterfaceTheme.Color.interactive
            self.titleLabel.textColor = InterfaceTheme.Color.interactive
            self.detailIconView.tintColor = InterfaceTheme.Color.interactive
            self.iconView.tintColor = InterfaceTheme.Color.interactive
        }
    }
}
