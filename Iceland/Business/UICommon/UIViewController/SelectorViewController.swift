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
    public var rowHeight: CGFloat = 60
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.register(ActionCell.self, forCellReuseIdentifier: ActionCell.reuseIdentifier)
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    public var emptyDataText: String = "It's empty".localizable
    
    public var emptyDataIcon: UIImage?
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.items.count == 0 && self.tableView.bounds.size != .zero {
            self.showEmptyDataView()
        } else {
            self.hideEmptyDataView()
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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
    
    public func addItem(icon: UIImage? = nil, title: String, description: String? = nil) {
        let item = Item(icon: icon, title: title, attributedString: nil, description: description)
        self.items.append(item)
        self.insertNewItemToTableIfNeeded(newItem: item)
    }
    
    public func addItem(icon: UIImage? = nil, attributedString: NSAttributedString, description: String? = nil) {
        let item = Item(icon: icon, title: "", attributedString: attributedString, description: description)
        self.items.append(item)
        self.insertNewItemToTableIfNeeded(newItem: item)
    }
    
    private func insertNewItemToTableIfNeeded(newItem: Item) {
        // 已经显示，则需要插入
        if self.tableView.window != nil {
            self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: UITableView.RowAnimation.none)
            
            self.hideEmptyDataView()
        }
    }
    
    // transite delegate will access this
    public var transiteFromView: UIView?
    public func show(from: UIView?, on viewController: UIViewController) {
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
        self.transiteFromView = from

        viewController.present(self, animated: true)
    }
    
    private func setupUI() {
        self.view.addSubview(self.tableView)
        
        self.tableView.sizeAnchor(height: self.view.bounds.height / 2)
        self.tableView.sideAnchor(for: .left, to: self.view, edgeInset: 30)
        self.tableView.centerAnchors(position: [.centerX, .centerY], to: self.view)
    }
    
    @objc private func cancel() {
        self.delegate?.SelectorDidCancel(viewController: self)
    }
    
    public struct Item {
        let icon: UIImage?
        let title: String
        let attributedString: NSAttributedString?
        let description: String?
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
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        cell.setSelected(item.title == self.currentTitle, animated: false)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.delegate?.SelectorDidSelect(index: indexPath.row, viewController: self)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.rowHeight
    }
    
    private func showEmptyDataView() {
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
            label.centerAnchors(position: [.centerX, .centerY], to: emptyDataView)
            label.sideAnchor(for: [.left, .right], to: emptyDataView, edgeInset: 30)
        }
        
        self.tableView.tableFooterView = emptyDataView
    }
    
    private func hideEmptyDataView() {
        if self.tableView.tableFooterView?.bounds.size != .zero {
            self.tableView.tableFooterView = UIView()
        }
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
        if let icon = image {
            self.iconView.image = icon
            self.iconView.isHidden = false
        } else {
            self.iconView.isHidden = true
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = InterfaceTheme.Color.background2
        self.separatorInset = .zero
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
        
        self.titleLabel.centerAnchors(position: [.centerY], to: self.contentView)
        
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


extension SelectorViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator(isPresenting: false)
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator()
    }
}

private class Animator: NSObject, UIViewControllerAnimatedTransitioning {
    public var isPresenting: Bool
    
    public init(isPresenting: Bool = true) {
        self.isPresenting = isPresenting
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containner = transitionContext.containerView
        guard let to = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        guard let from = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else { return }
        
        
        if self.isPresenting {
            if let selectorViewcontroller = to as? SelectorViewController {
                let fromView = selectorViewcontroller.transiteFromView
                
                containner.addSubview(to.view)
                selectorViewcontroller.tableView.alpha = 0
                selectorViewcontroller.view.backgroundColor = UIColor.black.withAlphaComponent(0)
                let bounds = from.view.bounds
                let destRect = transitionContext.finalFrame(for: to).inset(by: UIEdgeInsets(top: bounds.height / 4, left: 30, bottom: bounds.height / 4, right: 30))
                // 如果没有设置显示位置的 UIView，使用屏幕正中心的点作为显示位置
                let startRect = fromView != nil ? fromView!.superview!.convert(fromView!.frame, to: from.view) : CGRect(origin: selectorViewcontroller.view.center, size: .zero)
                let animatableView = UIImageView(frame: startRect)
                animatableView.backgroundColor = InterfaceTheme.Color.background2
                animatableView.clipsToBounds = true
                animatableView.alpha = 0
                
                containner.addSubview(animatableView)
                
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0.0, options: .curveEaseOut, animations: ({
                    animatableView.frame = destRect
                    animatableView.alpha = 1
                    selectorViewcontroller.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                }), completion: { completeion in
                    selectorViewcontroller.tableView.alpha = 1
                    animatableView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        } else {
            if let selectorViewcontroller = from as? SelectorViewController {
                let toView = selectorViewcontroller.transiteFromView
                guard let fromImage = selectorViewcontroller.tableView.snapshot else { return }
                
                selectorViewcontroller.tableView.alpha = 0
                let bounds = from.view.bounds
                let startRect = transitionContext.finalFrame(for: to).inset(by: UIEdgeInsets(top: bounds.height / 4, left: 30, bottom: bounds.height / 4, right: 30))
                // 如果没有设置显示位置的 UIView，使用屏幕正中心的点作为显示位置
                let destRect = toView != nil ? toView!.superview!.convert(toView!.frame, to: from.view) : CGRect(origin: selectorViewcontroller.view.center, size: .zero)
                let animatableView = UIImageView(frame: startRect)
                animatableView.backgroundColor = InterfaceTheme.Color.background2
                animatableView.clipsToBounds = true
                animatableView.image = fromImage
                
                containner.addSubview(animatableView)
                
                UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveEaseIn, animations: ({
                    animatableView.frame = destRect
                    animatableView.alpha = 0
                    selectorViewcontroller.view.backgroundColor = UIColor.black.withAlphaComponent(0)
                }), completion: { completeion in
                    animatableView.removeFromSuperview()
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                })
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
    }
}
