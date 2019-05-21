//
//  DocumentEditViewController_TextViewDelegate.swift
//  Iceland
//
//  Created by ian luo on 2019/5/10.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Business
import Interface

extension DocumentEditViewController: OutlineTextViewDelegate {
    public func didTapOnAttachment(textView: UITextView, characterIndex: Int, type: String, value: String, point: CGPoint) {
        self.viewModel.coordinator?.dependency.attachmentManager.attachment(with: value, completion: { [weak self] attachment in
            self?._showAttachmentView(attachment: attachment)
        }, failure: { error in
            
        })
    }
    
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
        self.viewModel.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.update, current: dateAndTime, add: { [unowned self] newDateAndTime in
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
        actionsController.addAction(icon: Asset.Assets.right.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.Document.Link.open) { viewController in
            viewController.dismiss(animated: true, completion: {
                if let url = URL(string: linkStructure[OutlineParser.Key.Element.Link.url]!) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
        }
        
        actionsController.addAction(icon: Asset.Assets.add.image, title: L10n.Document.Link.edit) { viewController in
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
    
    private func _showAttachmentView(attachment: Attachment) {
        let actionsView = ActionsViewController()

        let view = AttachmentViewFactory.create(attachment: attachment)
        view.sizeAnchor(width: self.view.bounds.width, height: view.size(for: self.view.bounds.width).height)
        
        actionsView.accessoryView = view
        actionsView.title = attachment.kind.rawValue
        
        actionsView.addAction(icon: nil, title: L10n.General.Button.Title.close) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        actionsView.setCancel { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        self.present(actionsView, animated: true, completion: nil)
        self.viewModel.coordinator?.dependency.globalCaptureEntryWindow?.hide()
    }
}
