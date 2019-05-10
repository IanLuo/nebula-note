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
        self._menuButton.addTarget(self, action: #selector(_showMenu), for: .touchUpInside)
        self._infoButton.addTarget(self, action: #selector(_showInfo), for: .touchUpInside)
        
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    @objc private func cancel() {
        self.textView.endEditing(true)
        self.viewModel.save {}
        self.viewModel.coordinator?.stop()
    }
    
    @objc private func _showInfo() {
        self.viewModel.coordinator?.showDocumentInfo(viewModel: self.viewModel)
    }
    
    @objc private func _showMenu() {
        let actionsController = ActionsViewController()
        
        actionsController.addAction(icon: Asset.Assets.down.image, title: "Fold all") { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.foldAll()
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.up.image, title: "Unfold all") { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.unfoldAll()
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.master.image, title: "Outline") { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showOutline(completion: { [unowned self] heading in
                    self._moveTo(location: heading.location)
                })
            })
            
            viewController.setCancel(action: { viewController in
                viewController.dismiss(animated: true, completion: nil)
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.capture.image.fill(color: InterfaceTheme.Color.interactive), title: "Capture", style: .highlight) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showCaptureEntrance()
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
    
        self.present(actionsController, animated: true, completion: nil)
    }
    
    private func attachmentPicker() {
        
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
    
    public func showDateAndTimeCreator(location: Int) {
        let actionsViewController = ActionsViewController()
        actionsViewController.addAction(icon: nil, title: "Schedule", action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showDateSelector(title: "Schedule", current: nil, add: { newDateAndTime in
                    newDateAndTime.isSchedule = true
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.updateDateAndTime(location, newDateAndTime), textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }, delete: {
                    // ignore
                }, cancel: {
                    //ignore
                })
            })
        })
        
        actionsViewController.addAction(icon: nil, title: "Due", action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showDateSelector(title: "Due", current: nil, add: { newDateAndTime in
                    newDateAndTime.isDue = true
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.updateDateAndTime(location, newDateAndTime), textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }, delete: {
                    // ignore
                }, cancel: {
                    //ignore
                })
            })
        })
        
        actionsViewController.addAction(icon: nil, title: "Date and time", action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showDateSelector(title: "Date and time", current: nil, add: { newDateAndTime in
                    
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.updateDateAndTime(location, newDateAndTime), textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }, delete: {
                    // ignore
                }, cancel: {
                    //ignore
                })
            })
        })
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
    }
    
    public func showPriorityEditor(location: Int, current: String?) {
        let actionsController = ActionsViewController()
        actionsController.title = current ?? "Choose your priority"
        
        let priorities = self.viewModel.coordinator?.dependency.settingAccessor.priorities.filter { $0 != current } ?? []
        
        for priority in priorities {
            actionsController.addAction(icon: nil, title: priority) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.changePriority(priority, location), textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                })
            }
        }
        
        if current != nil {
            actionsController.addAction(icon: nil, title: "Remove Priority", style: .warning) { (viewController) in
                viewController.dismiss(animated: true, completion: {
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.changePriority(nil, location), textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                })
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.present(actionsController, animated: true, completion: nil)
    }
    
    public func showTagEditor(location: Int) {
        let tags = self.viewModel.tags(at: location)
        
        let actionsViewController = ActionsViewController()
        
        var location = location
        
        for tag in tags {
            actionsViewController.addAction(icon: Asset.Assets.cross.image.fill(color: InterfaceTheme.Color.warning), title: tag) { actionViewController in
                
                let oldSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.removeTag(tag, location), textView: self.textView)
                if self.textView.selectedRange.location > location {
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }
                
                actionViewController.removeAction(with: tag)
                location -= tag.count
            }
        }
        
        actionsViewController.setCancel {
            $0.dismiss(animated: true, completion: nil)
        }
        
        actionsViewController.addAction(icon: Asset.Assets.add.image.withRenderingMode(.alwaysTemplate), title: L10n.Document.Edit.Tag.add, style: .highlight) { actionViewController in
            actionViewController.dismiss(animated: true, completion: {
                let formController = ModalFormViewController()
                formController.addTextFied(title: L10n.Document.Edit.Tag.add, placeHoder: L10n.Document.Edit.Tag.placeHolder, defaultValue: nil)
                formController.onValidating = { values in
                    if let newTagName = values[L10n.Document.Edit.Tag.add] as? String {
                        if try! NSRegularExpression(pattern: "^\(OutlineParser.RegexPattern.character)+$",
                                             options: []).firstMatch(in: newTagName, options: [],
                                                                     range: NSRange(location: 0, length: newTagName.count)) == nil {
                            return [L10n.Document.Edit.Tag.add: L10n.Document.Edit.Tag.validation]
                        }
                    }
                    
                    return [:]
                }
                formController.onSaveValue = { values, viewController in
                    if let newTagName = values[L10n.Document.Edit.Tag.add] as? String {
                        viewController.dismiss(animated: true, completion: {
                            let oldSelectedRange = self.textView.selectedRange
                            let result = self.viewModel.performAction(EditAction.addTag(newTagName, location), textView: self.textView)
                            if self.textView.selectedRange.location > location {
                                self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                            }
                            location += newTagName.count
                        })
                    }
                }
                
                formController.onCancel = {
                    $0.dismiss(animated: true, completion: nil)
                }
                
                self.present(formController, animated: true, completion: nil)
            })
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
    }
    
    public func showCapturedItemList(location: Int) {
        self.viewModel.coordinator?.showCapturedList { [weak self] attachment in
            
            guard let strongSelf = self else { return }
            
            let _ = strongSelf.viewModel.performAction(EditAction.addAttachment(strongSelf.textView.selectedRange.location,
                                                                   attachment.key,
                                                                   attachment.kind.rawValue),
                                          textView: strongSelf.textView)
        }
    }
    
    public func showPlanningSelector(location: Int, current: String?) {
        let allPlannings = self.viewModel.coordinator!.dependency.settingAccessor.allPlannings.filter { $0 != current }
        
        let actionsController = ActionsViewController()
        
        actionsController.title = current ?? "Choose your planning"
        
        for planning in allPlannings {
            actionsController.addAction(icon: nil, title: planning) { viewController in
                let oldSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changePlanning(planning, location),
                                             textView: self.textView)
                if self.textView.selectedRange.location >= location {
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }
                
                viewController.dismiss(animated: true, completion: nil)
            }
        }
        
        if current != nil {
            actionsController.addAction(icon: Asset.Assets.cross.image.fill(color: InterfaceTheme.Color.warning),
                                        title: L10n.General.Button.Title.delete,
                                        style: .warning) { viewController in
                                            let oldSelectedRange = self.textView.selectedRange
                                            let result = self.viewModel.performAction(EditAction.removePlanning(location),
                                                                         textView: self.textView)
                                            if self.textView.selectedRange.location >= location {
                                                self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                                            }
                                            
                                            viewController.dismiss(animated: true, completion: nil)
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        self.present(actionsController, animated: true)
    }
    
    /// 在 heading 里面点击 heading 按钮
    public func showHeadingEdit(at location: Int) {
        let actionsController = ActionsViewController()
        
        actionsController.addAction(icon: nil, title: "转为正文") { viewController in
            viewController.dismiss(animated: true, completion: {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.convertHeadingToParagraph(location), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.present(actionsController, animated: true, completion: nil)
    }
    
    public func showParagraphActions(at location: Int) {
        let actionsController = ActionsViewController()
        
        let isFolded = self.viewModel.isParagraphFolded(at: location)
        let foldTitle = isFolded ? "展开段落" : "折叠段落"
        let icon = isFolded ? Asset.Assets.up.image : Asset.Assets.down.image
        actionsController.addAction(icon: icon, title: foldTitle) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.foldOrUnfold(location: location)
            })
        }
        
        actionsController.addAction(icon: nil, title: "移动到其他段落") { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showOutline(completion: { [unowned self] heading in
                    let oldLocation = self.textView.selectedRange.location
                    
                    let result = self.viewModel.moveParagraph(contains: oldLocation, to: heading, textView: self.textView)
                    
                    let changedLength = oldLocation < heading.location ? -result.content!.count : 0 // 如果新的位置的 heading 在原来 heading 的前面，新的位置的 heading需要减掉移走的文字的长度
                    self.textView.selectedRange = NSRange(location: heading.location + heading.length + changedLength, length: 0)
                })
            })
        }
        
        actionsController.addAction(icon: nil, title: "移动到其他文档") { viewController in
            viewController.dismiss(animated: true, completion: {
                let oldLocation = self.textView.selectedRange.location
                self.viewModel.coordinator?.showDocumentHeadingPicker(completion: { [unowned self] url, heading in
                    self.viewModel.refileOtherDocument(url: url, heading: heading, location: location, completion: { [unowned self] result in
                        let changedLength = oldLocation < heading.location ? -result.content!.count : 0 // 如果新的位置的 heading 在原来 heading 的前面，新的位置的 heading需要减掉移走的文字的长度
                        self.textView.selectedRange = NSRange(location: heading.location + heading.length + changedLength, length: 0)
                    })
                })
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.present(actionsController, animated: true, completion: nil)
    }
    
    // 在其他非空行的位置点击 heading 按钮
    public func showHeadingAdd(at location: Int) {
        let actionsController = ActionsViewController()
        
        actionsController.addAction(icon: nil, title: "转为标题") { viewController in
            viewController.dismiss(animated: true, completion: {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.convertToHeading(location), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.present(actionsController, animated: true, completion: nil)
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
}

extension DocumentEditViewController: OutlineTextViewDelegate {
    public func didTapOnHiddenAttachment(textView: UITextView, characterIndex: Int, point: CGPoint) {
        self.viewModel.foldOrUnfold(location: characterIndex)
    }
    
    public func didTapOnPriority(textView: UITextView, characterIndex: Int, priority: String, point: CGPoint) {
        self.showPriorityEditor(location: characterIndex, current: priority)
    }
    
    public func didTapOnPlanning(textView: UITextView, characterIndex: Int, planning: String, point: CGPoint) {
        self.showPlanningSelector(location: characterIndex, current: planning)
    }
    
    public func didTapDateAndTime(textView: UITextView, characterIndex: Int, dateAndTimeString: String, point: CGPoint) {
        let dateAndTime = DateAndTimeType(dateAndTimeString)!
        self.viewModel.coordinator?.showDateSelector(title: "update the date and time", current: dateAndTime, add: { [unowned self] newDateAndTime in
            let oldSelectedRange = textView.selectedRange
            let result = self.viewModel.performAction(EditAction.updateDateAndTime(characterIndex, newDateAndTime), textView: self.textView)
            if self.textView.selectedRange.location > characterIndex {
                self.textView.selectedRange = oldSelectedRange.offset(result.delta)
            }
            
            self.viewModel.coordinator?.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: dateAndTime,
                                                                                              newDateAndTime: newDateAndTime))
        }, delete: {
            let oldSelectedRange = textView.selectedRange
            let result = self.viewModel.performAction(EditAction.updateDateAndTime(characterIndex, nil), textView: self.textView)
            if self.textView.selectedRange.location > characterIndex {
                self.textView.selectedRange = oldSelectedRange.offset(result.delta)
            }
            
            self.viewModel.coordinator?.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: dateAndTime,
                                                                                              newDateAndTime: nil))
        }, cancel: {})
    }
    
    public func didTapOnTags(textView: UITextView, characterIndex: Int, tags: [String], point: CGPoint) {
        self.showTagEditor(location: characterIndex)
    }
    
    public func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String : String], point: CGPoint) {
        let actionsController = ActionsViewController()
        actionsController.addAction(icon: Asset.Assets.right.image.fill(color: InterfaceTheme.Color.descriptive), title: "Open") { viewController in
            viewController.dismiss(animated: true, completion: {
                if let url = URL(string: linkStructure[OutlineParser.Key.Element.Link.url]!) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.add.image, title: "Edit") { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showLinkEditor(title: linkStructure["title"]!, url: linkStructure["url"]!, completeEdit: { [unowned self] linkString in
                    let oldSelectedRange = textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.updateLink(characterIndex, linkString), textView: self.textView)
                    textView.selectedRange = oldSelectedRange.offset(result.delta)
                })
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        self.present(actionsController, animated: true, completion: nil)
    }
    
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int, point: CGPoint) {
        self.viewModel.foldOrUnfold(location: chracterIndex)
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: String, point: CGPoint) {
        let _ = self.viewModel.performAction(.toggleCheckboxStatus(characterIndex, checkbox),
                                     textView: self.textView)
    }
    
}

extension DocumentEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.viewModel.didUpdate()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        self.viewModel.cursorLocationChanged(textView.selectedRange.location)
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" { // 换行
            return self._handleLineBreak(textView)
        } else if text == "" { // 删除
            return self._handelBackspace(textView)
        } else if text == "\t" { // tab
            return self._handleTab(textView)
        }
        
        return true
    }
}

