//
//  DocumentEditViewController+Menu.swift
//  Iceland
//
//  Created by ian luo on 2019/5/10.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface

extension DocumentEditorViewController {
    @objc public func cancel(_ button: UIView) {
        self.viewModel.context.coordinator?.stop()
        
        if self.viewModel.context.coordinator?.isModal == true {
            self.viewModel.dependency.globalCaptureEntryWindow?.isForcedToHide = false
        }
        self.viewModel.dependency.settingAccessor.logCloseDocument(url: self.viewModel.url)
    }
    
    @objc public func showInfo() {
        self.viewModel.context.coordinator?.showDocumentInfo(viewModel: self.viewModel) {}
    }
    
    @objc public func showOutlook() {
        
    }
    
    @objc public func showMenu() {
        let actionsController = ActionsViewController()
        
        actionsController.title = L10n.Document.Menu.title
        actionsController.addAction(icon: Asset.Assets.foldAll.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.Document.Menu.foldAll) { [unowned self] viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.foldAll()
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.unfoldAll.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.Document.Menu.unfoldAll) { [unowned self] viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.unfoldAll()
            })
        }
        
        actionsController.addAction(icon: Asset.SFSymbols.filemenuAndSelection.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.Document.Menu.outline) { [unowned self] viewController in
            viewController.dismiss(animated: true, completion: {
                self.showOutline()
            })
            
            viewController.setCancel(action: { viewController in
                viewController.dismiss(animated: true)
            })
        }
        
