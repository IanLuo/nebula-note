//
//  DocumentEditViewController_TextViewDelegate.swift
//  Iceland
//
//  Created by ian luo on 2019/5/10.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Core
import Interface
import CoreLocation
import MapKit

extension DocumentEditorViewController: OutlineTextViewDelegate {
    public func didTapOnAttachment(textView: UITextView, characterIndex: Int, type: String, value: String, point: CGPoint) {
        self.viewModel.dependency.attachmentManager.attachment(with: value, completion: { [weak self] attachment in
            self?._showAttachmentView(attachment: attachment, atCharactor: characterIndex)
        }, failure: { error in
            
        })
    }
    
    public func didTapOnHiddenAttachment(textView: UITextView, characterIndex: Int, point: CGPoint) {
        // 1. find the first topest unfoled heading, and use that to unfold
         
        var currentCheckCharacterIndex = characterIndex
        while let parent = self.viewModel.parentHeading(at: currentCheckCharacterIndex), self.viewModel.isSectionFolded(at: parent.range.location) {
            currentCheckCharacterIndex = parent.range.location
        }
        
        self.viewModel.foldOrUnfold(location: currentCheckCharacterIndex)
        
        if self.textView.isFirstResponder {
            if let heading = self.viewModel.heading(at: characterIndex) {
                self.textView.selectedRange = heading.range.tail(0)
            }
        }
    }
    
    public func didTapOnPriority(textView: UITextView, characterIndex: Int, priority: String, point: CGPoint) {
        self.showPriorityEditor(location: characterIndex, current: priority)
    }
    
    public func didTapOnPlanning(textView: UITextView, characterIndex: Int, planning: String, point: CGPoint) {
        self.showPlanningSelector(location: characterIndex, current: planning)
    }
    
