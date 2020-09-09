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
        
        indicator.interface { (me, interface) in
            let indicator = me as! UIActivityIndicatorView
            indicator.color = InterfaceTheme.Color.interactive
        }
        return indicator
    }()
    
    internal var _lastLocation: Int?
    internal var _isAdjustingSelectRange: Bool = false
    private let disposeBag = DisposeBag()
    private let _contentEdgeInsect: UIEdgeInsets = {
        if isMacOrPad {
            return UIEdgeInsets(top: 30, left: 60, bottom: 0, right: 100)
        } else {
            return UIEdgeInsets(top: 30, left: 12, bottom: 0, right: 20)
        }
    }()
    
    // these two part is used for mac and ipad
    private let topViewContainer: UIView = UIView()
    private let rightViewContainer: UIView = UIView()
    
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
        
        self.modalPresentationStyle = .fullScreen
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func start() {
        self.viewModel.start()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public let inputbar = InputToolbar(mode: .paragraph)
    
    private let _toolBar: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .equalSpacing
        view.spacing = 20
        return view
    }()
    
    private var _keyboardHeight: CGFloat = 0
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.interface { [weak self] (me, theme) in
            me.view.backgroundColor = InterfaceTheme.Color.background1
            self?.setNeedsStatusBarAppearanceUpdate()
            self?.viewModel.revertContent()
        }

        self.view.addSubview(self.topViewContainer)
        self.view.addSubview(self.textView)
        self.view.addSubview(self.rightViewContainer)
        self.view.addSubview(self._loadingIndicator)
        
        if !self.viewModel.isReadyToEdit {
            self._loadingIndicator.startAnimating()
            self.setToolbarEnabled(false)
        }
        
        // temp editor don't keep record
        if !self.viewModel.isTemp {
            self.viewModel.dependency.settingAccessor.logOpenDocument(url: self.viewModel.url)
        }
                
        self.topViewContainer.sideAnchor(for: [.left, .top, .right], to: self.view, edgeInset: 0)
        self.topViewContainer.bottomAnchor.constraint(equalTo: self.textView.topAnchor).isActive = true
        self.topViewContainer.bottomAnchor.constraint(equalTo: self.rightViewContainer.topAnchor).isActive = true
        if isPhone {
            self.topViewContainer.sizeAnchor(height: 0) // this view only available for iPad and mac
        }
        self.textView.sideAnchor(for: [.left, .bottom], to: self.view, edgeInset: 0)
        self.textView.rightAnchor.constraint(equalTo: self.rightViewContainer.leftAnchor).isActive = true
        self.rightViewContainer.sideAnchor(for: [.right, .bottom], to: self.view, edgeInset: 0)
        self.rightViewContainer.sizeAnchor(width: 0)

        self._loadingIndicator.centerAnchors(position: [.centerX, .centerY], to: self.view)

        // temp is used for show only the content, can't edit, like conflict preview
        if !self.viewModel.isTemp {
            if #available(iOS 13.0, *) {
                if isPad {
                    let binding = KeyBinding()
                    KeyAction.allCases.filter({ !$0.isGlobal }).forEach {
                        self.addKeyCommand(binding.create(for: $0))
                    }
                }
                
                self.enableKeyBindings()
            }

            var closeButtonIcon = Asset.Assets.cross.image.fill(color: InterfaceTheme.Color.interactive)
            if self.viewModel.context.coordinator?.isModal == false {
                closeButtonIcon = Asset.Assets.left.image.fill(color: InterfaceTheme.Color.interactive)
            }
            let closeButton = UIBarButtonItem(image: closeButtonIcon, style: .plain, target: self, action: #selector(cancel(_:)))
            self.navigationItem.leftBarButtonItem = closeButton
            
            let menuButton = UIBarButtonItem(image: Asset.Assets.more.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(showMenu))
            let infoButton = UIBarButtonItem(image: Asset.Assets.document.image.fill(color: InterfaceTheme.Color.interactive), style: .plain, target: self, action: #selector(showInfo))
            
            self.navigationItem.rightBarButtonItems = [menuButton, infoButton]
            
            self.inputbar.delegate = self
            
            if isMacOrPad {
                self.topViewContainer.addSubview(self.inputbar)
                self.view.addSubview(self._toolBar)
                
                self.inputbar.allSidesAnchors(to: self.topViewContainer, edgeInsets: .init(top: 0, left: Layout.innerViewEdgeInsets.left, bottom: 0, right: -50))
                self.inputbar.sizeAnchor(height: 60)
                self.topViewContainer.columnAnchor(view: self._toolBar, space: 50, alignment: .none)
                self._toolBar.sideAnchor(for: .right, to: self.view, edgeInsets: .init(top: 0, left: 0, bottom: 0, right: -Layout.innerViewEdgeInsets.right))
                self._toolBar.sizeAnchor(width: 44)
                
                self.addToolbarButton(title: L10n.Document.Menu.fullScreen, icon: Asset.Assets.fullscreen.image) { [weak self] button in
                    self?.viewModel.context.coordinator?.toggleEditorFullScreen()
                }
                
                self.addToolbarButton(title: L10n.Document.Menu.foldAll, icon: Asset.Assets.foldAll.image) { [weak self]  button in
                    self?.viewModel.foldAll()
                }
                
                self.addToolbarButton(title: L10n.Document.Menu.unfoldAll, icon: Asset.Assets.unfoldAll.image) { [weak self]  button in
                    self?.viewModel.unfoldAll()
                }
                
                self.addToolbarButton(title: L10n.Document.Menu.outline, icon: Asset.Assets.list.image) { [weak self]  button in
                    self?.showOutline(from: button)
                }
                
                self.addToolbarButton(title: "", icon: Asset.Assets.more.image) { [weak self]  button in
                    self?.showInfo()
                }
            } else {
                self.inputbar.frame = CGRect(origin: .zero, size: .init(width: self.view.bounds.width, height: 44))
                self.textView.inputAccessoryView = self.inputbar
            }
            
            self.inputbar.mode = .paragraph
            
            NotificationCenter.default.addObserver(self, selector: #selector(_documentStateChanged(_:)), name: UIDocument.stateChangedNotification, object: nil)
            
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidHideNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(_tryToShowUserGuide), name: UIResponder.keyboardDidShowNotification, object: nil)
            
            self.viewModel.dependency.syncManager.onDownloadingCompletes.subscribe(onNext: { [unowned self] url in
                guard url.path == self.viewModel.url.path else { return }
                
                guard self.viewModel.isReadyToEdit else { return }
                
                if (try? String(contentsOf: url.contentURL) ) == self.viewModel.string { return }
                
                guard self.view.window != nil else {
                    // if the view is not showing, just reload the content
                    self.viewModel.revertContent(shouldSaveBeforeRevert: false)
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 15) {
                    if let lastState = self._lastState, !lastState.contains(.inConflict) {
                        let confirm = ConfirmViewController(contentText: L10n.Document.Edit.remoteEditingArrivedTitle,
                                                            onConfirm: { viewController in
                                                                viewController.dismiss(animated: true) {
                                                                    self.viewModel.revertContent(shouldSaveBeforeRevert: false)
                                                                }
                        }) { viewController in
                            viewController.dismiss(animated: true)
                        }
                        
                        confirm.title = url.packageName
                        confirm.present(from: self)
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
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isPhone {
            self.viewModel.start()
        }
        
        self.view.becomeFirstResponder()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.textView.endEditing(true)
        
        // only for phone
        if self.presentingViewController == nil && isPhone {
            self.viewModel.context.coordinator?.removeFromParent()
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return InterfaceTheme.statusBarStyle
    }
    
    private func createActionButton(icon: UIImage?) -> RoundButton {
        let button = RoundButton()
        
        button.setIcon(icon, for: .normal)
        
        button.interface { (me, interface) in
            let button = me as! RoundButton
            button.setBackgroundColor(InterfaceTheme.Color.background2, for: .normal)
        }
        return button
    }
    
    private func addToolbarButton(title: String, icon: UIImage, action: @escaping (RoundButton) -> Void) {
        let button = RoundButton(style: RoundButton.Style.verticle)
        button.interface { (it, theme) in
            (it as! RoundButton).setIcon(icon.fill(color: theme.color.interactive), for: .normal)
            (it as! RoundButton).tintColor = theme.color.interactive
            (it as! RoundButton).setBackgroundColor(theme.color.background3, for: .normal)
        }
        button.title = title
        button.tapped { action($0) }
        button.setButtonRadius(20)
        
        self._toolBar.addArrangedSubview(button)
    }
    
    private func setToolbarEnabled(_ enable: Bool) {
        self._toolBar.arrangedSubviews.forEach {
            ($0 as? UIButton)?.isEnabled = enable
        }
    }
    
    private var _rightPartViewController: UIViewController?
    func toggleRightPart(viewController: UIViewController?) {
        
        self._rightPartViewController?.removeFromParent()
        self._rightPartViewController?.view.removeFromSuperview()
        
        if let viewController = viewController {
            self.addChild(viewController)
            self._rightPartViewController = viewController
            
            self.rightViewContainer.addSubview(viewController.view)
            viewController.view.allSidesAnchors(to: self.rightViewContainer, edgeInset: 0)
            
            self.rightViewContainer.constraint(for: Position.width)?.constant = 300
        } else {
            self.rightViewContainer.constraint(for: Position.width)?.constant = 0
        }
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
                self.viewModel.context.coordinator?.showConfictResolverIfFoundConflictVersions(from: self, viewModel: self.viewModel)
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
    
    public override var keyCommands: [UIKeyCommand]? {
        return super.keyCommands
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
        
        self.setToolbarEnabled(true)
        
        // 移动到指定的位置（如果需要）
        if self.viewModel.onLoadingLocation > 0 {
            self.allowScrollContentWhenKeyboardDisapearTemporaily()
            self.scrollTo(location: self.viewModel.onLoadingLocation)
        } else {
            if (SettingsAccessor.Item.foldAllEntriesWhenOpen.get(Bool.self) ?? false) && !self.viewModel.isTemp {
                self.viewModel.foldAll()
            }
            
            if self.viewModel.string.count == 0 { // if there's no content, add an entry, and show keyboard
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    let result = self.viewModel.performAction(EditAction.convertToHeading(0), textView: self.textView)
                    
                    if let range = result.range {
                        self.textView.selectedRange = NSRange(location: range.upperBound, length: 0)
                        self.textView.becomeFirstResponder()
                    }
                }
            }
        }
        
    }
    
    internal func scrollTo(location: Int, shouldScrollToZero: Bool = false) {
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
