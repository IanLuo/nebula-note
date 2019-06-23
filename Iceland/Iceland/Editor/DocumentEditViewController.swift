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
    
    private var _shouldScrollWhenKeyboardDisapear: Bool = false
    
    private let _loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.color = InterfaceTheme.Color.interactive
        return indicator
    }()
    
    public weak var delegate: DocumentEditViewControllerDelegate?
    
    internal var _lastLocation: Int?
    internal var _isAdjustingSelectRange: Bool = false
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero,
                                        textContainer: viewModel.container)
        self.textView.contentInset = UIEdgeInsets(top: 60, left: 10, bottom: 0, right: 10)

        super.init(nibName: nil, bundle: nil)
        
        self.textView.outlineDelegate = self
        self.textView.delegate = self
        viewModel.delegate = self
        
        self.view.backgroundColor = InterfaceTheme.Color.background1
        
        NotificationCenter.default.addObserver(self, selector: #selector(_documentStateChanged(_:)), name: UIDocument.stateChangedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public let inputbar = InputToolbar(mode: .paragraph)
    
    private let _toolBar: UIStackView = UIStackView()
    private var _closeButton: RoundButton!
    private var _menuButton: RoundButton!
    private var _infoButton: RoundButton!
    private var _keyboardHeight: CGFloat = 0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interface { (me, theme) in
            me.setNeedsStatusBarAppearanceUpdate()
        }
        
        self.view.addSubview(self.textView)
        self.view.addSubview(self._toolBar)
        self.view.addSubview(self._loadingIndicator)
        
        if !self.viewModel.isReadyToEdit {
            self._loadingIndicator.startAnimating()
        }
        
        self.textView.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
        self._loadingIndicator.centerAnchors(position: [.centerX, .centerY], to: self.view)
        self._toolBar.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInsets: .init(top: 10, left: 0, bottom: 0, right: 0), considerSafeArea: true)
        self._toolBar.sizeAnchor(height: 44)
        
        self._closeButton = self.createActionButton(icon: Asset.Assets.down.image.fill(color: InterfaceTheme.Color.interactive))
        self._menuButton = self.createActionButton(icon: Asset.Assets.more.image.fill(color: InterfaceTheme.Color.interactive))
        self._infoButton = self.createActionButton(icon: Asset.Assets.left.image.fill(color: InterfaceTheme.Color.interactive))
        
        self._closeButton.tapped { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.cancel(strongSelf._closeButton)
        }
        self._menuButton.tapped { [weak self] _ in self?.showMenu() }
        self._infoButton.tapped { [weak self] _ in self?.showInfo() }
        
        self._toolBar.addSubview(_closeButton)
        self._toolBar.addSubview(_menuButton)
        self._toolBar.addSubview(_infoButton)
        
        self._closeButton.sizeAnchor(width: 44)
        self._infoButton.sizeAnchor(width: 44)
        self._menuButton.sizeAnchor(width: 44)
        
        self._closeButton.sideAnchor(for: .left, to: self._toolBar, edgeInset: Layout.edgeInsets.left)
        self._closeButton.centerAnchors(position: .centerY, to: self._toolBar)
        
        self._infoButton.sideAnchor(for: .right, to: self._toolBar, edgeInset: Layout.edgeInsets.right)
        self._infoButton.centerAnchors(position: .centerY, to: self._toolBar)
        
        self._menuButton.rightAnchor.constraint(equalTo: self._infoButton.leftAnchor, constant: -10).isActive = true
        self._menuButton.centerAnchors(position: .centerY, to: self._toolBar)
        
        self.inputbar.frame = CGRect(origin: .zero, size: .init(width: self.view.bounds.width, height: 44))
        self.inputbar.delegate = self
        self.textView.inputAccessoryView = self.inputbar
        
        self.inputbar.mode = .paragraph
        
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardWillShow(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardWillHide(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardDidShow(_:)), name: UIApplication.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_keyboardDidHide(_:)), name: UIApplication.keyboardDidHideNotification, object: nil)
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return InterfaceTheme.statusBarStyle
    }
    
    private func createActionButton(icon: UIImage?) -> RoundButton {
        let button = RoundButton()
        
        button.setIcon(icon, for: .normal)
        button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
        return button
    }
    
    @objc private func _keyboardWillShow(_ notification: Notification) {
        
    }
    
    @objc private func _keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: {
            self.textView.contentInset = UIEdgeInsets(top: self.textView.contentInset.top,
                                                      left: self.textView.contentInset.left,
                                                      bottom: 0,
                                                      right: self.textView.contentInset.right)
        }, completion: nil)
    }
    
    @objc private func _keyboardDidShow(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let keyboardHeight = (userInfo["UIKeyboardFrameEndUserInfoKey"] as! CGRect).height
            
            self.textView.contentInset = UIEdgeInsets(top: self.textView.contentInset.top,
                                                      left: self.textView.contentInset.left,
                                                      bottom: keyboardHeight,
                                                      right: self.textView.contentInset.right)
            
            if let textRange = self.textView.selectedTextRange {
                let targetRect = self.textView.caretRect(for: textRange.start)
                let keyboarTopAsContentOffset = self.textView.contentOffset.y + self.textView.bounds.height - keyboardHeight
                if targetRect.origin.y >= keyboarTopAsContentOffset {
                    UIView.animate(withDuration: 0.25) {
                        self.textView.contentOffset = CGPoint(x: self.textView.contentOffset.x, y: keyboarTopAsContentOffset)
                    }
                }
            }
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
                    // TODO: handle new document conent arrived
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
    
    public func allowScrollContentWhenKeyboardDisapearTemporaily() {
        self._shouldScrollWhenKeyboardDisapear = true
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self._shouldScrollWhenKeyboardDisapear = false
        }
    }
}

extension DocumentEditViewController: DocumentEditViewModelDelegate {
    public func didEnterTokens(_ tokens: [Token]) {
        if tokens.count == 0 {
            self.inputbar.mode = .paragraph
        } else {
            for token in tokens {
                if token is HeadingToken {
                    self.inputbar.mode = .heading
                    break
                } else if token is BlockBeginToken {
                    if token.name == OutlineParser.Key.Node.quoteBlockBegin {
                        self.inputbar.mode = .quote
                        break
                    } else if token.name == OutlineParser.Key.Node.codeBlockBegin {
                        self.inputbar.mode = .code
                        break
                    }
                } else {
                    self.inputbar.mode = .paragraph
                }
            }
        }
        
        self.viewModel.currentTokens = tokens
    }
    
    public func didReadyToEdit() {
        self._loadingIndicator.stopAnimating()
        
        // 移动到指定的位置（如果需要）
        self.allowScrollContentWhenKeyboardDisapearTemporaily()
        self._scrollTo(location: self.viewModel.onLoadingLocation)
        
        // 打开文件时， 添加到最近使用的文件
        self.viewModel.coordinator?.dependency.editorContext.recentFilesManager.addRecentFile(url: self.viewModel.url, lastLocation: 0) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.viewModel.coordinator?.dependency.eventObserver.emit(OpenDocumentEvent(url: strongSelf.viewModel.url))
        }
    }
    
    internal func _scrollTo(location: Int) {
        if location > 0 {
            self.textView.scrollRangeToVisible(self.textView.selectedRange)
            self.textView.selectedRange = (self.textView.text as NSString).lineRange(for: NSRange(location: location, length: 0)).tail(0).offset(-1)
            self.textView.becomeFirstResponder()
        }
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func updateHeadingInfo(heading: HeadingToken?) {
        
    }
}
