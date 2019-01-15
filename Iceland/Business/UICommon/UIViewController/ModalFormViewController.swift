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
    func modalFormDidCancel(viewController: ModalFormViewController)
    func modalFormDidSave(viewController: ModalFormViewController, formData: [String: Codable])
}

public class ModalFormViewController: UIViewController {
    public enum InputType {
        case textField(String, String, String?)
        case textView(String, String?)
    }
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.setTitle("✕", for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("✓", for: .normal)
        button.addTarget(self, action: #selector(save), for: .touchUpInside)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        return button
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.title
        label.textColor = InterfaceTheme.Color.descriptive
        label.textAlignment = .center
        return label
    }()
    
    public var items: [InputType] = []
    
    private var formData: [String: Codable] = [:]
    
    public weak var delegate: ModalFormViewControllerDelegate?
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.allowsSelection = false
        tableView.separatorInset = .zero
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.backgroundColor = InterfaceTheme.Color.background2
        tableView.register(InputTextFieldCell.self, forCellReuseIdentifier: InputTextFieldCell.reuseIdentifier)
        tableView.register(InputTextViewCell.self, forCellReuseIdentifier: InputTextViewCell.reuseIdentifier)
        return tableView
    }()
    
    private let actionButtonsContainer:UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background2
        return view
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide), name: UIApplication.keyboardWillHideNotification, object: nil)
        
        self.titleLabel.text = self.title
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        self.view.addSubview(self.actionButtonsContainer)
        
        self.actionButtonsContainer.addSubview(self.saveButton)
        self.actionButtonsContainer.addSubview(self.cancelButton)
        self.actionButtonsContainer.addSubview(self.titleLabel)
        
        // 此时添加 border 才不会被按钮覆盖
        self.actionButtonsContainer.setBorder(position: .bottom, color: InterfaceTheme.Color.background3, width: 2)
        
        self.actionButtonsContainer.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        
        self.saveButton.sideAnchor(for: [.left, .top, .bottom], to: actionButtonsContainer, edgeInset: 0)
        self.saveButton.sizeAnchor(width: 60, height: 60)
        self.titleLabel.sideAnchor(for: [.top, .bottom], to: actionButtonsContainer, edgeInset: 0)
        self.saveButton.rowAnchor(view: self.titleLabel)
        self.cancelButton.sideAnchor(for: [.right, .top, .bottom], to: actionButtonsContainer, edgeInset: 0)
        self.cancelButton.sizeAnchor(width: 60, height: 60)
        self.titleLabel.rowAnchor(view: self.cancelButton)
        
        self.view.addSubview(self.tableView)
        actionButtonsContainer.columnAnchor(view: self.tableView)
        
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
        self.tableView.sizeAnchor(height: self.tabelHeight)
    }
    
    private var tabelHeight: CGFloat {
        var height: CGFloat = 0
        self.items.forEach {
            switch $0 {
            case .textField:
                height += InputTextFieldCell.height
            case .textView:
                height += InputTextViewCell.height
            }
        }
        
        return height
    }
    
    public func show(from: UIViewController, animated: Bool) {
        if animated {
            self.tableView.constraint(for: .bottom)?.constant = self.tabelHeight
            from.present(self, animated: false) {
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                    self.tableView.constraint(for: .bottom)?.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        } else {
            from.present(self, animated: false, completion: nil)
        }
    }
    
    public func addTextFied(title: String, placeHoder: String, defaultValue: String?) {
        self.items.append(InputType.textField(title, placeHoder, defaultValue))
    }
    
    public func addTextView(title: String, defaultValue: String?) {
        self.items.append(InputType.textView(title, defaultValue))
    }
    
    @objc private func keyBoardWillShow(notification: Notification) {
        if let rect = notification.userInfo?[UIApplication.keyboardFrameEndUserInfoKey] as? CGRect {
            let height = rect.height
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
                var adjustment: CGFloat = 0
                if #available(iOS 11.0, *) {
                    adjustment += self.view.safeAreaInsets.bottom
                }
                self.tableView.constraint(for: .bottom)?.constant = -height + adjustment
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    @objc private func keyBoardWillHide(notification: Notification) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.tableView.constraint(for: .bottom)?.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func cancel() {
        self.tableView.endEditing(true)
        self.delegate?.modalFormDidCancel(viewController: self)
    }
    
    @objc private func save() {
        self.tableView.endEditing(true)
        self.delegate?.modalFormDidSave(viewController: self, formData: self.formData)
    }
}

extension ModalFormViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.row]
        
        switch item {
        case .textField:
            let cell = tableView.dequeueReusableCell(withIdentifier: InputTextFieldCell.reuseIdentifier, for: indexPath) as! InputTextFieldCell
            cell.item = item
            cell.delegate = self
            return cell
        case .textView:
            let cell = tableView.dequeueReusableCell(withIdentifier: InputTextViewCell.reuseIdentifier, for: indexPath) as! InputTextViewCell
            cell.item = item
            cell.delegate = self
            return cell
        }
    }
}