extension DocumentEditViewController {
    private func _handleLineBreak(_ textView: UITextView) -> Bool {
        // 如果在 heading 中，换行不在当前位置，而在 heading 之后
        guard let currentPosition = textView.selectedTextRange?.start else { return true }
        
        for case let heading in self.viewModel.currentTokens where heading is HeadingToken {
            let result = self.viewModel.performAction(EditAction.addNewLineBelow(location: textView.selectedRange.location), textView: textView)
            textView.selectedRange = NSRange(location: result.range!.location, length: 0)
            return false
        }
        
        // 有序列表，自动添加列表前缀，如果真有前缀没有内容，则删除前缀
        for case let token in self.viewModel.currentTokens where token is OrderedListToken {
            if token.range.length == (token as! OrderedListToken).prefix.length {
                let oldSelectedRange = textView.selectedRange
                let result = self.viewModel.performAction(EditAction.replaceText((token as! OrderedListToken).prefix, ""), textView: self.textView)
                textView.selectedRange = oldSelectedRange.offset(result.delta)
            } else {
                textView.replace(textView.textRange(from: currentPosition, to: currentPosition)!, withText: "\n")
                let result = self.viewModel.performAction(EditAction.orderedListSwitch(textView.selectedRange.location), textView: self.textView)
                textView.selectedRange = NSRange(location: result.range!.upperBound, length: 0)
            }
            return false
        }
        
        // 无序列表，自动添加列表前缀，如果真有前缀没有内容，则删除前缀
        for case let token in self.viewModel.currentTokens where token is UnorderdListToken {
            if token.range.length == (token as! UnorderdListToken).prefix.length {
                let oldSelectedRange = textView.selectedRange
                let result = self.viewModel.performAction(EditAction.replaceText((token as! UnorderdListToken).prefix, ""), textView: self.textView)
                textView.selectedRange = oldSelectedRange.offset(result.delta)
            } else {
                textView.replace(textView.textRange(from: currentPosition, to: currentPosition)!, withText: "\n")
                let result = self.viewModel.performAction(EditAction.unorderedListSwitch(textView.selectedRange.location), textView: self.textView)
                textView.selectedRange = NSRange(location: result.range!.upperBound, length: 0)
            }
            return false
        }
        
        return true
    }
    
