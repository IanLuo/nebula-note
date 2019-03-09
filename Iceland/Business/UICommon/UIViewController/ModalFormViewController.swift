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
    
    /// 如果校验失败，返回失败的 key 以及要显示的问题
    func validate(formdata: [String: Codable]) -> [String: String]
}

public class ModalFormViewController: UIViewController {
    public enum InputType {
        case textField(String, String, String?, UIKeyboardType)
        case textView(String, String?, UIKeyboardType)
    }
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.setImage(UIImage(named: "cross")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.setTitleColor(InterfaceTheme.Color.interactive, for: .normal)
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "check-mark")?.withRenderingMode(.alwaysTemplate), for: .normal)
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
    
    private var formData: [String: Codable] = [:] {
        didSet {
            self.performValidation(formData: formData)
        }
    }
    
    public var onSaveValue: (([String: Codable], ModalFormViewController) -> Void)?
    
    public var onCancel: ((ModalFormViewController) -> Void)?
    
    public var onValidating: (([String: Codable]) -> [String: String])?
    
    public weak var delegate: ModalFormViewControllerDelegate?
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.allowsSelection = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
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
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overCurrentContext
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide), name: UIApplication.keyboardWillHideNotification, object: nil)
        
        self.titleLabel.text = self.title
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.becomeFirstResponder()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        self.view.addSubview(self.actionButtonsContainer)
        
        self.actionButtonsContainer.addSubview(self.saveButton)
        self.actionButtonsContainer.addSubview(self.cancelButton)
        self.actionButtonsContainer.addSubview(self.titleLabel)
        
        self.actionButtonsContainer.sideAnchor(for: [.left, .right], to: self.view, edgeInset: 0)
        self.actionButtonsContainer.setBorder(position: .bottom, color: InterfaceTheme.Color.background3, width: 0.5)
        
        self.saveButton.sideAnchor(for: [.left, .top, .bottom], to: actionButtonsContainer, edgeInset: 0)
        self.saveButton.sizeAnchor(width: 80, height: 80)
        self.titleLabel.sideAnchor(for: [.top, .bottom], to: actionButtonsContainer, edgeInset: 0)
        self.saveButton.rowAnchor(view: self.titleLabel)
        self.cancelButton.sideAnchor(for: [.right, .top, .bottom], to: actionButtonsContainer, edgeInset: 0)
        self.cancelButton.sizeAnchor(width: 80, height: 80)
        self.titleLabel.rowAnchor(view: self.cancelButton)
        
        self.view.addSubview(self.tableView)
        actionButtonsContainer.columnAnchor(view: self.tableView)
        
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0, considerSafeArea: true)
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
    
    public func addTextFied(title: String, placeHoder: String, defaultValue: String?, keyboardType: UIKeyboardType = .default) {
        self.items.append(InputType.textField(title, placeHoder, defaultValue, keyboardType))
    }
    
    public func addTextView(title: String, defaultValue: String?, keyboardType: UIKeyboardType = .default) {
        self.items.append(InputType.textView(title, defaultValue, keyboardType))
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
        self.onCancel?(self)
    }
    
    @objc private func save() {
        self.tableView.endEditing(true)
        self.delegate?.modalFormDidSave(viewController: self, formData: self.formData)
        self.onSaveValue?(self.formData, self)
    }
    
    // MARK: - validation -
    private func performValidation(formData: [String: Codable]) {
        var validateResult: [String: String] = [:]
        if let onValidating = onValidating {
            validateResult = onValidating(formData)
        }
        
        if validateResult.count == 0 {
            validateResult = self.delegate?.validate(formdata: formData) ?? [:]
        }
        
        self.showValidationResult(validateResult)
    }
    
    private func showValidationResult(_ result: [String: String]) {
        self.saveButton.isEnabled = result.count == 0 // 如果校验有问题，disable 保存按钮
        self.saveButton.alpha = self.saveButton.isEnabled ? 1 : 0.3
        
        // 调用每个 cell 对应显示问题的方法
        for i in 0..<self.items.count {
            if let validatable = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? Validatable {
                if let p = result[validatable.validateKey] {
                    validatable.showValidationResult(p)
                } else {
                    validatable.showValidationResult(nil)
                }
            }
        }
    }
}

