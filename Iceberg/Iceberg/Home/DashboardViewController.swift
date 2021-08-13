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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        title = L10n.App.name
        
        super.viewDidLoad()
        
        self.interface { me, theme in
            let me = me as! DashboardViewController
            me.setNeedsStatusBarAppearanceUpdate()
            me.view.backgroundColor = theme.color.background1
            me.navigationController?.navigationBar.setBackgroundImage(UIImage.create(with: theme.color.background1, size: .singlePoint), for: .default)
        }
        
        self.view.addSubview(self.tableView)
        
        let footer = UIStackView(subviews: [
            self.membershipButton,
            UIStackView(subviews: [
                self.settingsButton,
                self.trashButton
            ], distribution: .equalSpacing, spacing: 20).sizeAnchor(height: 44)
        ], axis: .horizontal, alignment: .center, spacing: 20)
        
        self.tableView.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
        
        let footerContainer = UIView(child: footer).interface({ me, theme in
            me.backgroundColor = theme.color.background1
        })
        self.view.addSubview(footerContainer)
        footerContainer.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 20, considerSafeArea: true)
        
        self.trashButton.tapped { [unowned self] _ in
            self.viewModel.context.coordinator?.showTrash()
        }
        
        self.settingsButton.tapped { [unowned self] _ in
            self.viewModel.context.coordinator?.showSettings()
        }
        
        self.membershipButton.rx.tap.subscribe(onNext: { [unowned self] _ in
            self.viewModel.context.coordinator?.showMembershipView()
        }).disposed(by: self.disposeBag)
        
        self.viewModel
            .context
            .coordinator?
            .dependency
            .purchaseManager
            .isMember
            .subscribe(onNext: { [weak self] isMember in
                self?.membershipButton.isHidden = isMember
                guard self?.view.window != nil else { return }
                self?.view.layoutIfNeeded()
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
        tableView.register(TabViewCell.self, forCellReuseIdentifier: TabViewCell.reuseIdentifier)
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
        } else {
            self.tabs.forEach { $0.isCurrent = false }
        }
    }
    
    public func viewController(at index: Int) -> UIViewController? {
        return self.tabs[index].type.viewController
    }
    
    public enum TabType {
        case agenda(UIViewController, Int)
        case captureList(UIViewController, Int)
        case search(UIViewController, Int)
        case documents(UIViewController, Int)
        case kanban(UIViewController, Int)
        case editor(UIViewController, Int)
        
        var viewController: UIViewController {
            switch self {
            case .agenda(let viewController, _): return viewController
            case .captureList(let viewController, _): return viewController
            case .search(let viewController, _): return viewController
            case .documents(let viewController, _): return viewController
            case .kanban(let viewController, _): return viewController
            case .editor(let viewController, _): return viewController
            }
        }
        
        var index: Int {
            switch self {
            case .agenda(_ , let index): return index
            case .captureList(_ , let index): return index
            case .search(_ , let index): return index
            case .documents(_ , let index): return index
            case .kanban(_, let index): return index
            case .editor(_, let index): return index
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
    }
}

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tabs.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TabViewCell.reuseIdentifier, for: indexPath) as! TabViewCell
        let tab = self.tabs[indexPath.row]
        cell.tab = tab
        
        cell.action = {
            self.selectOnTab(index: indexPath.row)
        }
        return cell
    }
}

// MARK: - TabView -

private class TabViewCell: UITableViewCell {
    static let reuseIdentifier = "TabViewCell"
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
            button.setTitleColor(theme.color.spotlight, for: .normal)
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
            imageView.tintColor = self?.isHighlighted == true ? theme.color.spotlitTitle : theme.color.spotlight
        })
        imageView.contentMode = .center
        return imageView
    }()
        
    var action: (() -> Void)?
    override var isHighlighted: Bool {
        get { return self.titleButton.isSelected }
        set {
            self.titleButton.isSelected = newValue
            self.iconView.tintColor = newValue ? InterfaceTheme.Color.spotlitTitle : InterfaceTheme.Color.spotlight
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.interface { (me, theme) in
            let tabView = me as! TabViewCell
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
            let me = view as! TabViewCell
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
