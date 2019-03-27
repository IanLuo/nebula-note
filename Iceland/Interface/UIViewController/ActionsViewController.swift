//
//  ActionsViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class ActionsViewController: UIViewController, TransitionProtocol {
    fileprivate struct Constants {
        static let rowHeight: CGFloat = 50
        static let specialItemSeparatorHeight: CGFloat = 10
    }
    
    public enum Style {
        case `default`
        case highlight
        case warning
        
        var height: CGFloat {
            switch self {
            case .default:
                return Constants.rowHeight
            case .highlight:
                return Constants.rowHeight + Constants.specialItemSeparatorHeight
            case .warning:
                return Constants.rowHeight + Constants.specialItemSeparatorHeight
            }
        }
    }
    
    public func addAction(icon: UIImage?, title: String, style: Style = .default, action: @escaping (ActionsViewController) -> Void) {
        self.items.append(Item(icon: icon, title: title, action: action, style: style))
        
        if self.isInitialized {
            self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: UITableView.RowAnimation.none)
            UIView.animate(withDuration: 0.25, animations: {
                self.tableView.constraint(for: Position.height)?.constant = CGFloat(self.items.count) * Constants.rowHeight
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
                self.tableView.constraint(for: Position.height)?.constant = self.items.reduce(0.0, { $0 + $1.style.height })
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
    
    private let transitionDelegate = FadeBackgroundTransition(animator: MoveInAnimtor())
    
    public var fromView: UIView?
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
        self.transitioningDelegate = transitionDelegate
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        self.titleLabel.text = self.title
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    private var items: [Item] = []
    
    private var isInitialized: Bool = false
    
    private var cancelAction: ((UIViewController) -> Void)?
    
    public var accessoryView: UIView? {
        didSet {
            if let accessoryView = accessoryView {
                accessoryViewContainer.isHidden = false
                accessoryViewContainer.subviews.forEach { $0.removeFromSuperview() }
                accessoryViewContainer.addSubview(accessoryView)
                accessoryView.allSidesAnchors(to: accessoryViewContainer, edgeInset: 0)
            } else {
                accessoryViewContainer.isHidden = true
                let emptyView = UIView()
                accessoryViewContainer.addSubview(emptyView)
                emptyView.sizeAnchor(height: 0)
                emptyView.allSidesAnchors(to: accessoryViewContainer, edgeInset: 0)
            }
        }
    }
    
    private let accessoryViewContainer: UIView = {
       let view = UIView()
        return view
    }()
    
    private let actionsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background2
        return view
    }()
    
    public let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background1
        return view
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(Asset.Assets.cross.image.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.descriptive
        label.textAlignment = .left
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.separatorStyle = .none
        tableView.register(ActionCell.self, forCellReuseIdentifier: ActionCell.reuseIdentifier)
        return tableView
    }()
    
    private func setupUI() {
        self.view.addSubview(self.contentView)
        
        self.contentView.addSubview(self.tableView)
        self.contentView.addSubview(self.actionsContainerView)
        self.contentView.addSubview(self.accessoryViewContainer)
        self.contentView.addSubview(self.cancelButton)
        
        self.actionsContainerView.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInset: 0)
        self.actionsContainerView.addSubview(self.cancelButton)
        self.actionsContainerView.addSubview(self.titleLabel)
        
        self.actionsContainerView.setBorder(position: [.top, .bottom], color: InterfaceTheme.Color.background3, width: 0.5)

        self.cancelButton.sideAnchor(for: [.right, .top, .bottom], to: self.actionsContainerView, edgeInset: 0)
        self.cancelButton.sizeAnchor(width: 80, height: 80)
        self.titleLabel.sideAnchor(for: [.left, .top, .bottom], to: self.actionsContainerView, edgeInsets: .init(top: 0, left: 30, bottom: 0, right: 0))
        self.titleLabel.rowAnchor(view: self.cancelButton)
        
        self.actionsContainerView.columnAnchor(view: self.accessoryViewContainer)
        
        self.contentView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
        
        self.accessoryViewContainer.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        self.accessoryViewContainer.columnAnchor(view: self.tableView)
        
        self.tableView.sizeAnchor(height: self.items.reduce(0.0, { $0 + $1.style.height }))
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 0, considerSafeArea: true)
        
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

extension ActionsViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
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
        self.items[indexPath.row].action(self)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.items[indexPath.row].style.height
    }
}

fileprivate class ActionCell: UITableViewCell {
    fileprivate var item: ActionsViewController.Item? {
        didSet {
            self.iconView.image = item?.icon?.withRenderingMode(.alwaysTemplate)
            self.titleLabel.text = item?.title
            
            guard let item = item else { return }
            
            switch item.style {
            case .default:
                self.iconView.constraint(for: .centerY)?.constant = 0
                self.contentView.removeBorders()
                self.titleLabel.constraint(for: .top)?.constant = 0
                self.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
                self.titleLabel.textColor = InterfaceTheme.Color.interactive
            case .highlight:
                self.titleLabel.textColor = InterfaceTheme.Color.spotlight
                self.contentView.setBorder(position: .top, color: InterfaceTheme.Color.background1, width: ActionsViewController.Constants.specialItemSeparatorHeight)
                self.titleLabel.constraint(for: .top)?.constant = ActionsViewController.Constants.specialItemSeparatorHeight / 2
                self.titleLabel.constraint(for: .bottom)?.constant = -ActionsViewController.Constants.specialItemSeparatorHeight / 2
                self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            case .warning:
                self.titleLabel.textColor = InterfaceTheme.Color.warning
                self.contentView.setBorder(position: .top, color: InterfaceTheme.Color.background1, width: ActionsViewController.Constants.specialItemSeparatorHeight)
                self.titleLabel.constraint(for: .top)?.constant = ActionsViewController.Constants.specialItemSeparatorHeight / 2
                self.titleLabel.constraint(for: .bottom)?.constant = -ActionsViewController.Constants.specialItemSeparatorHeight / 2
                self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
        }
    }
    
    static let reuseIdentifier = "ActionCell"
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.tintColor = InterfaceTheme.Color.descriptive
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.body
        label.textColor = InterfaceTheme.Color.interactive
        label.textAlignment = .left
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = InterfaceTheme.Color.background2
        
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.titleLabel)
        
        self.titleLabel.sideAnchor(for: [.top, .bottom, .left, .bottom], to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: 0))
        self.titleLabel.sizeAnchor(height: ActionsViewController.Constants.rowHeight)
        self.titleLabel.rowAnchor(view: self.iconView)
        
        self.titleLabel.rowAnchor(view: self.iconView)
        self.iconView.sideAnchor(for: .right, to: self.contentView, edgeInset: Layout.edgeInsets.right)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = InterfaceTheme.Color.background3
        } else {
            self.backgroundColor = InterfaceTheme.Color.background2
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.backgroundColor = InterfaceTheme.Color.background3
        } else {
            self.backgroundColor = InterfaceTheme.Color.background2
        }
    }
}