//
//  DocumentEditViewController+Menu.swift
//  Iceland
//
//  Created by ian luo on 2019/5/10.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

extension DocumentEditViewController {
    @objc public func cancel(_ button: UIView) {
        self.viewModel.close { _ in }
        self.dismiss(animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.isForcedToHide = false
    }
    
    @objc public func showInfo() {
        self.viewModel.coordinator?.showDocumentInfo(viewModel: self.viewModel) { [weak self] in
            self?.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    @objc public func showMenu() {
        let actionsController = ActionsViewController()
        
        actionsController.title = L10n.Document.Menu.title
        actionsController.addAction(icon: Asset.Assets.down.image, title: L10n.Document.Menu.foldAll) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.foldAll()
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.up.image, title: L10n.Document.Menu.unfoldAll) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.unfoldAll()
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.master.image, title: L10n.Document.Menu.outline) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showOutline(completion: { [unowned self] heading in
                    self.allowScrollContentWhenKeyboardDisapearTemporaily()
                    self._scrollTo(location: heading.location)
                })
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
            
            viewController.setCancel(action: { viewController in
                viewController.dismiss(animated: true, completion: nil)
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.inspiration.image,
                                    title: L10n.Document.Menu.capture,
                                    style: .highlight) { viewController in
                                        viewController.dismiss(animated: true) {
                                            self.viewModel.coordinator?.showCaptureEntrance()
                                        }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        self.textView.resignFirstResponder() // 隐藏键盘
        
        self.present(actionsController, animated: true, completion: nil)
        
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    public func showDateAndTimeCreator(location: Int) {
        
        let handleNewDateAndTime: (DateAndTimeType) -> Void = { newDateAndTime in
            let oldSelectedRange = self.textView.selectedRange
            let result = self.viewModel.performAction(EditAction.updateDateAndTime(location, newDateAndTime), textView: self.textView)
            self.textView.selectedRange = oldSelectedRange.offset(result.delta)
            self.viewModel.coordinator?.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: nil,
                                                                                              newDateAndTime: newDateAndTime))
        }
        
        let handleDeleteDateAndTime: () -> Void = {
            self.viewModel.coordinator?.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: nil,
                                                                                              newDateAndTime: nil))
        }
        
        let actionsViewController = ActionsViewController()
        actionsViewController.addAction(icon: nil, title: L10n.Document.DateAndTime.schedule, action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.schedule, current: nil, add: { newDateAndTime in
                    newDateAndTime.isSchedule = true
                    handleNewDateAndTime(newDateAndTime)
                }, delete: { [weak self] in
                    handleDeleteDateAndTime()
                    self?.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                }, cancel: { [weak self] in
                    self?.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            })
        })
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.DateAndTime.due, action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.due, current: nil, add: { newDateAndTime in
                    newDateAndTime.isDue = true
                    handleNewDateAndTime(newDateAndTime)
                }, delete: { [weak self] in
                    handleDeleteDateAndTime()
                    self?.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                }, cancel: { [weak self] in
                    self?.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            })
        })
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.DateAndTime.title, action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.title, current: nil, add: { newDateAndTime in
                    handleNewDateAndTime(newDateAndTime)
                }, delete: { [weak self] in
                    handleDeleteDateAndTime()
                    self?.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                }, cancel: { [weak self] in
                    self?.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                })
            })
        })
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    public func showPriorityEditor(location: Int, current: String?) {
        let actionsController = ActionsViewController()
        actionsController.title = current ?? L10n.Document.Priority.title
        
        let priorities = self.viewModel.coordinator?.dependency.settingAccessor.priorities.filter { $0 != current } ?? []
        
        for priority in priorities {
            actionsController.addAction(icon: nil, title: priority) { viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.changePriority(priority, location), textView: self.textView)
                    if self.textView.selectedRange.location > location {
                        self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                    }
                })
            }
        }
        
        if current != nil {
            actionsController.addAction(icon: nil, title: L10n.Document.Priority.remove, style: .warning) { (viewController) in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.changePriority(nil, location), textView: self.textView)
                    if self.textView.selectedRange.location > location {
                        self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                    }
                })
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        self.present(actionsController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    // 编辑和选择标签
    public func showTagEditor(location: Int) {
        let tags = self.viewModel.tags(at: location) // 当前选中的所有 tag
        
        let actionsViewController = ActionsViewController()
        actionsViewController.title = L10n.Document.Edit.Tag.title
        var location = location
        
        for tag in tags {
            actionsViewController.addAction(icon: Asset.Assets.cross.image.fill(color: InterfaceTheme.Color.warning), title: tag) { actionViewController in
                
                let oldSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.removeTag(tag, location), textView: self.textView)
                if self.textView.selectedRange.location > location {
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }
                
                actionViewController.removeAction(with: tag)
                location -= tag.count // 删除 tag 后，当前光标所在的位置减去对应 tag 字符串的长度
                self.viewModel.coordinator?.dependency.eventObserver.emit(TagDeleteEvent(tag: tag)) // 更新已保存的 tag
            }
        }
        
        actionsViewController.setCancel {
            $0.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        // 选择一个已经存在的标签
        actionsViewController.addAction(icon: Asset.Assets.tag.image.fill(color: InterfaceTheme.Color.interactive), title: L10n.Document.Edit.Tag.choose, style: .highlight) { viewController in
            viewController.dismiss(animated: true, completion: {
                let selector = SelectorViewController()
                selector.title = L10n.Document.Edit.Tag.title
                
                if let allTags = self.viewModel.coordinator?.loadAllTags() {
                    for tag in allTags {
                        selector.addItem(title: tag, enabled: !tags.contains(tag))
                    }
                }
                
                selector.onCancel = {
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    $0.dismiss(animated: true, completion: nil)
                }
                
                selector.onSelection = { index, viewController in
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    viewController.dismiss(animated: true, completion: {
                        let oldSelectedRange = self.textView.selectedRange
                        let newTag = viewController.items[index].title
                        let result = self.viewModel.performAction(EditAction.addTag(newTag, location), textView: self.textView)
                        if self.textView.selectedRange.location > location {
                            self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                        }
                        location += newTag.count // 删除 tag 后，当前光标所在的位置减去对应 tag 字符串的长度 (可能不需要，暂时先留着)
                    })
                }
                
                self.present(selector, animated: true, completion: nil)
            })
            
        }
        
        // 添加新的标签
        actionsViewController.addAction(icon: Asset.Assets.add.image.fill(color: InterfaceTheme.Color.interactive), title: L10n.Document.Edit.Tag.add, style: .highlight) { actionViewController in
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
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    if let newTagName = values[L10n.Document.Edit.Tag.add] as? String {
                        viewController.dismiss(animated: true, completion: {
                            let oldSelectedRange = self.textView.selectedRange
                            let result = self.viewModel.performAction(EditAction.addTag(newTagName, location), textView: self.textView)
                            if self.textView.selectedRange.location > location {
                                self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                            }
                            location += newTagName.count
                            
                            self.viewModel.coordinator?.dependency.eventObserver.emit(TagAddedEvent(tag: newTagName))
                        })
                    }
                }
                
                formController.onCancel = {
                    $0.dismiss(animated: true, completion: nil)
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                }
                
                self.present(formController, animated: true, completion: nil)
            })
        }
        
        self.present(actionsViewController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
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
        
        actionsController.title = current ?? L10n.Document.Planning.title
        
        for planning in allPlannings {
            actionsController.addAction(icon: nil, title: planning) { viewController in
                let oldSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changePlanning(planning, location),
                                                          textView: self.textView)
                if self.textView.selectedRange.location >= location {
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }
                
                viewController.dismiss(animated: true, completion: nil)
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
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
                                            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        self.present(actionsController, animated: true)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    /// 在 heading 里面点击 heading 按钮
    public func showHeadingEdit(at location: Int) {
        let actionsController = ActionsViewController()
        actionsController.title = L10n.Document.Heading.title
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.toParagraphContent) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.convertHeadingToParagraph(location), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        self.present(actionsController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    public func showParagraphActions(at location: Int) {
        let actionsController = ActionsViewController()
        actionsController.title = L10n.Document.Edit.Action.Paragraph.title
        
        let isFolded = self.viewModel.isParagraphFolded(at: location)
        let foldTitle = isFolded ? L10n.Document.Heading.unfold : L10n.Document.Heading.fold
        let icon = isFolded ? Asset.Assets.up.image : Asset.Assets.down.image
        actionsController.addAction(icon: icon, title: foldTitle) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                self.viewModel.foldOrUnfold(location: location)
            })
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.moveTo) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                self.viewModel.coordinator?.showOutline(ignoredHeadingLocation: location, completion: { [unowned self] heading in
                    let oldLocation = self.textView.selectedRange.location
                    
                    let result = self.viewModel.moveParagraph(contains: oldLocation, to: heading, textView: self.textView)
                    
                    let changedLength = oldLocation < heading.location ? -result.content!.count : 0 // 如果新的位置的 heading 在原来 heading 的前面，新的位置的 heading需要减掉移走的文字的长度
                    self.textView.selectedRange = NSRange(location: heading.location + heading.length + changedLength, length: 0)
                })
            })
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.moveToAnotherDocument) { viewController in
            viewController.dismiss(animated: true, completion: {
                let oldLocation = self.textView.selectedRange.location
                self.viewModel.coordinator?.showDocumentHeadingPicker(completion: { [unowned self] url, heading in
                    self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                    self.viewModel.moveParagraphToOtherDocument(url: url, heading: heading, location: location, textView: self.textView, completion: { [unowned self] result in
                        let changedLength = oldLocation < heading.location ? -result.content!.count : 0 // 如果新的位置的 heading 在原来 heading 的前面，新的位置的 heading需要减掉移走的文字的长度
                        self.textView.selectedRange = NSRange(location: heading.location + heading.length + changedLength, length: 0)
                    })
                })
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        self.present(actionsController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
    
    // 在其他非空行的位置点击 heading 按钮
    public func showHeadingAdd(at location: Int) {
        let actionsController = ActionsViewController()
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.toHeading) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.convertToHeading(location), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
        }
        
        self.present(actionsController, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
    }
}
