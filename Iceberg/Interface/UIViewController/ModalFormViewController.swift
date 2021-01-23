//
//  ModalFormViewController.swift
//  Business
//
//  Created by ian luo on 2019/1/13.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

public protocol ModalFormViewControllerDelegate: class {
    func modalFormDidCancel(viewController: ModalFormViewController)
    func modalFormDidSave(viewController: ModalFormViewController, formData: [String: Codable])
    
    /// 如果校验失败，返回失败的 key 以及要显示的问题
    func validate(formdata: [String: Codable]) -> [String: String]
}

open class ModalFormViewController: TransitionViewController {
    public var contentView: UIView = {
        let view = UIView()
        
        if !isMacOrPad {
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
        }
        return view
    }()
    
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
    
    
    public enum InputType {
        case textField(String, String, String?, UIKeyboardType)
        case textView(String, String?, UIKeyboardType)
    }
    
    private lazy var cancelButton: RoundButton = {
        let button = RoundButton()
        button.setIcon(Asset.SFSymbols.xmark.image.resize(upto: CGSize(width: 10, height: 10)).fill(color: InterfaceTheme.Color.interactive), for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
        return button
    }()
    
    private lazy var saveButton: RoundButton = {
        let button = RoundButton()
        button.setIcon(Asset.SFSymbols.checkmark.image.resize(upto: CGSize(width: 15, height: 15)).fill(color: InterfaceTheme.Color.spotlight), for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
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
    
    public var onSaveValueAutoDismissed: (([String: Codable]) -> Void)?
    
    public var onCancel: ((ModalFormViewController) -> Void)?
    
    public var onValidating: (([String: Codable]) -> [String: String])?
    
    private let disposeBag = DisposeBag()
    
    public weak var delegate: ModalFormViewControllerDelegate?
    
    public lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.alwaysBounceVertical = false
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = InterfaceTheme.Color.background1
        tableView.register(InputTextFieldCell.self, forCellReuseIdentifier: InputTextFieldCell.reuseIdentifier)
        tableView.register(InputTextViewCell.self, forCellReuseIdentifier: InputTextViewCell.reuseIdentifier)
        return tableView
    }()
    
    private let actionButtonsContainer:UIView = {
        let view = UIView()
        view.backgroundColor = InterfaceTheme.Color.background1
        return view
    }()
    
    private let _transitionDelegate: UIViewControllerTransitioningDelegate = FadeBackgroundTransition(animator: MoveInAnimtor())
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        
        self.transitioningDelegate = self._transitionDelegate
        
        if isMacOrPad {
            self.modalPresentationStyle = UIModalPresentationStyle.popover
        } else {
            self.modalPresentationStyle = .overCurrentContext
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillShow), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyBoardWillHide), name: UIApplication.keyboardWillHideNotification, object: nil)
        
        self.titleLabel.text = self.title
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.saveButton.tapped { [weak self] _ in
            self?.save()
        }
        
        self.cancelButton.tapped { [weak self] _ in
            self?.cancel()
        }
        