fileprivate protocol CellValueDelegate: class {
    func didSetValue(title: String, value: Codable)
}

extension ModalFormViewController: CellValueDelegate {
    func didSetValue(title: String, value: Codable) {
        self.formData[title] = value
    }
}

//
// MARK: - cells
//

// MARK: - InputTextViewCell
private class InputTextViewCell: UITableViewCell, UITextViewDelegate {
    fileprivate static let reuseIdentifier = "InputTextViewCell"
    fileprivate static let height: CGFloat = 150
    
    weak var delegate: CellValueDelegate?
    
    fileprivate var item: ModalFormViewController.InputType? {
        didSet {
            guard let item = item else { return }
            self.updateUI(item)
        }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.footnote
        label.textColor = InterfaceTheme.Color.enphersizedDescriptive
        return label
    }()
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = InterfaceTheme.Font.body
        textView.textColor = InterfaceTheme.Color.interactive
        textView.backgroundColor = InterfaceTheme.Color.background2
        return textView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background2
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textView)
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInset: 10)
        self.titleLabel.columnAnchor(view: self.textView)
        self.textView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 10)
        
        self.titleLabel.sizeAnchor(height: 30)
        self.textView.sizeAnchor(height: 100)
    }
    
    private func updateUI(_ item: ModalFormViewController.InputType) {
        switch item {
        case let .textView(title, defaultValue):
            self.titleLabel.text = title
            self.textView.text = defaultValue
        default: break
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.didSetValue(title: self.titleLabel.text ?? "", value: textView.text)
    }
}

// MARK: - InputTextFieldCell
private class InputTextFieldCell: UITableViewCell, UITextFieldDelegate {
    fileprivate static let reuseIdentifier = "InputTextFieldCell"
    fileprivate static let height: CGFloat = 130
    
    weak var delegate: CellValueDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        label.textColor = InterfaceTheme.Color.enphersizedDescriptive
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
        
        self.textField.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let title = self.titleLabel.text,
            let value = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) {
            self.delegate?.didSetValue(title: title, value: value)
        }
        return true
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background2
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textField)
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInset: 10)
        self.titleLabel.sizeAnchor(height: 30)
        self.titleLabel.columnAnchor(view: self.textField)
        self.textField.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 10)
        self.textField.sizeAnchor(height: 60)
    }
    
    private func updateUI(_ item: ModalFormViewController.InputType) {
        switch item {
        case let .textField(title, placeholder, value):
            self.titleLabel.text = title
            self.textField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                      attributes: [NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive])
            self.textField.text = value
        default: break
        }
    }
}

extension Encodable {
    public func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}

extension JSONEncoder {
    public struct EncodableWrapper: Encodable {
        let wrapped: Encodable
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try self.wrapped.encode(to: &container)
        }
    }
    
    public func encode<Key: Encodable>(_ dictionary: [Key: Encodable]) throws -> Data {
        let wrappedDict = dictionary.mapValues(EncodableWrapper.init(wrapped:))
        return try self.encode(wrappedDict)
    }
}
