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

public class DocumentEditorViewController: UIViewController {
    public let textView: OutlineTextView
    internal let viewModel: DocumentEditViewModel
    
    private var _shouldScrollWhenKeyboardDisapear: Bool = false
    
    private let _loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.color = InterfaceTheme.Color.interactive
        return indicator
    }()
    
    internal var _lastLocation: Int?
    internal var _isAdjustingSelectRange: Bool = false
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero,
                                        textContainer: viewModel.container)
        self.textView.contentInset = UIEdgeInsets(top: 60, left: 10, bottom: 0, right: 10)

        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overFullScreen
        
        self.textView.outlineDelegate = self
        self.textView.delegate = self
        viewModel.delegate = self
        
        self.view.backgroundColor = InterfaceTheme.Color.background1
        self.modalPresentationStyle = .fullScreen
        
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
    private var _keyboardHeight: CGFloat = 0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interface { [weak self] (me, theme) in
            self?.setNeedsStatusBarAppearanceUpdate()
        }
        
        self.view.addSubview(self.textView)
        self.view.addSubview(self._loadingIndicator)
        
        if !self.viewModel.isReadyToEdit {
            self._loadingIndicator.startAnimating()
        }
        
        self.textView.allSidesAnchors(to: self.view, edgeInset: 0, considerSafeArea: true)
        self._loadingIndicator.centerAnchors(position: [.centerX, .centerY], to: self.view)

        let closeButton = UIBarButtonItem(image: Asset.Assets.down.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(cancel(_:)))
        self.navigationItem.leftBarButtonItem = closeButton
        
        let menuButton = UIBarButtonItem(image: Asset.Assets.more.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(showMenu))
        let infoButton = UIBarButtonItem(image: Asset.Assets.left.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(showInfo))
        
        self.navigationItem.rightBarButtonItems = [menuButton, infoButton]
        
        self.inputbar.frame = CGRect(origin: .zero, size: .init(width: self.view.bounds.width, height: 44))
        self.inputbar.delegate = self
        self.textView.inputAccessoryView = self.inputbar
        
        self.inputbar.mode = .paragraph
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.textView.endEditing(true)
        if self.presentingViewController == nil {
            self.viewModel.coordinator?.removeFromParent()
        }
    }
    
//    public override var preferredStatusBarStyle: UIStatusBarStyle {
//        return InterfaceTheme.statusBarStyle
//    }
    
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
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.textView.contentInset = .zero
        } else {
            self.textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        self.textView.scrollIndicatorInsets = self.textView.contentInset

        let selectedRange = self.textView.selectedRange
        self.textView.scrollRangeToVisible(selectedRange)
    }
    
    private var _lastState: UIDocument.State?
    @objc private func _documentStateChanged(_ notification: NSNotification) {
        if let document = notification.object as? UIDocument {
            if document.documentState == .normal {
                if self._lastState == .editingDisabled { // recovered from editDisabled, that means other process has modified it, revert content
                    self.viewModel.revertContent() // load content from disk
                }
                log.info("document state is: normal")
            }
            
            if document.documentState.contains(.closed) {
                log.info("document is closed")
            }
            
            if document.documentState.contains(.editingDisabled) {
                log.info("document state is: editingDisabled")
            }
            
            if document.documentState.contains(.inConflict) {
                log.info("document has conflict inConflict")
                
                do { try self.viewModel.handleConflict(url: document.fileURL) }
                catch {
                    log.error("failed to handle conflict: \(error)")
                }
            }
            
            if document.documentState.contains(.progressAvailable) {
                log.info("document state is: progressAvailable")
            }
            
            if document.documentState.contains(.savingError) {
                log.info("document state is: savingError")
            }
            
            log.info("document state is: \(document.documentState)")
            
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

extension DocumentEditorViewController: DocumentEditViewModelDelegate {
    public func didEnterTokens(_ tokens: [Token]) {
        self.viewModel.currentTokens = tokens
        
        if let firstHeading = self.viewModel.headings.first {
            if self.textView.selectedRange.location < firstHeading.range.location {
                self.inputbar.mode = .headless
                return
            }
            
            if let lastToken = tokens.last {
                if lastToken is BlockBeginToken {
                    if lastToken.name == OutlineParser.Key.Node.quoteBlockBegin {
                        self.inputbar.mode = .quote
                    } else if lastToken.name == OutlineParser.Key.Node.codeBlockBegin {
                        self.inputbar.mode = .code
                    }
                } else if lastToken is HeadingToken {
                    self.inputbar.mode = .heading
                }
            } else {
                self.inputbar.mode = .paragraph
            }

        } else {
            self.inputbar.mode = .headless
        }
    }
    
    public func didReadyToEdit() {
        self._loadingIndicator.stopAnimating()
        
        // 移动到指定的位置（如果需要）
        if self.viewModel.onLoadingLocation > 0 {
            self.allowScrollContentWhenKeyboardDisapearTemporaily()
            self._scrollTo(location: self.viewModel.onLoadingLocation)
        } else {
            if SettingsAccessor.Item.unfoldAllEntriesWhenOpen.get(Bool.self) == false {
                self.viewModel.foldAll()
            }
        }
        
        // 打开文件时， 添加到最近使用的文件
        self.viewModel.coordinator?.dependency.editorContext.recentFilesManager.addRecentFile(url: self.viewModel.url, lastLocation: 0) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.viewModel.coordinator?.dependency.eventObserver.emit(OpenDocumentEvent(url: strongSelf.viewModel.url))
        }
    }
    
    internal func _scrollTo(location: Int, shouldScrollToZero: Bool = false) {
        if location > 0 {
            self.textView.scrollRangeToVisible(self.textView.selectedRange)
            self.textView.selectedRange = NSRange(location: location, length: 0)
            self.textView.becomeFirstResponder()
        } else if shouldScrollToZero && location == 0 {
            self.textView.scrollRectToVisible(CGRect.zero, animated: true)
            self.textView.selectedRange = NSRange(location: 0, length: 0)
            self.textView.becomeFirstResponder()
        }
    }
    
    public func updateHeadingInfo(heading: HeadingToken?) {
        
    }
}