        if isMacOrPad {
            if self.fromView == nil {
                self.popoverPresentationController?.sourceView = self.view
                self.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2, width: 0, height: 0)
            }
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.preferredContentSize = CGSize(width: 300, height: self.contentView.bounds.height + 20) // 20 is edge insets
    }
    
    public func makeFirstTextFieldFirstResponder() {
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.becomeFirstResponder()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        makeFirstTextFieldFirstResponder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        self.interface { (me, interface) in
            me.view.backgroundColor = interface.color.background1
        }
        
        self.view.addSubview(self.contentView)
        self.contentView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 10, considerSafeArea: true)
        
        self.contentView.addSubview(self.actionButtonsContainer)
        
        self.actionButtonsContainer.addSubview(self.saveButton)
        self.actionButtonsContainer.addSubview(self.cancelButton)
        self.actionButtonsContainer.addSubview(self.titleLabel)
        
        self.actionButtonsContainer.sideAnchor(for: [.left, .right, .top], to: self.contentView, edgeInset: 0)
        self.actionButtonsContainer.sizeAnchor(height: 60)
        
        if isMacOrPad {
            self.cancelButton.isHidden = true
        }
        
        self.cancelButton.sideAnchor(for: .left, to: actionButtonsContainer, edgeInset: 10)
        self.cancelButton.sizeAnchor(width: 30)
        
        self.titleLabel.centerAnchors(position: .centerY, to: self.actionButtonsContainer)
        self.saveButton.centerAnchors(position: .centerY, to: self.actionButtonsContainer)
        self.cancelButton.centerAnchors(position: .centerY, to: self.actionButtonsContainer)
        
        self.cancelButton.rowAnchor(view: self.titleLabel)
        self.saveButton.sideAnchor(for: .right, to: actionButtonsContainer, edgeInset: 10)
        self.saveButton.sizeAnchor(width: 30)
        
        self.titleLabel.rowAnchor(view: self.cancelButton)
        
        self.contentView.addSubview(self.tableView)
        actionButtonsContainer.columnAnchor(view: self.tableView)
        
        self.tableView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInset: 0, considerSafeArea: true)
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
        self.formData[title] = defaultValue
    }
    
    public func addTextView(title: String, defaultValue: String?, keyboardType: UIKeyboardType = .default) {
        self.items.append(InputType.textView(title, defaultValue, keyboardType))
        self.formData[title] = defaultValue
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
        guard self.performValidation(formData: self.formData) else { return }
        self.tableView.endEditing(true)
        self.delegate?.modalFormDidSave(viewController: self, formData: self.formData)
        self.onSaveValue?(self.formData, self)
        
        if let onSaveValueAutoDismissed = self.onSaveValueAutoDismissed {
            self.dismiss(animated: true) { [unowned self] in
                onSaveValueAutoDismissed(self.formData)
            }
        }
    }
    
    // MARK: - validation -
    @discardableResult
    private func performValidation(formData: [String: Codable]) -> Bool {
        var validateResult: [String: String] = [:]
        if let onValidating = onValidating {
            validateResult = onValidating(formData)
        }
        
        if validateResult.count == 0 {
            validateResult = self.delegate?.validate(formdata: formData) ?? [:]
        }
        
        self.showValidationResult(validateResult)
        
        return validateResult.count == 0
    }
    
    private func showValidationResult(_ result: [String: String]) {
        self.saveButton.isEnabled = result.count == 0 // 如果校验有问题，disable 保存按钮
        self.saveButton.alpha = self.saveButton.isEnabled ? 1 : 0.3
        
        // 调用每个 cell 对应显示问题的方法
        for i in 0..<self.items.count {
            if let validatable = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? FormCellProtocol {
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
            cell.onReturn.subscribe(onNext: {
                if indexPath.row == self.items.count - 1 {
                    self.delegate?.modalFormDidSave(viewController: self, formData: self.formData)
                } else {
                    self.save()
                }
            }).disposed(by: self.disposeBag)
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

fileprivate protocol FormCellProtocol {
    func showValidationResult(_ problem: String?)
    var validateKey: String { get }
    var onReturn: PublishSubject<Void> { get set }
    var onNext: PublishSubject<Void> { get set }
}

//
// MARK: - cells
//

// MARK: - InputTextViewCell
private class InputTextViewCell: UITableViewCell, UITextViewDelegate, FormCellProtocol {
    var onReturn: PublishSubject<Void> = PublishSubject()
    
    var onNext: PublishSubject<Void> = PublishSubject()
    
    fileprivate static let reuseIdentifier = "InputTextViewCell"
    fileprivate static let height: CGFloat = 150
    
    weak var delegate: CellValueDelegate?
    
    var cellReuseBag: DisposeBag = DisposeBag()
    
    override func prepareForReuse() {
        cellReuseBag = DisposeBag()
    }
    
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
        label.textColor = InterfaceTheme.Color.secondaryDescriptive
        return label
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.font = InterfaceTheme.Font.body
        textView.textColor = InterfaceTheme.Color.interactive
        textView.backgroundColor = InterfaceTheme.Color.background2
        textView.layer.cornerRadius = 8
        textView.layer.masksToBounds = true
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
        self.backgroundColor = InterfaceTheme.Color.background1
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textView)
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 10, left: 12, bottom: 0, right: -12))
        self.titleLabel.columnAnchor(view: self.textView, space: 5)
        self.textView.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 10, left: 12, bottom: 0, right: -12))
        
        self.titleLabel.sizeAnchor(height: 30)
        self.textView.sizeAnchor(height: 100)
    }
    
    func showValidationResult(_ problem: String?) {
        if let problem = problem {
            self.titleLabel.text = "\(self.validateKey) \(problem)"
            self.textView.backgroundColor = InterfaceTheme.Color.warning
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
private class InputTextFieldCell: UITableViewCell, UITextFieldDelegate, FormCellProtocol{
    var onReturn: PublishSubject<Void> = PublishSubject()
    
    var onNext: PublishSubject<Void> = PublishSubject()
    
    fileprivate static let reuseIdentifier = "InputTextFieldCell"
    fileprivate static let height: CGFloat = 110
    
    weak var delegate: CellValueDelegate?
    
    var cellReuseBag: DisposeBag = DisposeBag()
    
    override func prepareForReuse() {
        cellReuseBag = DisposeBag()
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = InterfaceTheme.Font.footnote
        label.textAlignment = .left
        label.textColor = InterfaceTheme.Color.secondaryDescriptive
        return label
    }()
    
    override func becomeFirstResponder() -> Bool {
        return self.textField.becomeFirstResponder()
    }
    
    private lazy var textField: TextField = {
        let textField = TextField()
        textField.font = InterfaceTheme.Font.body
        textField.textColor = InterfaceTheme.Color.interactive
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = InterfaceTheme.Color.background2
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.delegate = self
        
        return textField
    }()
    
    private class TextField: UITextField {
        override func textRect(forBounds bounds: CGRect) -> CGRect {
            var bounds = bounds
            bounds.origin.x += 10
            return bounds
        }
        
        override func editingRect(forBounds bounds: CGRect) -> CGRect {
            var bounds = bounds
            bounds.origin.x += 10
            return bounds
        }
    }
    
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
        if string == "\n" {
            self.onReturn.onNext(())
            return false
        }
        
        let value = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        self.delegate?.didSetValue(title: self.validateKey, value: value)
        return true
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background1
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.textField)
        
        self.titleLabel.sideAnchor(for: [.left, .top, .right], to: self.contentView, edgeInsets: .init(top: 10, left: 12, bottom: 0, right: -12))
        self.titleLabel.sizeAnchor(height: 20)
        self.titleLabel.columnAnchor(view: self.textField, space: 5)
        self.textField.sideAnchor(for: [.left, .right, .bottom], to: self.contentView, edgeInsets: .init(top: 10, left: 12, bottom: 0, right: -12))
        self.textField.sizeAnchor(height: 44)
    }
    
    func showValidationResult(_ problem: String?) {
        if let problem = problem {
            self.titleLabel.text = "\(self.validateKey) \(problem)"
            self.textField.backgroundColor = InterfaceTheme.Color.warning
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
