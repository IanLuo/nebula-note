//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

public protocol DocumentEditViewControllerDelegate: class {

}

public class DocumentEditViewController: UIViewController {
    public let textView: OutlineTextView
    internal let viewModel: DocumentEditViewModel
    
    private let _loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
    
    public weak var delegate: DocumentEditViewControllerDelegate?
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero,
                                        textContainer: viewModel.container)
        self.textView.contentInset = UIEdgeInsets(top: 160, left: 30, bottom: 80, right: 30)

        super.init(nibName: nil, bundle: nil)
        
        self.textView.outlineDelegate = self
        self.textView.delegate = self
        viewModel.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(_documentStateChanged(_:)), name: UIDocument.stateChangedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public let toolbar = InputToolbar(mode: .paragraph)
    
    private let toolBar: UIView = UIView()
    private var closeButton: UIButton!
    private var _menuButton: UIButton!
    private var _infoButton: UIButton!
    private var _keyboardHeight: CGFloat = 0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.frame = self.view.bounds
        
        self.view.addSubview(self.textView)
        self.view.addSubview(self.toolBar)
        self.view.addSubview(self._loadingIndicator)
        
        if !self.viewModel.isReadyToEdit {
            self._loadingIndicator.startAnimating()
        }
        
        self._loadingIndicator.centerAnchors(position: [.centerX, .centerY], to: self.view)
        
        self.closeButton = self.createActionButton(icon: Asset.Assets.cross.image.withRenderingMode(.alwaysTemplate))
        self._menuButton = self.createActionButton(icon: Asset.Assets.more.image.withRenderingMode(.alwaysTemplate))
        self._infoButton = self.createActionButton(icon: Asset.Assets.left.image.withRenderingMode(.alwaysTemplate))
        
        self.closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        self._menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
        self._infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        
        self.toolBar.addSubview(closeButton)
        self.toolBar.addSubview(_menuButton)
        self.toolBar.addSubview(_infoButton)
        
        self.toolbar.frame = CGRect(origin: .zero, size: .init(width: self.view.bounds.width, height: 44))
        self.toolbar.delegate = self
        self.textView.inputAccessoryView = self.toolbar
        
        self.toolbar.mode = .paragraph
        
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardDidShow(_:)), name: UIApplication.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardDidHide(_:)), name: UIApplication.keyboardDidHideNotification, object: nil)
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.toolBar.size(width: self.view.bounds.width, height: 80)
            .align(to: self.view, direction: AlignmentDirection.top, position: AlignmentPosition.middle, inset: 0)

        self.closeButton.size(width: 40, height: 40)
            .alignToSuperview(direction: AlignmentDirection.left, inset: 30)
            .alignToSuperview(direction: AlignmentDirection.top, inset: 30)
        
        self._menuButton.size(width: 40, height: 40)
            .alignToSuperview(direction: AlignmentDirection.right, inset: 30)
            .alignToSuperview(direction: AlignmentDirection.top, inset: 30)
        
        self._infoButton.size(width: 40, height: 40)
            .alignToSuperview(direction: AlignmentDirection.right, inset: 80)
            .alignToSuperview(direction: AlignmentDirection.top, inset: 30)
    }
    
    private func createActionButton(icon: UIImage?) -> UIButton {
        let button = UIButton()
        button.setImage(icon, for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }
    
    @objc private func _keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            self._keyboardHeight = (userInfo["UIKeyboardFrameBeginUserInfoKey"] as! CGRect).size.height
        }
    }
    
    @objc private func _keyboardWillHide(_ notification: Notification) {
        
    }
    
    @objc private func _keyboardDidShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            self._keyboardHeight = (userInfo["UIKeyboardFrameEndUserInfoKey"] as! CGRect).size.height
        }
    }
    
    @objc private func _keyboardDidHide(_ notification: Notification) {
        
    }
    
    private var _lastState: UIDocument.State?
    @objc private func _documentStateChanged(_ notification: NSNotification) {
        if let document = notification.object as? UIDocument {
            if document.documentState == .closed {
                
            } else if document.documentState == .editingDisabled {
                print("document state is: editingDisabled")
            } else if document.documentState == .inConflict {
                print("document state is: inConflict")
                do { try self.viewModel.handleConflict(url: document.fileURL) }
                catch {
                    log.error("failed to handle conflict: \(error)")
                }
            } else if document.documentState == .normal {
                if self._lastState == .editingDisabled { // recovered from editDisabled, that means other process has modified it, revert content
                    self.viewModel.revertContent()
                }
                print("document state is: normal")
            } else if document.documentState == .progressAvailable {
                print("document state is: progressAvailable")
            } else if document.documentState == .savingError {
                print("document state is: savingError")
            }
            print("document state is: \(document.documentState)")
            
            self._lastState = document.documentState
        }
    }
}

extension DocumentEditViewController: DocumentEditViewModelDelegate {
    public func didEnterTokens(_ tokens: [Token]) {
        if tokens.count == 0 {
            self.toolbar.mode = .paragraph
        } else {
            for token in tokens {
                if token is HeadingToken {
                    self.toolbar.mode = .heading
                    break
                } else if token is BlockBeginToken {
                    if token.name == OutlineParser.Key.Node.quoteBlockBegin {
                        self.toolbar.mode = .quote
                        break
                    } else if token.name == OutlineParser.Key.Node.codeBlockBegin {
                        self.toolbar.mode = .code
                        break
                    }
                } else {
                    self.toolbar.mode = .paragraph
                }
            }
        }
        
        self.viewModel.currentTokens = tokens
    }
    
    public func didReadyToEdit() {
        self._loadingIndicator.stopAnimating()
        self._moveTo(location: self.viewModel.onLoadingLocation)
        
        // 打开文件时， 添加到最近使用的文件
        self.viewModel.coordinator?.dependency.editorContext.recentFilesManager.addRecentFile(url: self.viewModel.url, lastLocation: 0) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.viewModel.coordinator?.dependency.eventObserver.emit(OpenDocumentEvent(url: strongSelf.viewModel.url))
        }
        

    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func updateHeadingInfo(heading: HeadingToken?) {
        
    }
}
