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
    public func addAction(icon: UIImage?, title: String, action: @escaping () -> Void) {
        self.items.append(Item(icon: icon, title: title, action: action))
        
        if self.isInitialized {
            if let last = self.items.last {
                let itemView = ItemView(item: last)
                itemView.tag = self.items.count - 1
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
                accessoryViewContainer.addSubview(accessoryView)
            }
        }
    }
    
    private let accessoryViewContainer: UIView = UIView()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    
    private func setupUI() {
        self.accessoryViewContainer.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(stackView)
        self.view.addSubview(self.accessoryViewContainer)

        self.accessoryViewContainer.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.accessoryViewContainer.sideAnchor(for: .bottom, to: self.stackView, edgeInset: 1)
        
        self.stackView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInsets: .zero)
        
        for (index, item) in self.items.enumerated() {
            let itemView = ItemView(item: item)
            itemView.tag = index
            itemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(tap:))))
            self.stackView.addArrangedSubview(itemView)
        }
        
        // 点击屏幕其他位置，则关闭
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.isInitialized = true
    }
    
    @objc func cancel() {
        self.cancelAction?(self)
    }
    
    @objc func tapped(tap: UITapGestureRecognizer) {
        if let view = tap.view {
            for (index, item) in self.items.enumerated() {
                if index == view.tag {
                    self.dismiss(animated: true) {
                        item.action()
                    }
                }
            }
        }
    }
    
    private struct Item {
        let icon: UIImage?
        let title: String
        let action: () -> Void
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
            
            self.iconView.sideAnchor(for: .left, to: self, edgeInsets: .init(top: 0, left: 10, bottom: 0, right: 0))
            self.iconView.centerAnchors(position: .centerY, to: self)
            
            self.titleLabel.sideAnchor(for: .left, to: self.iconView, edgeInsets: .init(top: 0, left: 10, bottom: 0, right: 0))
            self.titleLabel.sideAnchor(for: .right, to: self.iconView, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: 10))
            self.titleLabel.centerAnchors(position: .centerY, to: self)
            
            self.backgroundColor = InterfaceTheme.Color.background2
            self.setBorder(position: .bottom, color: InterfaceTheme.Color.background3, width: 1)
            
            self.translatesAutoresizingMaskIntoConstraints = false
            self.sizeAnchor(height: 60)
        }
    }
}

extension ActionsViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
    }
}