    public func didTapDateAndTime(textView: UITextView, characterIndex: Int, dateAndTimeString: String, point: CGPoint) {
        let dateAndTime = DateAndTimeType(dateAndTimeString)!
        self.viewModel.context.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.update, current: dateAndTime, add: { [unowned self] newDateAndTime in
            self.viewModel.dependency.globalCaptureEntryWindow?.show()
            
            let oldSelectedRange = textView.selectedRange
            let result = self.viewModel.performAction(EditAction.updateDateAndTime(characterIndex, newDateAndTime), textView: self.textView)
            if self.textView.selectedRange.location > characterIndex {
                self.textView.selectedRange = oldSelectedRange.offset(result.delta)
            }
            
            self.viewModel.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: dateAndTime,
                                                                                 newDateAndTime: newDateAndTime))
            }, delete: {
                let oldSelectedRange = textView.selectedRange
                let result = self.viewModel.performAction(EditAction.updateDateAndTime(characterIndex, nil), textView: self.textView)
                if self.textView.selectedRange.location > characterIndex {
                    self.textView.selectedRange = oldSelectedRange.offset(result.delta)
                }
                
                self.viewModel.dependency.eventObserver.emit(DateAndTimeChangedEvent(oldDateAndTime: dateAndTime,
                                                                                                  newDateAndTime: nil))
        }, cancel: { [weak self] in
            self?.viewModel.dependency.globalCaptureEntryWindow?.show()
        })
        
        self.viewModel.dependency.globalCaptureEntryWindow?.hide()
    }
    
    public func didTapOnTags(textView: UITextView, characterIndex: Int, tags: [String], point: CGPoint) {
        self.showTagEditor(location: characterIndex)
    }
    
    public func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String : Any], point: CGPoint) {
        let actionsController = ActionsViewController()
        
        actionsController.title = linkStructure["url"] as? String
        
        let linkPath = linkStructure[OutlineParser.Key.Element.Link.url] as? String ?? ""
        let linkTitle = linkStructure[OutlineParser.Key.Element.Link.title] as? String ?? ""
        let isDocumentLink = linkPath.hasPrefix(OutlineParser.Values.Link.x3)
        
        let openLinkText = isDocumentLink ? L10n.Document.Link.openDocumentLink : L10n.Document.Link.open
        let editLinkText = isDocumentLink ? L10n.Document.Link.editDocumentLink : L10n.Document.Link.edit
        let editLinkIcon = isDocumentLink ? Asset.Assets.fileLink.image.fill(color: InterfaceTheme.Color.descriptive) : Asset.Assets.edit.image.fill(color: InterfaceTheme.Color.descriptive)
        
        actionsController.addAction(icon: Asset.Assets.right.image.fill(color: InterfaceTheme.Color.descriptive), title: openLinkText) { viewController in
            viewController.dismiss(animated: true, completion: {
                
                if let link = linkStructure[OutlineParser.Key.Element.Link.url] as? String {
                    if isDocumentLink {
                        self.viewModel.context.coordinator?.openDocumentLink(link: link)
                    } else {
                        if let url = URL(string: linkStructure[OutlineParser.Key.Element.Link.url] as? String ?? "") {
                            self.viewModel.dependency.globalCaptureEntryWindow?.show()
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            })
        }
        
        actionsController.addAction(icon: editLinkIcon, title: editLinkText) { viewController in
            viewController.dismiss(animated: true, completion: {
                let location = textView.rect(forStringRange: textView.selectedRange)?.center
                
                if isDocumentLink { // 编辑文档连接
                    for case let linkToken in self.viewModel.tokens(at: characterIndex) where linkToken is LinkToken {
                        self.showFileLinkChoose(location: characterIndex, linkRange: linkToken.range)
                    }
                } else { // 编辑普通连接
                    self.viewModel.context.coordinator?.showLinkEditor(title: linkTitle, url: linkPath, from: self.textView, location: location, completeEdit: { [unowned self] linkString in
                        self.viewModel.dependency.globalCaptureEntryWindow?.show()
                        let oldSelectedRange = textView.selectedRange
                        let result = self.viewModel.performAction(EditAction.updateLink(characterIndex, linkString), textView: self.textView)
                        textView.selectedRange = oldSelectedRange.offset(result.delta)
                    })
                }
                
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
            self.viewModel.dependency.globalCaptureEntryWindow?.show()
        }
        
        actionsController.present(from: self, at: self.textView, location: point)

        self.viewModel.dependency.globalCaptureEntryWindow?.hide()
    }
    
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int, point: CGPoint) {
        self.viewModel.foldOrUnfold(location: chracterIndex)
        
        if self.textView.isFirstResponder {
            if let heading = self.viewModel.heading(at: chracterIndex) {
                self.textView.selectedRange = heading.range.tail(0)
            }
        }
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: String, point: CGPoint) {
        let _ = self.viewModel.performAction(.toggleCheckboxStatus(characterIndex, checkbox),
                                             textView: self.textView)
    }
    
    private func _showAttachmentView(attachment: Attachment, atCharactor: Int) {
        let actionsView = ActionsViewController()

        let view = AttachmentViewFactory.create(attachment: attachment)
        view.sizeAnchor(width: self.view.bounds.width, height: view.size(for: self.view.bounds.width).height)
        
        actionsView.accessoryView = view
        actionsView.title = attachment.kind.name
        
        if attachment.kind == .location {
            actionsView.addAction(icon: nil, title: L10n.CaptureList.Action.openLocation) { viewController in
                viewController.dismiss(animated: true, completion: {
                    let jsonDecoder = JSONDecoder()
                    do {
                        let coord = try jsonDecoder.decode(CLLocationCoordinate2D.self, from: try Data(contentsOf: attachment.url))
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord, addressDictionary:nil))
                        mapItem.openInMaps(launchOptions: [:])
                    } catch {
                        log.error("\(error)")
                    }
                })
            }
        } else if attachment.kind == .image || attachment.kind == .sketch {
            actionsView.addAction(icon: nil, title: L10n.Document.Edit.Image.useAsCover) { viewController in
                viewController.dismiss(animated: true) {
                    self.viewModel.dependency.documentManager.setCover(UIImage(contentsOfFile: attachment.url.path), url: self.viewModel.url, completion: { [weak self] _ in
                        self?.toastSuccess()
                    })
                }
            }
        }
        
        actionsView.addAction(icon: nil, title: L10n.Attachment.share) { viewController in
            viewController.dismiss(animated: true, completion: {
                let exportManager = ExportManager(editorContext: self.viewModel.dependency.editorContext)
                exportManager.share(from: self, url: attachment.url)
                self.viewModel.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        actionsView.addAction(icon: nil, title: L10n.General.Button.Title.close) { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.dependency.globalCaptureEntryWindow?.show()
            })
        }
        

        actionsView.setCancel { viewController in
            viewController.dismiss(animated: true, completion: {
                self.viewModel.dependency.globalCaptureEntryWindow?.show()
            })
        }
        
        if let location = self.textView.rect(forStringRange: NSRange(location: atCharactor, length: 0)) {
            actionsView.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsView.present(from: self)
        }

        self.viewModel.dependency.globalCaptureEntryWindow?.hide()
    }
}
