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
        static let specialItemSeparatorHeight: CGFloat = 0.5
        static let titleHeight: CGFloat = 60
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
    
    public func addAction(icon: UIImage?, title: String, style: Style = .default, at: Int? = nil, action: @escaping (ActionsViewController) -> Void) {
        
        if let at = at {
            self.items.insert(Item(icon: icon, title: title, action: action, style: style), at: at)
        } else {
            self.items.append(Item(icon: icon, title: title, action: action, style: style))
        }
        
        if self.isInitialized {
            self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: UITableView.RowAnimation.none)
            UIView.animate(withDuration: 0.25, animations: {
                self.tableView.constraint(for: Position.height)?.constant = self.items.reduce(0.0, { $0 + $1.style.height })
                self.view.layoutIfNeeded()
            })
        }
    }
    
    public func addActionAutoDismiss(icon: UIImage?, title: String, style: Style = .default, at: Int? = nil, action: @escaping () -> Void) {
        self.addAction(icon: icon, title: title) { viewController in
            viewController.dismiss(animated: true) {
                action()
            }
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
    
    public var fromView: UIView? {
        didSet {
            if isMacOrPad {
                self.popoverPresentationController?.sourceView = fromView
                
                if let fromView = fromView {
                    self.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: fromView.frame.midX, y: fromView.frame.midY), size: .zero)
                }
            }
        }
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        
        if isMacOrPad {
            self.modalPresentationStyle = UIModalPresentationStyle.popover
        } else {
            self.modalPresentationStyle = .overCurrentContext
            self.transitioningDelegate = transitionDelegate
        }
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
        
        self.cancelButton.tapped { [weak self] _ in
            self?.cancel()
        }
        
        if isMacOrPad {
            if self.fromView == nil {
                self.popoverPresentationController?.sourceView = self.view
                self.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 0, height: 0)
            }
            let size = self.view.systemLayoutSizeFitting(CGSize(width: self.view.bounds.width, height: 0))
            self.preferredContentSize = CGSize(width: 300, height: size.height)
        }
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
                accessoryView.setBorder(position: Border.Position.bottom, color: InterfaceTheme.Color.background3, width: 0.5)
                
                accessoryViewContainer.constraint(for: Position.height)?.isActive = false
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
        
        if isMacOrPad {
            view.backgroundColor = .clear
        }
        
        view.setBorder(position: Border.Position.bottom, color: InterfaceTheme.Color.background3, width: 0.5)
        return view
    }()
    
    public let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background2
        
        if isMacOrPad {
            view.backgroundColor = .clear
        }

        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let cancelButton: RoundButton = {
        let button = RoundButton()
        button.setBorder(color: nil)
        button.setIcon(Asset.Assets.cross.image.resize(upto: CGSize(width: 10, height: 10)).fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background3, for: .normal)
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

        if isMacOrPad {
            tableView.backgroundColor = .clear
        }

        tableView.separatorStyle = .singleLine
        tableView.separatorColor = InterfaceTheme.Color.background3
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
        self.actionsContainerView.sizeAnchor(height: 44)
        
        self.cancelButton.sideAnchor(for: .right, to: self.actionsContainerView, edgeInsets: .init(top: 10, left: 0, bottom: -10, right: -Layout.edgeInsets.right + 7)) // make it align to the icon
        self.cancelButton.sizeAnchor(width: 30)
        self.titleLabel.sideAnchor(for: [.left, .top, .bottom], to: self.actionsContainerView, edgeInsets: .init(top: 10, left: Layout.edgeInsets.left, bottom: -10, right: 0))
        self.titleLabel.rowAnchor(view: self.cancelButton)
        self.titleLabel.centerYAnchor.constraint(equalTo: self.cancelButton.centerYAnchor).isActive = true
        
        self.contentView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 10, considerSafeArea: true)
        self.contentView.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
//        self.contentView.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        
        self.actionsContainerView.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInset: 0)
        self.actionsContainerView.columnAnchor(view: self.accessoryViewContainer)
        
        if self.accessoryView == nil {
            self.accessoryViewContainer.sizeAnchor(height: 0)
        }
        self.accessoryViewContainer.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        self.accessoryViewContainer.columnAnchor(view: self.tableView)
        
        self.tableView.sizeAnchor(height: self.items.reduce(0.0, { $0 + $1.style.height }))
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 0)
        
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
            self.iconView.image = item?.icon
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
                self.contentView.setBorder(position: .top, color: InterfaceTheme.Color.background3, width: ActionsViewController.Constants.specialItemSeparatorHeight, insets: .both(20))
                self.titleLabel.constraint(for: .top)?.constant = ActionsViewController.Constants.specialItemSeparatorHeight / 2
                self.titleLabel.constraint(for: .bottom)?.constant = -ActionsViewController.Constants.specialItemSeparatorHeight / 2
                self.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            case .warning:
                self.titleLabel.textColor = InterfaceTheme.Color.warning
                self.contentView.setBorder(position: .top, color: InterfaceTheme.Color.background3, width: ActionsViewController.Constants.specialItemSeparatorHeight, insets: .both(20))
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
        #if targetEnvironment(macCatalyst)
        self.backgroundColor = .clear
        #endif
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.titleLabel)
        
        self.titleLabel.sideAnchor(for: [.top, .bottom, .left, .bottom], to: self.contentView, edgeInsets: .init(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: 0))
        self.titleLabel.sizeAnchor(height: ActionsViewController.Constants.rowHeight)
        self.titleLabel.rowAnchor(view: self.iconView)
        
        self.iconView.sizeAnchor(width: 44)
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
            #if targetEnvironment(macCatalyst)
            self.backgroundColor = .clear
            #endif
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected {
            self.backgroundColor = InterfaceTheme.Color.background3
        } else {
            self.backgroundColor = InterfaceTheme.Color.background2
            #if targetEnvironment(macCatalyst)
            self.backgroundColor = .clear
            #endif
        }
    }
}
