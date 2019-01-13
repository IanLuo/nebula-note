//
//  ModalFormViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/13.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol ModalFormViewControllerDelegate: class {
    func ModalFormDidCancel(viewController: ModalFormViewController)
    func ModalFormDidSave(viewController: ModalFormViewController)
}

public class ModalFormViewController: UIViewController {
    public enum InputType {
        case text(String, String, String?)
    }
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton()
        return button
    }()
    
    public var items: [InputType] = []
    
    public weak var delegate: ModalFormViewControllerDelegate?
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.separatorColor = InterfaceTheme.Color.background1
        tableView.register(InputTextCell.self, forCellReuseIdentifier: InputTextCell.reuseIdentifier)
        return tableView
    }()
    
    public func addTextFied(title: String, placeHoder: String, defaultValue: String?) {
        self.items.append(InputType.text(title, placeHoder, defaultValue))
    }
    
    @objc private func cancel() {
        
    }
    
    @objc private func save() {
        
    }
}

extension ModalFormViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.row]
        
        switch item {
        case .text:
            let cell = tableView.dequeueReusableCell(withIdentifier: InputTextCell.reuseIdentifier, for: indexPath) as! InputTextCell
            cell.item = item
            return cell
        }
    }
}

private class InputTextCell: UITableViewCell {
    fileprivate static let reuseIdentifier = "InputTextCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textAlignment = .left
        label.textColor = InterfaceTheme.Color.descriptive
        return label
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.font = InterfaceTheme.Font.body
        textField.textColor = InterfaceTheme.Color.interactive
        return textField
    }()
    
    fileprivate var item: ModalFormViewController.InputType? {
        didSet {
            guard let item = item else { return }
            self.updateUI(item)
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textField)
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInset: 10)
        self.titleLabel.sizeAnchor(height: 60)
        self.titleLabel.columnAnchor(view: self.textField)
        self.textField.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 10)
        self.textField.sizeAnchor(height: 60)
    }
    
    private func updateUI(_ item: ModalFormViewController.InputType) {
        switch item {
        case let .text(title, placeholder, value):
            self.titleLabel.text = title
            self.textField.placeholder = placeholder
            self.textField.text = value
        default: break
        }
    }
}
