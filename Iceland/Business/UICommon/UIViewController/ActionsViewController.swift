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
    public func addAction(icon: UIImage?, title: String, action: @escaping (ActionsViewController) -> Void) {
        self.items.append(Item(icon: icon, title: title, action: action))
        
        if self.isInitialized {
            if let last = self.items.last {
                let itemView = ItemView(item: last)
                itemView.tag = self.items.count - 1
                itemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(tap:))))
                self.stackView.addArrangedSubview(itemView)
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
            for (i, view) in self.stackView.arrangedSubviews.enumerated() {
                if index == i {
                    self.stackView.removeArrangedSubview(view)
                    view.removeFromSuperview()
                }
            }
        }
    }
    
    public func addCancel(action: @escaping (UIViewController) -> Void) {
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
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    private func setupUI() {
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.accessoryViewContainer.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.contentView)
        
        self.contentView.addSubview(self.stackView)
        self.contentView.addSubview(self.accessoryViewContainer)
        self.contentView.addSubview(self.cancelButton)
        
        self.contentView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
        
        self.cancelButton.sideAnchor(for: [.top, .right], to: self.contentView, edgeInset: 0)
        self.cancelButton.columnAnchor(view: self.accessoryViewContainer, space: 10)
        self.cancelButton.sizeAnchor(width: 44, height: 44)
        
        self.accessoryViewContainer.sideAnchor(for: [.left, .right], to: self.contentView, edgeInset: 0)
        self.accessoryViewContainer.columnAnchor(view: self.stackView)
        
        self.stackView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 0, left: 0, bottom: -20, right: 0))
        
        for item in self.items {
            let itemView = ItemView(item: item)
            itemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(tap:))))
            self.stackView.addArrangedSubview(itemView)
        }
        
        self.isInitialized = true
    }
    
    @objc func cancel() {
        self.cancelAction?(self)
    }
    
    @objc func tapped(tap: UITapGestureRecognizer) {
        
        if let view = tap.view {
            for (index, v) in self.stackView.arrangedSubviews.enumerated() {
                if view == v {
                    self.items[index].action(self)
                }
            }
        }
    }
    
    private struct Item {
        let icon: UIImage?
        let title: String
        let action: (ActionsViewController) -> Void
    }
    
    private class ItemView: UIView {
        convenience init(item: Item) {
            self.init(frame: .zero)
            self.item = item
            self.setupUI()
        }
        
        private var item: Item!
        private let iconView: UIImageView = {
            let iv = UIImageView()
            iv.tintColor = InterfaceTheme.Color.descriptive
            return iv
        }()
        private let titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = InterfaceTheme.Color.interactive
            label.font = InterfaceTheme.Font.subTitle
            return label
        }()
        
        private func setupUI() {
            self.addSubview(self.iconView)
            self.addSubview(self.titleLabel)
            
            self.iconView.translatesAutoresizingMaskIntoConstraints = false
            self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            if let icon = item.icon {
                self.iconView.image = icon
            } else {
                self.iconView.isHidden = true
            }
            
            self.titleLabel.text = item.title
            
            self.iconView.sideAnchor(for: .left, to: self, edgeInset: 30)
            self.iconView.centerAnchors(position: .centerY, to: self)
            
            self.titleLabel.centerAnchors(position: [.centerY, .centerX], to: self)
            
            self.backgroundColor = InterfaceTheme.Color.background2
            
            self.translatesAutoresizingMaskIntoConstraints = false
            self.sizeAnchor(height: 60)
        }
    }
}
