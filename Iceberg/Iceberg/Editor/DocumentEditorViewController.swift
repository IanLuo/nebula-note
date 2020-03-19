//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import RxSwift

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
    private let disposeBag = DisposeBag()
    private let _contentEdgeInsect = UIEdgeInsets(top: 30, left: 12, bottom: 0, right: 20)
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero,
                                        textContainer: viewModel.container)
        self.textView.contentInset = self._contentEdgeInsect

        super.init(nibName: nil, bundle: nil)
        
        self.modalPresentationStyle = .overFullScreen
        
        self.textView.outlineDelegate = self
        self.textView.delegate = self
        self.textView.isEditable = !self.viewModel.isTemp
        viewModel.delegate = self
        
        self.view.backgroundColor = InterfaceTheme.Color.background1
        self.modalPresentationStyle = .fullScreen
        
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

        if !self.viewModel.isTemp {
            let closeButton = UIBarButtonItem(image: Asset.Assets.down.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(cancel(_:)))
            self.navigationItem.leftBarButtonItem = closeButton
            
            let menuButton = UIBarButtonItem(image: Asset.Assets.more.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(showMenu))
            let infoButton = UIBarButtonItem(image: Asset.Assets.left.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(showInfo))
            
            self.navigationItem.rightBarButtonItems = [menuButton, infoButton]
            
            self.inputbar.frame = CGRect(origin: .zero, size: .init(width: self.view.bounds.width, height: 44))
            self.inputbar.delegate = self
            self.textView.inputAccessoryView = self.inputbar
            
            self.inputbar.mode = .paragraph
            
            NotificationCenter.default.addObserver(self, selector: #selector(_documentStateChanged(_:)), name: UIDocument.stateChangedNotification, object: nil)
            
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidHideNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(_tryToShowUserGuide), name: UIResponder.keyboardDidShowNotification, object: nil)
            
            self.viewModel.dependency.syncManager.onDownloadingCompletes.subscribe(onNext: { url in
                guard url.path == self.viewModel.url.path else { return }
                
                guard (try? String(contentsOf: url)) != self.viewModel.string else { return }
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 15) {
                    if let lastState = self._lastState, !lastState.contains(.inConflict) {
                        let confirm = ConfirmViewController(contentText: L10n.Document.Edit.remoteEditingArrivedTitle, onConfirm: { viewController in
                            viewController.dismiss(animated: true) {
                                self.viewModel.revertContent(shouldSaveBeforeRevert: false)
                            }
                        }) { viewController in
                            viewController.dismiss(animated: true)
                        }
                        
                        self.present(confirm, animated: true)
                    }
                }
            }).disposed(by: self.disposeBag)
            
            // disable global mode for now
//            self.viewModel.dependency.appContext.isReadingMode.subscribe(onNext: { [weak self] isReadingMode in
//                self?.textView.isEditable = !isReadingMode && self?.viewModel.isTemp == false
//                self?.textView.inputAccessoryView?.isHidden = isReadingMode
//            }).disposed(by: self.disposeBag)
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.textView.endEditing(true)
        if self.presentingViewController == nil {
            self.viewModel.context.coordinator?.removeFromParent()
        }
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
    
    @objc private func _tryToShowUserGuide(_ notification: Notification) {
        
        guard shouldShowHeadingGuide() else { return }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            let headingButton = self.inputbar.button(at: 0, section: 0)
            if let headingButton = headingButton {
                let userGuideWindow = UserGuideWindow(frame: UIScreen.main.bounds, sourceView: headingButton)
                userGuideWindow.setGuidText(L10n.Guide.Document.Edit.headingEntry)
                UIApplication.shared.windows[UIApplication.shared.windows.count - 1].addSubview(userGuideWindow)
            }
        }
    }
        
    private var _didShowUserGuide: Bool = false
    private func shouldShowHeadingGuide() -> Bool {
        guard _didShowUserGuide == false else { return false }
        
        _didShowUserGuide = true
        
        if self.textView.text.count == 0 && SettingsAccessor.Item.didShowUserGuide.get(Bool.self) == false {
            SettingsAccessor.Item.didShowUserGuide.set(true, completion: {})
            return true
        } else {
            return false
        }
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard self.textView.isEditable else { return }
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardDidHideNotification {
            UIView.animate(withDuration: 0.2) {
                self.textView.contentInset = self._contentEdgeInsect
            }
        } else {
            self.textView.contentInset = UIEdgeInsets(top: self._contentEdgeInsect.top, left: self._contentEdgeInsect.left, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: self._contentEdgeInsect.right)
            self.textView.scrollRangeToVisible(self.textView.selectedRange)
        }
    }

    
    private var _lastState: UIDocument.State?
    @objc private func _documentStateChanged(_ notification: NSNotification) {
        if let document = notification.object as? UIDocument {
            if document.documentState == .normal {
                log.info("document state is: normal")
            }
            
            if document.documentState.contains(.closed) {
                log.info("document is closed")
            }
            
            if document.documentState.contains(.editingDisabled) {
                log.info("document state is: editingDisabled")
            }
            
            if document.documentState.contains(.inConflict) {
                log.info("document state is: inConflict")
                self.viewModel.context.coordinator?.showConfictResolver(from: self, viewModel: self.viewModel)
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
                if lastToken is BlockToken {
                    if lastToken.name == OutlineParser.Key.Node.quoteBlockBegin || lastToken.name == OutlineParser.Key.Node.quoteBlockEnd {
                        self.inputbar.mode = .quote
                    } else if lastToken.name == OutlineParser.Key.Node.codeBlockBegin || lastToken.name == OutlineParser.Key.Node.codeBlockEnd {
                        self.inputbar.mode = .code
                    }
                } else if lastToken is HeadingToken {
                    self.inputbar.mode = .heading
                } else {
                    self.inputbar.mode = .paragraph
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
            if (SettingsAccessor.Item.foldAllEntriesWhenOpen.get(Bool.self) ?? false) && !self.viewModel.isTemp {
                self.viewModel.foldAll()
            }
            
            if self.viewModel.string.count == 0 { // if there's no content, add an entry, and show keyboard
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    let result = self.viewModel.performAction(EditAction.convertToHeading(0), textView: self.textView)
                    self.textView.selectedRange = NSRange(location: result.range!.upperBound, length: 0)
                    self.textView.becomeFirstResponder()
                }
            }
        }
        
        // 打开文件时， 添加到最近使用的文件
        if !self.viewModel.isTemp {
            self.viewModel.dependency.editorContext.recentFilesManager.addRecentFile(url: self.viewModel.url, lastLocation: 0) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.dependency.eventObserver.emit(OpenDocumentEvent(url: strongSelf.viewModel.url))
            }
        }
    }
    
    internal func _scrollTo(location: Int, shouldScrollToZero: Bool = false) {
        if location > 0 {
            self.textView.selectedRange = NSRange(location: location, length: 0)
            if self.textView.isFirstResponder {
                self.textView.scrollRangeToVisible(self.textView.selectedRange)
            } else {
                self.textView.becomeFirstResponder()
            }
        } else if shouldScrollToZero && location == 0 {
            self.textView.selectedRange = NSRange(location: 0, length: 0)
            if self.textView.isFirstResponder {
                self.textView.scrollRangeToVisible(self.textView.selectedRange)
            } else {
                self.textView.becomeFirstResponder()
            }
        }
    }
    
    public func updateHeadingInfo(heading: HeadingToken?) {
        
    }
}
