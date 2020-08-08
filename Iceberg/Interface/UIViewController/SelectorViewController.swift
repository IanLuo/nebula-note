//
//  SelectorViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol SelectorViewControllerDelegate: class {
    func SelectorDidCancel(viewController: SelectorViewController)
    func SelectorDidSelect(index: Int, viewController: SelectorViewController)
}

open class SelectorViewController: UIViewController {
    
    public var onSelection:((Int, SelectorViewController) -> Void)?
    public var onCancel: ((SelectorViewController) -> Void)?
    
    public let heightRatio: CGFloat
    
    public init(heightRatio: CGFloat = 1/2) {
        self.heightRatio = heightRatio
        super.init(nibName: nil, bundle: nil)
        
        // custom transition only add to iPhone
        if isMacOrPad {
            self.modalPresentationStyle = UIModalPresentationStyle.popover
        } else {
            self.modalPresentationStyle = .custom
            self.transitioningDelegate = self.transitionDelegate
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.register(ActionCell.self, forCellReuseIdentifier: ActionCell.reuseIdentifier)
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.descriptive
        label.textAlignment = .center

        label.backgroundColor = InterfaceTheme.Color.background2
        return label
    }()
    
    public let contentView: UIView = {
        let view = UIView()
        
        if !isMacOrPad {
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
        }
        return view
    }()
    
    private lazy var closeButton: RoundButton = {
        let button = RoundButton()
        button.setIcon(Asset.Assets.cross.image.resize(upto: CGSize(width: 10, height: 10)).fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background3, for: .normal)
        button.tapped { [weak self] _ in
            self?.cancel()
        }
        return button
    }()
    
    public var emptyDataText: String = L10n.Selector.empty
    
    public var emptyDataIcon: UIImage?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.titleLabel.text = self.title
        
        if isMacOrPad {
            if self.fromView == nil {
                self.popoverPresentationController?.sourceView = self.view
                self.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 0, height: 0)
            }
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.preferredContentSize = CGSize(width: 300, height: self.contentView.bounds.height)
    }
    
    public func scrollToDefaultValue() {
        var selectedIndex: Int? = nil
        for (index, item) in self.items.enumerated() {
            if item.title == self.currentTitle {
                selectedIndex = index
                break
            }
        }
        
        if let selectedIndex = selectedIndex {
            let indexPath = IndexPath(row: selectedIndex, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: false)
        }
    }
    
    public var items: [Item] = []
    public var currentTitle: String?
    public var selectedTitles: [String] = []
    public weak var delegate: SelectorViewControllerDelegate?
    public var name: String?
    
    private let transitionDelegate = FadeBackgroundTransition(animator: MoveToAnimtor())
    
    public func addItem(icon: UIImage? = nil, title: String, description: String? = nil, enabled: Bool = true) {
        let item = Item(icon: icon, title: title, attributedString: nil, description: description, enabled: enabled)
        self.items.append(item)
        self.insertNewItemToTableIfNeeded(newItem: item)
    }
    
    public func addItem(icon: UIImage? = nil, attributedString: NSAttributedString, description: String? = nil, enabled: Bool = true) {
        let item = Item(icon: icon, title: "", attributedString: attributedString, description: description, enabled: enabled)
        self.items.append(item)
        self.insertNewItemToTableIfNeeded(newItem: item)
    }
    
    private func insertNewItemToTableIfNeeded(newItem: Item) {
        // 已经显示，则需要插入
        if self.tableView.window != nil {
            self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: UITableView.RowAnimation.none)
        }
    }
    
    // transite delegate will access this
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

    private func setupUI() {
        self.view.addSubview(self.contentView)
        self.contentView.addSubview(self.tableView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.closeButton)
        
        let insets: CGFloat = isMacOrPad ? 0 : 30
        self.contentView.sideAnchor(for: [.left, .right], to: self.view, edgeInset: insets)
        
        if isMacOrPad {
            self.contentView.sizeAnchor(height: self.view.bounds.height)
            self.contentView.sideAnchor(for: [.top, .bottom], to: self.view, edgeInset: 0)
        } else {
            self.contentView.centerAnchors(position: .centerY, to: self.view)
            self.contentView.sizeAnchor(height: self.view.bounds.height * heightRatio)
        }
        
        self.titleLabel.sizeAnchor(height: 60)
        self.titleLabel.sideAnchor(for: [.left, .right, .top], to: self.contentView, edgeInset: 0)
        self.titleLabel.setBorder(position: .bottom, color: InterfaceTheme.Color.background3, width: 0.5)
        
        self.closeButton.sizeAnchor(width: 30)
        self.closeButton.sideAnchor(for: [.right], to: self.contentView, edgeInset: 20)
        self.closeButton.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor).isActive = true
        
        if isMacOrPad {
            self.closeButton.isHidden = true
        }
        
        self.titleLabel.columnAnchor(view: self.tableView, space: 0)
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 0)
    }
    
    @objc private func cancel() {
        self.delegate?.SelectorDidCancel(viewController: self)
        
        unowned let unownedSelf = self
        self.onCancel?(unownedSelf)
    }
    
    public struct Item {
        public let icon: UIImage?
        public let title: String
        public let attributedString: NSAttributedString?
        public let description: String?
        public let enabled: Bool
    }
}

