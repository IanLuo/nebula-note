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
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private var items: [Item] = []
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(stackView)
        
        stackView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInsets: .zero)
        
        self.items.forEach {
            let itemView = ItemView(item: $0)
            itemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(tap:))))

            stackView.addArrangedSubview(itemView)
        }
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