extension ModalFormViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self.view
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

fileprivate protocol Validatable {
    func showValidationResult(_ problem: String?)
    var validateKey: String { get }
}

//
// MARK: - cells
//

// MARK: - InputTextViewCell
private class InputTextViewCell: UITableViewCell, UITextViewDelegate, Validatable {
    fileprivate static let reuseIdentifier = "InputTextViewCell"
    fileprivate static let height: CGFloat = 150
    
    weak var delegate: CellValueDelegate?
    
    fileprivate var item: ModalFormViewController.InputType? {
        didSet {
            guard let item = item else { return }
            self.updateUI(item)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return self.textView.becomeFirstResponder()
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.footnote
        label.textColor = InterfaceTheme.Color.enphersizedDescriptive
        return label
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = InterfaceTheme.Font.body
        textView.textColor = InterfaceTheme.Color.interactive
        textView.backgroundColor = InterfaceTheme.Color.background2
        textView.delegate = self
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
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 10, left: 30, bottom: 0, right: 30))
        self.titleLabel.columnAnchor(view: self.textView)
        self.textView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 10, left: 30, bottom: 0, right: 30))
        
        self.titleLabel.sizeAnchor(height: 30)
        self.textView.sizeAnchor(height: 100)
    }
    
    func showValidationResult(_ problem: String?) {
        if let problem = problem {
            self.titleLabel.text = "\(self.validateKey) \(problem)"
            self.textView.backgroundColor = InterfaceTheme.Color.backgroundWarning
        } else {
            self.titleLabel.text = self.validateKey
            self.textView.backgroundColor = InterfaceTheme.Color.background2
        }
    }
    
    private(set) var validateKey: String = "" // make compiler happy
    
    private func updateUI(_ item: ModalFormViewController.InputType) {
        switch item {
        case let .textView(title, defaultValue, keyboardType):
            self.titleLabel.text = title
            self.validateKey = title
            self.textView.text = defaultValue
            self.textView.keyboardType = keyboardType
        default: break
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.didSetValue(title: self.validateKey, value: textView.text)
    }
}

// MARK: - InputTextFieldCell
private class InputTextFieldCell: UITableViewCell, UITextFieldDelegate, Validatable{
    fileprivate static let reuseIdentifier = "InputTextFieldCell"
    fileprivate static let height: CGFloat = 110
    
    weak var delegate: CellValueDelegate?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        label.textColor = InterfaceTheme.Color.enphersizedDescriptive
        return label
    }()
    
    override func becomeFirstResponder() -> Bool {
        return self.textField.becomeFirstResponder()
    }
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.font = InterfaceTheme.Font.body
        textField.textColor = InterfaceTheme.Color.interactive
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
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
        let value = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        self.delegate?.didSetValue(title: self.validateKey, value: value)
        return true
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background2
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textField)
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 10, left: 30, bottom: 0, right: 30))
        self.titleLabel.sizeAnchor(height: 30)
        self.titleLabel.columnAnchor(view: self.textField)
        self.textField.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 10, left: 30, bottom: 0, right: 30))
        self.textField.sizeAnchor(height: 60)
    }
    
    func showValidationResult(_ problem: String?) {
        if let problem = problem {
            self.titleLabel.text = "\(self.validateKey) \(problem)"
            self.textField.backgroundColor = InterfaceTheme.Color.backgroundWarning
        } else {
            self.titleLabel.text = self.validateKey
            self.textField.backgroundColor = InterfaceTheme.Color.background2
        }
    }
    
    private(set) var validateKey: String = "" // make compiler happy
    
    private func updateUI(_ item: ModalFormViewController.InputType) {
        switch item {
        case let .textField(title, placeholder, value, keyboardType):
            self.titleLabel.text = title
            self.validateKey = title
            self.textField.attributedPlaceholder = NSAttributedString(string: placeholder,
                                                                      attributes: [NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive])
            self.textField.text = value
            self.textField.keyboardType = keyboardType
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