    /// 输入退格键，自动选中某些 tokne 范围
    private func _handelBackspace(_ textView: UITextView) -> Bool {
        if textView.selectedRange.length == 0 {
            for case let attachmentToken in self.viewModel.currentTokens where attachmentToken is AttachmentToken {
                textView.selectedRange = attachmentToken.range
                return false
            }
            
            for case let dateAndTimeToken in self.viewModel.currentTokens where dateAndTimeToken is DateAndTimeToken {
                textView.selectedRange = dateAndTimeToken.range
                return false
            }
            
            for case let textMark in self.viewModel.currentTokens where textMark is TextMarkToken {
                if textMark.range.length == 2 /* 没有内容 */ {
                    let oldSelectedRange = textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.replaceText(textMark.range, ""), textView: textView)
                    textView.selectedRange = oldSelectedRange.offset(result.range!.location - oldSelectedRange.location)
                    return false
                }
            }
            
            for case let token in self.viewModel.currentTokens where token is HeadingToken {
                let headingToken = token as! HeadingToken
                let location = textView.selectedRange.location
                
                if let tagsRange = headingToken.tags {
                    if tagsRange.contains(location) || tagsRange.upperBound == location {
                        textView.selectedRange = tagsRange
                        return false
                    }
                }
                
                if let planningRange = headingToken.planning {
                    if planningRange.contains(location) || planningRange.upperBound == location {
                        textView.selectedRange = planningRange
                        return false
                    }
                }
                
                if let priorityRange = headingToken.priority {
                    if priorityRange.contains(location) || priorityRange.upperBound == location {
                        textView.selectedRange = priorityRange
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    private func _handleTab(_ textView: UITextView) -> Bool {
        for case let heading in self.viewModel.currentTokens where heading is HeadingToken {
            var newLevel = (heading as! HeadingToken).level + 1
            if newLevel >= SettingsAccessor.shared.maxLevel { newLevel = 1 }
            let oldSelectedRange = textView.selectedRange
            let result = self.viewModel.performAction(EditAction.updateHeadingLevel(textView.selectedRange.location, newLevel), textView: self.textView)
            textView.selectedRange = oldSelectedRange.offset(result.delta)
            return false
        }
        
        return true
    }
    
    private func _moveTo(location: Int) {
        // FIXME:
        if let position = self.textView.position(from: self.textView.beginningOfDocument, offset: location) {
            let r = self.textView.firstRect(for: self.textView.textRange(from: position, to: position)!)
            self.textView.setContentOffset(CGPoint(x: self.textView.contentOffset.x, y: r.origin.y), animated: false)
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
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func updateHeadingInfo(heading: HeadingToken?) {
        
    }
}