//        let modeTitle = viewModel.isReadingModel ? L10n.Document.Menu.enableEditingMode : L10n.Document.Menu.enableReadingMode
//        actionsController.addAction(icon: nil, title: modeTitle) { [unowned self] viewController in
//            viewController.dismiss(animated: true, completion: {
//                self.viewModel.isReadingModel = !self.viewModel.isReadingModel
//                self.textView.isEditable = !self.viewModel.isReadingModel
//                self.textView.inputAccessoryView?.isHidden = self.viewModel.isReadingModel
////                self.viewModel.dependency.appContext.isReadingMode.accept(!self.viewModel.isReadingModel) // trigger global status change
//            })
//        }
        
        actionsController.addActionAutoDismiss(icon: Asset.SFSymbols.info.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.Document.Menu.info) {
            self.showInfo()
        }
        
        actionsController.addAction(icon: Asset.SFSymbols.lightbulb.image.fill(color: InterfaceTheme.Color.spotlight),
                                    title: L10n.Document.Menu.capture,
                                    style: .highlight) { viewController in
                                        viewController.dismiss(animated: true) { [unowned self] in
                                            self.viewModel.context.coordinator?.showCaptureEntrance()
                                        }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        _  = self.textView.resignFirstResponder() // 隐藏键盘
        
        actionsController.present(from: self)
    }
    
    @objc func showOutline(from: UIView? = nil) {
        self.viewModel.context.coordinator?.showOutline(from: from, completion: { selection in
            self.allowScrollContentWhenKeyboardDisapearTemporaily()
            
            switch selection {
            case .heading(let heading):
                self.viewModel.unfold(location: heading.range.upperBound)
                self.scrollTo(location: heading.range.upperBound, shouldScrollToZero: true)
            case .position(let location):
                self.viewModel.unfold(location: location)
                self.scrollTo(location: location, shouldScrollToZero: true)
            }
            
        })
    }
    
    public func showDateAndTimeCreator(location: Int) {
        let point = self.textView.rect(forStringRange: self.textView.selectedRange)?.center ?? self.textView.center
        
        let handleNewDateAndTime: (DateAndTimeType) -> Void = { newDateAndTime in
            let oldSelectedRange = self.textView.selectedRange
            let result = self.viewModel.performAction(EditAction.updateDateAndTime(location, newDateAndTime), textView: self.textView)
            self.textView.selectedRange = oldSelectedRange.offset(result.delta)
            self.viewModel.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: nil,
                                                                                 newDateAndTime: newDateAndTime))
        }
        
        let handleDeleteDateAndTime: () -> Void = {
            self.viewModel.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: nil,
                                                                                 newDateAndTime: nil))
        }
        
        let actionsViewController = ActionsViewController()
        actionsViewController.addAction(icon: nil, title: L10n.Document.DateAndTime.schedule, action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.context.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.schedule, current: nil, point: point, from: self.textView, add: { newDateAndTime in
                    newDateAndTime.isSchedule = true
                    handleNewDateAndTime(newDateAndTime)
                }, delete: {
                    handleDeleteDateAndTime()
                }, cancel: {})
            })
        })
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.DateAndTime.due, action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.context.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.due, current: nil, point: point, from: self.textView, add: { newDateAndTime in
                    newDateAndTime.isDue = true
                    handleNewDateAndTime(newDateAndTime)
                }, delete: {
                    handleDeleteDateAndTime()
                }, cancel: {})
            })
        })
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.DateAndTime.title, action: { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.context.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.title, current: nil, point: point, from: self.textView, add: { newDateAndTime in
                    handleNewDateAndTime(newDateAndTime)
                }, delete: {
                    handleDeleteDateAndTime()
                }, cancel: {})
            })
        })
        
        actionsViewController.addAction(icon: nil, title: L10n.Document.Edit.Action.Help.dateAndTime, style: .highlight, action: { viewController in
            viewController.dismiss(animated: true, completion: {
                HelpPage.dateAndTime.open(from: self)
            })
        })
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        actionsViewController.present(from: self, at: self.textView, location: point)
    }
    
    public func showPriorityEditor(location: Int, current: String?) {
        let actionsController = ActionsViewController()
        actionsController.title = current ?? L10n.Document.Priority.title
        
        let priorities = self.viewModel.dependency.settingAccessor.priorities.filter { $0 != current }
        
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
            actionsController.addAction(icon: nil, title: L10n.Document.Priority.remove, style: .warning) { (viewController) in
                viewController.dismiss(animated: true, completion: {
                    let oldSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.changePriority(nil, location), textView: self.textView)
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                })
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        if let priorityRange = self.viewModel.heading(at: location)?.priority, let location = self.textView.rect(forStringRange: priorityRange) {
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else if let headingRange = self.viewModel.heading(at: location)?.range, let location = self.textView.rect(forStringRange: headingRange) {
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsController.present(from: self)
        }
    }
    
    // 编辑和选择标签
    public func showTagEditor(location: Int) {
        let tags = self.viewModel.tags(at: location) // 当前选中的所有 tag
        
        let actionsViewController = ActionsViewController()
        actionsViewController.title = L10n.Document.Edit.Tag.title
        var location = location
        
        for tag in tags {
            actionsViewController.addAction(icon: Asset.SFSymbols.xmark.image.fill(color: InterfaceTheme.Color.warning), title: tag) { actionViewController in
                
                let oldSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.removeTag(tag, location), textView: self.textView)
                if self.textView.selectedRange.location > location {
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }
                
                actionViewController.removeAction(with: tag)
                location -= tag.count // 删除 tag 后，当前光标所在的位置减去对应 tag 字符串的长度
                self.viewModel.dependency.eventObserver.emit(TagDeleteEvent(tag: tag)) // 更新已保存的 tag
            }
        }
        
        actionsViewController.setCancel {
            $0.dismiss(animated: true, completion: nil)
        }
        
        // 选择一个已经存在的标签
        actionsViewController.addAction(icon: Asset.SFSymbols.tag.image.fill(color: InterfaceTheme.Color.interactive), title: L10n.Document.Edit.Tag.choose, style: .highlight) { viewController in
            viewController.dismiss(animated: true, completion: {
                let selector = SelectorViewController()
                selector.title = L10n.Document.Edit.Tag.title
                
                if let allTags = self.viewModel.context.coordinator?.loadAllTags() {
                    for tag in allTags {
                        selector.addItem(title: tag, enabled: !tags.contains(tag))
                    }
                }
                
                selector.onCancel = {
                    $0.dismiss(animated: true)
                }
                
                selector.onSelection = { index, viewController in
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
                
                if let range = self.viewModel.heading(at: location)?.range {
                    selector.present(from: self, at: self.textView, location: self.textView.rect(forStringRange: range)?.center)
                }
                
            })
            
        }
        
        // 添加新的标签
        actionsViewController.addAction(icon: Asset.SFSymbols.plus.image.fill(color: InterfaceTheme.Color.interactive), title: L10n.Document.Edit.Tag.add, style: .highlight) { actionViewController in
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
                            
                            self.viewModel.dependency.eventObserver.emit(TagAddedEvent(tag: newTagName))
                        })
                    }
                }
                
                formController.onCancel = {
                    $0.dismiss(animated: true, completion: nil)
                }
                
                formController.present(from: self, at: self.textView, location: self.textView.rect(forStringRange: NSRange(location: location, length: 0))?.origin)
            })
        }
        
        if let priorityRange = self.viewModel.heading(at: location)?.tags, let location = self.textView.rect(forStringRange: priorityRange) {
            actionsViewController.present(from: self, at: self.textView, location: location.center)
        } else if let headingRange = self.viewModel.heading(at: location)?.range, let location = self.textView.rect(forStringRange: headingRange){
            actionsViewController.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsViewController.present(from: self)
        }
    }
    
    public func showCapturedItemList(location: Int) {
        self.viewModel.context.coordinator?.showCapturedList { [weak self] attachment in
            
            guard let strongSelf = self else { return }
            
            let _ = strongSelf.viewModel.performAction(EditAction.addAttachment(strongSelf.textView.selectedRange,
                                                                                attachment.key,
                                                                                attachment.kind.rawValue),
                                                       textView: strongSelf.textView)
        }
    }
    
    public func showAllAttachmentPicker(location: Int) {
        self.viewModel.context.coordinator?.showAllAttachmentPicker { [weak self] attachment in
            
            guard let strongSelf = self else { return }
            
            let _ = strongSelf.viewModel.performAction(EditAction.addAttachment(strongSelf.textView.selectedRange,
                                                                                attachment.key,
                                                                                attachment.kind.rawValue),
                                                       textView: strongSelf.textView)
        }
    }
    
    public func showPlanningSelector(location: Int, current: String?) {
        let allPlannings = self.viewModel.dependency.settingAccessor.allPlannings.filter { $0 != current }
        
        let actionsController = ActionsViewController()
        
        actionsController.title = current ?? L10n.Document.Planning.title
        
        for planning in allPlannings {
            actionsController.addAction(icon: nil, title: planning) { viewController in
                let oldSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changePlanning(planning, location),
                                                          textView: self.textView)
                self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                
                viewController.dismiss(animated: true)
            }
        }
        
        if let current = current {
            actionsController.addAction(icon: Asset.SFSymbols.xmark.image.fill(color: InterfaceTheme.Color.warning),
                                        title: L10n.General.Button.Title.delete + " \"\(current)\"",
                                        style: .warning) { viewController in
                                            let oldSelectedRange = self.textView.selectedRange
                                            let result = self.viewModel.performAction(EditAction.removePlanning(location),
                                                                                      textView: self.textView)
                                            self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                                            
                                            viewController.dismiss(animated: true, completion: nil)
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        if let priorityRange = self.viewModel.heading(at: location)?.planning, let location = self.textView.rect(forStringRange: priorityRange) {
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else if let headingRange = self.viewModel.heading(at: location)?.range, let location = self.textView.rect(forStringRange: headingRange){
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsController.present(from: self)
        }
    }
    
    public func showParagraphActions(at location: Int, point: CGPoint? = nil) {
        let actionsController = ActionsViewController()
        actionsController.title = L10n.Document.Edit.Action.Paragraph.title
        
        actionsController.addActionAutoDismiss(icon: nil, title: L10n.Key.Command.foldOthersExcpet) {
            self.viewModel.foldOtherHeadings(except: self.textView.selectedRange.location)
        }
        
        actionsController.addSperator()
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.moveTo) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.context.coordinator?.showOutline(ignoredHeadingLocation: location,
                                                                from: self.view,
                                                                point: self.textView.rect(forStringRange: self.textView.selectedRange)?.origin,
                                                                completion: { [unowned self] outlineLocation in
                    let oldLocation = self.textView.selectedRange.location
                    
                    let result = self.viewModel.moveParagraph(contains: oldLocation, to: outlineLocation, textView: self.textView)
                    
                    guard result.content != nil else { return }
                    
                    var location: Int!
                    var insertionLength: Int = 0
                    switch outlineLocation {
                    case .heading(let heading):
                        location = heading.location
                        insertionLength = heading.length
                    case .position(let _location): location = _location
                    }
                    
                    let changedLength = oldLocation < location ? -result.content!.count : 0 // 如果新的位置的 heading 在原来 heading 的前面，新的位置的 heading需要减掉移走的文字的长度
                    self.textView.selectedRange = NSRange(location: location + insertionLength + changedLength, length: 0)
                })
            })
        }
        
        if self.viewModel.isMember {
            actionsController.addAction(icon: nil, title: L10n.Document.Heading.moveToAnotherDocument) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let oldLocation = self.textView.selectedRange.location
                    self.viewModel.context.coordinator?.showDocumentHeadingPicker(completion: { [unowned self] documentInfo, outlineLocation in
                        self.viewModel.moveParagraphToOtherDocument(url: documentInfo.url, outline: outlineLocation, location: location, textView: self.textView, completion: { [unowned self] result in
                            
                            guard result.content != nil else { return }
                            
                            var location: Int!
                            switch outlineLocation {
                            case .heading(let heading):
                                location = heading.location
                            case .position(let _location):
                                location = _location
                            }
                            
                            let changedLength = oldLocation > location ? -result.content!.count : 0 // 如果新的位置的 heading 在原来 heading 的前面，新的位置的 heading需要减掉移走的文字的长度
                            self.textView.selectedRange = NSRange(location: oldLocation + changedLength, length: 0)
                        })
                    })
                })
            }
        } else {
            actionsController.addAction(icon: Asset.Assets.proLabel.image, title: L10n.Document.Heading.moveToAnotherDocument) { [unowned self] viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.context.coordinator?.showMembership()
                })
            }
        }
        
        if self.viewModel.isMember {
            actionsController.addAction(icon: nil, title: L10n.Document.Edit.Action.Section.delete) { [unowned self] viewController in
                viewController.dismiss(animated: true, completion: {
                    let comfirm = ConfirmViewController(contentText: L10n.Document.Edit.Action.Section.delete, onConfirm: { viewController in
                        viewController.dismiss(animated: true) {
                            let result = self.viewModel.performAction(EditAction.deleteSection(self.textView.selectedRange.location), textView: self.textView)
                            self.textView.selectedRange = NSRange(location: result.range!.location, length: 0)
                        }
                    }) { viewController in
                        viewController.dismiss(animated: true)
                    }
                    
                    comfirm.present(from: self,
                                    at: self.textView,
                                    location: self.textView.rect(forStringRange: self.textView.selectedRange)?.origin)
                })
            }
        } else {
            actionsController.addAction(icon: Asset.Assets.proLabel.image, title: L10n.Document.Edit.Action.Section.delete) { [unowned self] viewController in
                viewController.dismiss(animated: true, completion: {
                    self.viewModel.context.coordinator?.showMembership()
                })
            }
        }
        
        actionsController.addSperator()
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.addNewEntryAtBegining) { viewController in
            viewController.dismiss(animated: true) {
                let result = self.viewModel.performAction(EditAction.addSameLevelHeadingAbove(0), textView: self.textView)
                self.textView.selectedRange = NSRange(location: result.range!.upperBound - 1, length: 0)
            }
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.addHeadingAboveIt) { viewController in
            viewController.dismiss(animated: true) {
                let result = self.viewModel.performAction(EditAction.addSameLevelHeadingAbove(location), textView: self.textView)
                self.textView.selectedRange = NSRange(location: result.range!.upperBound - 1, length: 0)
            }
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.addHeadingBelowIt) { viewController in
            viewController.dismiss(animated: true) {
                let result = self.viewModel.performAction(EditAction.addSameLevelHeadingAfterCurrentHeading(location), textView: self.textView)
                self.textView.selectedRange = NSRange(location: result.range!.upperBound - 1, length: 0) // move one position back, so user can start type heading text
            }
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.addSubHeadingBelow) { viewController in
            viewController.dismiss(animated: true) {
                let result = self.viewModel.performAction(EditAction.addSubHeadingAfterCurrentHeading(location), textView: self.textView)
                self.textView.selectedRange = NSRange(location: result.range!.upperBound - 1, length: 0) // move one position back, so user can start type heading text
            }
        }
        
        actionsController.addAction(icon: nil, title: L10n.Document.Heading.addNewEntryAtEnd) { viewController in
            viewController.dismiss(animated: true) {
                let result = self.viewModel.performAction(EditAction.addHeadingAtBottom, textView: self.textView)
                self.textView.selectedRange = NSRange(location: result.range!.upperBound - 1, length: 0) // move one position back, so user can start type heading text
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        if let passedInPoint = point {
            actionsController.present(from: self, at: self.textView, location: passedInPoint)
        } else if let location = self.textView.rect(forStringRange: self.textView.selectedRange) {
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else if let headingRange = self.viewModel.heading(at: location)?.range, let location = self.textView.rect(forStringRange: headingRange){
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsController.present(from: self)
        }
    }
    
    public func showHeadingActions(at location: Int, isHeading: Bool) {
        let actionsController = ActionsViewController()
        actionsController.title = L10n.Document.Heading.title
        
        if isHeading {
            actionsController.addActionAutoDismiss(icon: nil, title: L10n.Document.Heading.toParagraphContent) {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.convertHeadingToParagraph(location), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            }
            
            actionsController.addActionAutoDismiss(icon: nil, title: L10n.Document.Edit.Heading.Convert._1) {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changeHeadingLevel(location, 1), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            }
            
            actionsController.addActionAutoDismiss(icon: nil, title: L10n.Document.Edit.Heading.Convert._2) {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changeHeadingLevel(location, 2), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            }
            
            actionsController.addActionAutoDismiss(icon: nil, title: L10n.Document.Edit.Heading.Convert._3) {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changeHeadingLevel(location, 3), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            }
            
            actionsController.addActionAutoDismiss(icon: nil, title: L10n.Document.Edit.Heading.Convert._4) {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changeHeadingLevel(location, 4), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            }
            
            actionsController.addActionAutoDismiss(icon: nil, title: L10n.Document.Edit.Heading.Convert._5) {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changeHeadingLevel(location, 5), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            }
            
            actionsController.addActionAutoDismiss(icon: nil, title: L10n.Document.Edit.Heading.Convert._6) {
                let lastSelectedRange = self.textView.selectedRange
                let result = self.viewModel.performAction(EditAction.changeHeadingLevel(location, 6), textView: self.textView)
                self.textView.selectedRange = lastSelectedRange.offset(result.delta)
            }
        } else {
            actionsController.addAction(icon: nil, title: L10n.Document.Heading.toHeading) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let lastSelectedRange = self.textView.selectedRange
                    let result = self.viewModel.performAction(EditAction.convertToHeading(location), textView: self.textView)
                    self.textView.selectedRange = lastSelectedRange.offset(result.delta)
                })
            }
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        if let location = self.textView.rect(forStringRange: self.textView.selectedRange) {
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else if let headingRange = self.viewModel.heading(at: location)?.range, let location = self.textView.rect(forStringRange: headingRange){
            actionsController.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsController.present(from: self)
        }
    }
    
    func pickAttachment(selectedRange: NSRange) {
        let actionsViewController = ActionsViewController()
        
        Attachment.Kind.allCases.forEach { attachment in
            let haveAccess = !attachment.isMemberFunction || self.viewModel.isMember
            var icon = attachment.icon
            if !haveAccess {
                icon = attachment.icon.addSubImage(Asset.Assets.proLabel.image.translation(offset: CGPoint(x: 0, y: 10)))
            }
            
            actionsViewController.addActionAutoDismiss(icon: icon, title: attachment.name) {
                if haveAccess {
                    self.viewModel.context.coordinator?.showAttachmentPicker(from: self.self.viewModel.context.coordinator,
                                                                             kind: attachment,
                                                                             at: self.textView,
                                                                             location: self.textView.rect(forStringRange: self.textView.selectedRange)?.center,
                                                                             accessoryData: [AttachmentCoordinator.kDefaultLinkTitle: self.textView.text.nsstring.substring(with: selectedRange)],
                                                                             complete: { [unowned self] attachmentId in
                                                                                let oldSelection = self.textView.selectedRange
                                                                                let result = self.viewModel.performAction(EditAction.addAttachment(selectedRange,
                                                                                                                                                   attachmentId,
                                                                                                                                                   attachment.rawValue),
                                                                                                                          textView: self.textView)
                                                                                DispatchQueue.runOnMainQueueSafely {
                                                                                    self.textView.selectedRange = oldSelection.offset(result.delta)
                                                                                }
                                                                                
                                                                                // this is special for link, because link here do not need to save attachment file, so delete the attachment
                                                                                if attachment == .link {
                                                                                    self.viewModel.dependency.attachmentManager.delete(key: attachmentId, completion: {}, failure: { _ in })
                                                                                }
                        }, cancel: {})
                } else {
                    self.viewModel.context.coordinator?.showMembership()
                }
            }
        }
        
        actionsViewController.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        if let location = self.textView.rect(forStringRange: self.textView.selectedRange) {
            actionsViewController.present(from: self, at: self.textView, location: location.center)
        } else if let headingRange = self.viewModel.heading(at: selectedRange.location)?.range, let location = self.textView.rect(forStringRange: headingRange){
            actionsViewController.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsViewController.present(from: self)
        }
    }
    
    public func showFileLinkChoose(location: Int, linkRange: NSRange?) {
        self.viewModel.context.coordinator?.showDocumentHeadingPicker(completion: { (documentInfo, outlineLocation) in
            let range = linkRange ?? NSRange(location: location, length: 0)
            let result = self.viewModel.performAction(EditAction.addFileLink(range, documentInfo.url, documentInfo, outlineLocation), textView: self.textView)
            self.textView.selectedRange = NSRange(location: result.delta + location, length: 0)
        })
    }
    
    public func showDocumentLinkTitleEditor(title: String, link: String, from: UIView, location: CGPoint?, completion: @escaping (String?) -> Void) {
        let url = URL.documentBaseURL.appendingPathComponent(OutlineParser.Values.Link.removeScheme(link: link))
        let modalForm = ModalFormViewController()
        modalForm.title = title
        modalForm.addTextFied(title: L10n.CaptureLink.Title.title, placeHoder: L10n.Document.Edit.DocumentLink.title, defaultValue: title)
        modalForm.onSaveValueAutoDismissed = { form in            
            completion(OutlineParser.Values.Link.serializeCustomizednameFileLink(name: form[L10n.CaptureLink.Title.title] as? String ?? title, url: url))
        }
        modalForm.onCancel = {
            $0.dismiss(animated: true) {
                completion(nil)
            }
        }
        modalForm.present(from: self, at: from, location: location)
    }

    public func showHeadingActionsView(at location: Int) {
        print(self.viewModel.getProperties(heading: location))
    }
    
    public func showTemplatesPicker(location: Int) {
        let selector = SelectorViewController()
        
        let dateFormats = ["yyyy/MM/dd", "yyyy MM dd", "yyyy-MM-dd"]
        
        for formate in dateFormats {
            let formatter = DateFormatter()
            formatter.dateFormat = formate
            selector.addItem(title: formatter.string(from: Date()))
        }
                
        selector.onCancel = {
            $0.dismiss(animated: true)
        }
        
        selector.onSelection = { index, viewController in
            
            viewController.dismiss(animated: true) {
                let formatter = DateFormatter()
                formatter.dateFormat = dateFormats[index]
                let string = formatter.string(from: Date())
                
                let result = self.viewModel.performAction(EditAction.replaceText(NSRange(location: location, length: 0), string), textView: self.textView)
                self.textView.selectedRange = NSRange(location: location + result.delta, length: 0)
            }
        }
        
        if let location = self.textView.rect(forStringRange: self.textView.selectedRange) {
            selector.present(from: self, at: self.textView, location: location.center)
        } else if let headingRange = self.viewModel.heading(at: self.textView.selectedRange.location)?.range, let location = self.textView.rect(forStringRange: headingRange){
            selector.present(from: self, at: self.textView, location: location.center)
        } else {
            selector.present(from: self)
        }
    }
}