extension SelectorViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActionCell.reuseIdentifier, for: indexPath) as! ActionCell
        
        let item = self.items[indexPath.row]
        cell.descriptionLabel.text = item.description
        cell.titleLabel.text = item.title
        if let attr = item.attributedString {
            cell.titleLabel.attributedText = attr
        }
        cell.setIcon(image: item.icon)
        
        cell.contentView.subviews.forEach {
            $0.alpha = item.enabled ? 1 : 0.5
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        cell.setSelected(item.title == self.currentTitle, animated: false)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard self.items[indexPath.row].enabled else { return }
        
        self.delegate?.SelectorDidSelect(index: indexPath.row, viewController: self)
        
        unowned let unownedSelf = self
        self.onSelection?(indexPath.row, unownedSelf)
    }
    
    public func showEmptyDataView() {
        let emptyDataView = UIView(frame: self.tableView.bounds)
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.descriptive
        label.text = self.emptyDataText
        label.textAlignment = .center
        label.numberOfLines = 0

        if let icon = self.emptyDataIcon {
            let container = UIView()
            emptyDataView.addSubview(container)
            container.centerAnchors(position: [.centerX, .centerY], to: emptyDataView)
            
            let imageView = UIImageView(image: icon)
            container.addSubview(imageView)
            container.addSubview(label)
            
            imageView.sideAnchor(for: [.left, .top, .right], to: container, edgeInset: 0)
            imageView.columnAnchor(view: label, space: 20)
            label.sideAnchor(for: [.left, .bottom, .right], to: container, edgeInset: 0)
            label.sideAnchor(for: [.left, .right], to: container, edgeInset: 30)
        } else {
            emptyDataView.addSubview(label)
            label.allSidesAnchors(to: emptyDataView, edgeInset: 30)
        }
        
        self.tableView.tableFooterView = emptyDataView
    }
    
    public func hideEmptyDataView() {
        if self.tableView.tableFooterView?.bounds.size != .zero {
            self.tableView.tableFooterView = UIView()
        }
    }
}

extension SelectorViewController: TransitionProtocol {
    public func didTransiteToShow() {
        self.scrollToDefaultValue()
    }
}

extension SelectorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}

fileprivate class ActionCell: UITableViewCell {
    static let reuseIdentifier = "ActionCell"
    
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.numberOfLines = 0
        label.textColor = InterfaceTheme.Color.interactive
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.interactive
        return label
    }()
    
    func setIcon(image: UIImage?) {
        self.iconView.image = image
        
        if image != nil {
            self.iconView.sizeAnchor(width: 30, height: 30)
        } else {
            self.iconView.sizeAnchor(width: 0, height: 0)
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = InterfaceTheme.Color.background2
        self.selectedBackgroundView?.isHidden = true
        
        self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.iconView.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(self.descriptionLabel)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.iconView)
        
        self.iconView.sideAnchor(for: .left, to: self.contentView, edgeInset: 20)
        self.iconView.centerAnchors(position: .centerY, to: self.contentView)
        self.iconView.rowAnchor(view: self.titleLabel, space: 20)
        self.iconView.ratioAnchor(1)
        
        self.titleLabel.sideAnchor(for: [.top, .right, .bottom], to: self.contentView, edgeInset: 20)
        self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.contentView.leadingAnchor, constant: 20).isActive = true
        
        self.descriptionLabel.sideAnchor(for: .right, to: self.contentView, edgeInset: 20)
        self.descriptionLabel.centerAnchors(position: .centerY, to: self.contentView)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = InterfaceTheme.Color.background3
        } else {
            self.backgroundColor = InterfaceTheme.Color.background2
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            self.backgroundColor = InterfaceTheme.Color.background3
        } else {
            self.backgroundColor = InterfaceTheme.Color.background2
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

