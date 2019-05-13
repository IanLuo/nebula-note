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
    @objc public func cancel() {
        self.textView.endEditing(true)
        self.viewModel.save { [unowned self] in
            self.viewModel.close { [unowned self] _ in
                self.viewModel.coordinator?.stop()
            }
        }
    }
    
    @objc public func showInfo() {
        self.viewModel.coordinator?.showDocumentInfo(viewModel: self.viewModel)
    }
    
    @objc public func showMenu() {
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
}
