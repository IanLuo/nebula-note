//
//  SelectorViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public class SelectorViewController: UIViewController {
    private var cancelAction: ((SelectorViewController) -> Void)?
    private var selectAction: ((Int, SelectorViewController) -> Void)?
    
    public func addCancel(action: @escaping (SelectorViewController) -> Void) {
        self.cancelAction = action
    }
    
    public func addSelect(action: @escaping (Int, SelectorViewController) -> Void) {
        self.selectAction = action
    }
    
    public func addItem(icon: UIImage? = nil, title: String, description: String? = nil) {
        self.items.append(Item(icon: icon, title: title, description: description))
    }
    
    public var items: [Item] = []
    
    public var selectedItems: [Int] = []
    
    public func show(from: UIView, on viewController: UIViewController) {
        // TODO: show
    }
    
    public func hide() {
        // TODO: hide
    }
    
    public struct Item {
        let icon: UIImage?
        let title: String
        let description: String?
    }
    
    public class ItemView: UIView {
        private let iconView: UIImageView = {
            let imageView = UIImageView()
            return imageView
        }()
        
        private let titleLabel: UILabel = {
            let label = UILabel()
            label.font = InterfaceTheme.Font.body
            label.textColor = InterfaceTheme.Color.interactive
            return label
        }()
        
        private let descriptionLabel: UILabel = {
            let label = UILabel()
            label.font = InterfaceTheme.Font.body
            label.textColor = InterfaceTheme.Color.descriptive
            return label
        }()
        
        fileprivate init(item: Item) {
            super.init(frame: .zero)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
