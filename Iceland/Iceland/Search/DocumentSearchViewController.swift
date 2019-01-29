//
//  DocumentSearchViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol DocumentSearchViewControllerDelegate: class {
    func didSelectDocument(url: URL, location: Int)
    func didCancelSearching()
}

public class DocumentSearchViewController: UIViewController {
    private enum SearchStatus {
        case ready
        case searching
    }
    
    private let viewModel: DocumentSearchViewModel
    
    public weak var delegate: DocumentSearchViewControllerDelegate?
    
    private let searchInputView: SearchInputView = SearchInputView()
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.searchInputView.textField.becomeFirstResponder()
    }
    
    public override func becomeFirstResponder() -> Bool {
        return self.searchInputView.textField.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        return self.searchInputView.textField.resignFirstResponder()
    }
    
    private lazy var searchResultTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        tableView.register(SearchTableCell.self, forCellReuseIdentifier: SearchTableCell.reuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private lazy var preservedSearchItemsTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = InterfaceTheme.Color.background3
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private var searchStatus: SearchStatus = .ready {
        didSet {
            log.info("status changed: \(searchStatus)")
            switch searchStatus {
            case .ready:
                self.searchResultTableView.isHidden = true
            case .searching:
                self.searchResultTableView.isHidden = false
            }
        }
    }
    
    public init(viewModel: DocumentSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        
        self.title = "Search".localizable
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        
        self.searchStatus = .ready
        
        self.searchInputView.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        self.view.backgroundColor = InterfaceTheme.Color.background1.withAlphaComponent(0.1)
        
        self.view.addSubview(self.searchInputView)
        self.view.addSubview(self.preservedSearchItemsTableView)
        self.view.addSubview(self.searchResultTableView)
        
        self.searchInputView.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInset: 0)
        self.searchInputView.sizeAnchor(height: 80)
        self.searchInputView.columnAnchor(view: self.preservedSearchItemsTableView)
        self.searchInputView.columnAnchor(view: self.searchResultTableView)
        
        self.preservedSearchItemsTableView.sideAnchor(for: [.bottom, .left, .right], to: self.view, edgeInset: 0)
        self.searchResultTableView.sideAnchor(for: [.bottom, .left, .right], to: self.view, edgeInset: 0)
        
        self.searchInputView.hideCancelButton(self.viewModel.coordinator?.isModal != true) // 因为目前只有在 modal 和常驻侧边栏两个位置有 search 模块，所以直接检查是否 modal 即可
    }
}

extension DocumentSearchViewController: SearchInputViewDelegate {
    func didEndSearching() {
        self.searchStatus = .ready
        self.delegate?.didCancelSearching()
    }
    
    func didStartSearching() {
        self.searchStatus = .searching
    }
    
    func didChangeQuery(string: String) {
        self.viewModel.clearSearchResults()
        self.viewModel.search(query: string)
    }
    
    func didClearQuery() {
        self.viewModel.clearSearchResults()
    }
}

extension DocumentSearchViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.data.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchTableCell.reuseIdentifier, for: indexPath) as! SearchTableCell
        cell.cellModel = self.viewModel.data[indexPath.row]
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let searchResult = self.viewModel.data[indexPath.row]
        self.delegate?.didSelectDocument(url: searchResult.url, location: searchResult.hilightRange.location)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension DocumentSearchViewController: DocumentSearchViewModelDelegate {
    public func didCompleteSearching() {
        
    }
    
    public func didAddResult(index: Int, count: Int) {
        self.searchResultTableView.reloadData()
    }
    
    public func didClearResults() {
        self.searchResultTableView.reloadData()
    }
}

private protocol SearchInputViewDelegate: class {
    func didStartSearching()
    func didChangeQuery(string: String)
    func didClearQuery()
    func didEndSearching()
}

private class SearchInputView: UIView, UITextFieldDelegate {
    weak var delegate: SearchInputViewDelegate?
    
    public init() {
        super.init(frame: .zero)
        
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var startEditButton: UIButton = {
        let icon = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 20, height: 20)))
        icon.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
        icon.setImage(UIImage(named: "zoom")?.withRenderingMode(.alwaysTemplate), for: .normal)
        return icon
    }()
    
    private lazy var endEditButton: UIButton = {
        let button = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 20, height: 20)))
        button.addTarget(self, action: #selector(endEdit), for: .touchUpInside)
        button.setTitle("Cancel".localizable, for: .normal)
        button.titleLabel?.font = InterfaceTheme.Font.footnote
        return button
    }()
    
    fileprivate lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.textColor = InterfaceTheme.Color.interactive
        textField.font = InterfaceTheme.Font.body
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.tintColor = InterfaceTheme.Color.interactive
        
        let clearButton = UIButton(frame: CGRect(origin: .zero, size: CGSize(width: 20, height: 20)))
        clearButton.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.descriptive, size: .singlePoint), for: .normal)
        clearButton.setImage(UIImage(named: "cross")?.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = InterfaceTheme.Color.interactive
        clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
        clearButton.layer.cornerRadius = 10
        clearButton.layer.masksToBounds = true
        clearButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        textField.rightView = clearButton
        textField.rightViewMode = .whileEditing
        return textField
    }()
    
    @objc private func endEdit() {
        self.textField.endEditing(true)
        self.delegate?.didEndSearching()
    }
    
    @objc private func clear() {
        self.textField.text = ""
        self.delegate?.didChangeQuery(string: "")
    }
    
    @objc private func beginEdit() {
        self.textField.becomeFirstResponder()
    }
    
    fileprivate func hideCancelButton(_ hide: Bool) {
        self.endEditButton.constraint(for: .width)?.constant = hide ? 0 : 60
        self.layoutIfNeeded()
    }
    
    private func setupUI() {
        self.backgroundColor = InterfaceTheme.Color.background1
        
        self.addSubview(self.startEditButton)
        self.addSubview(self.endEditButton)
        self.addSubview(self.textField)
        
        self.tintColor = InterfaceTheme.Color.interactive
        
        self.startEditButton.sideAnchor(for: .left, to: self, edgeInset: 0)
        self.startEditButton.sizeAnchor(width: 60, height: 60)
        self.startEditButton.centerAnchors(position: .centerY, to: self)
        self.startEditButton.rowAnchor(view: self.textField)
        self.textField.sideAnchor(for: [.top, .bottom], to: self, edgeInset: 0)
        self.textField.rowAnchor(view: self.endEditButton)
        self.endEditButton.sizeAnchor(width: 60, height: 60)
        self.endEditButton.sideAnchor(for: .right, to: self, edgeInset: 30)
        self.endEditButton.centerAnchors(position: .centerY, to: self)
        
        self.setBorder(position: .bottom, color: InterfaceTheme.Color.background3, width: 0.5)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.didStartSearching()
        self.startEditButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.endEditButton.isHidden = true
        self.startEditButton.isEnabled = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let newString = textField.text == nil ? string : (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if newString.count > 0 {
            self.delegate?.didChangeQuery(string: newString)
        } else {
            self.delegate?.didClearQuery()
        }
        return true
    }
}
