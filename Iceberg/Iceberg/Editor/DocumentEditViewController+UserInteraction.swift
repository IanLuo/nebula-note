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
import RxSwift

extension DocumentEditorViewController: OutlineTextViewDelegate {
    public func didHandleIdeasFiles(urls: [URL], characterIndex: Int) {
        Observable.from(urls)
            .flatMap { url in
                self.viewModel.dependency.sharedDataHandler
                    .createAttachmentFromIdea(attachmentManager: self.viewModel.dependency.attachmentManager,
                                              url: url)
            }
            .observe(on: MainScheduler())
            .subscribe(onNext: {
                guard let key = $0 else { return }
                guard let attachment = self.viewModel.dependency.attachmentManager.attachment(with: key) else { return }
                _ = self.viewModel.performAction(EditAction.addAttachment(NSRange(location: characterIndex, length: 0), attachment.key, attachment.kind.rawValue), textView: self.textView)
                
                if attachment.kind.displayAsPureText {
                    self.viewModel.dependency.attachmentManager.delete(key: attachment.key, completion: {}, failure: {_ in })
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    public func didTapOnActions(textView: UITextView, characterIndex: Int, point: CGPoint) {
        self.showParagraphActions(at: characterIndex, point: point) 
    }
    
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
        self.viewModel.context.coordinator?.showDateSelector(title: L10n.Document.DateAndTime.update, current: dateAndTime, point: point, from: self.textView, add: { [unowned self] newDateAndTime in
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
            }, cancel: {})
    }
    
    public func didTapOnTags(textView: UITextView, characterIndex: Int, tags: [String], point: CGPoint) {
        self.showTagEditor(location: characterIndex)
    }
    
    public func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String : Any], point: CGPoint) {
        let actionsController: ActionsViewController = ActionsViewController()
        
        actionsController.title = linkStructure["url"] as? String
        
        let linkPath = linkStructure[OutlineParser.Key.Element.Link.url] as? String ?? ""
        let linkTitle = linkStructure[OutlineParser.Key.Element.Link.title] as? String ?? ""
        let isDocumentLink = linkPath.hasPrefix(OutlineParser.Values.Link.x3)
        
        let openLinkText = isDocumentLink ? L10n.Document.Link.openDocumentLink : L10n.Document.Link.open
        let editLinkText = isDocumentLink ? L10n.Document.Link.editDocumentLink : L10n.Document.Link.edit
        let editLinkIcon = isDocumentLink ? Asset.SFSymbols.docTextMagnifyingglass.image.fill(color: InterfaceTheme.Color.descriptive) : Asset.SFSymbols.pencilCircle.image.fill(color: InterfaceTheme.Color.descriptive)
        
        actionsController.addAction(icon: Asset.SFSymbols.arrowRight.image.fill(color: InterfaceTheme.Color.descriptive), title: openLinkText) { viewController in
            viewController.dismiss(animated: true, completion: {
                
                if let link = linkStructure[OutlineParser.Key.Element.Link.url] as? String {
                    if isDocumentLink {
                        self.viewModel.context.coordinator?.openDocumentLink(opener: self.viewModel.url, link: link)
                    } else {
                        if let url = URL(string: linkStructure[OutlineParser.Key.Element.Link.url] as? String ?? "") {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
            })
        }
        
        if isDocumentLink {
            actionsController.addAction(icon: Asset.SFSymbols.pencilCircle.image.fill(color: InterfaceTheme.Color.descriptive), title: L10n.Document.Edit.DocumentLink.title) { viewController in
                viewController.dismiss(animated: true) {
                    let location = textView.rect(forStringRange: textView.selectedRange)?.center
                    for case let linkToken in self.viewModel.tokens(at: characterIndex) where linkToken is LinkToken {
                        self.showDocumentLinkTitleEditor(title: linkTitle, link: linkPath, from: self.textView, location: location) { [unowned self] in
                            if let newLinkString = $0 {
                                let oldSelectedRange = textView.selectedRange
                                let result = self.viewModel.performAction(EditAction.replaceText(linkToken.range, newLinkString), textView: self.textView)
                                textView.selectedRange = oldSelectedRange.offset(result.delta)
                            }
                        }
                    }
                }
            }
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
                        let oldSelectedRange = textView.selectedRange
                        let result = self.viewModel.performAction(EditAction.updateLink(characterIndex, linkString), textView: self.textView)
                        textView.selectedRange = oldSelectedRange.offset(result.delta)
                    })
                }
                
            })
        }
        
        actionsController.setCancel { viewController in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        actionsController.present(from: self, at: self.textView, location: point)
    }
    
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int, point: CGPoint) {
        self.viewModel.foldOrUnfold(location: chracterIndex)
        
        if self.textView.isFirstResponder {
            _ = self.textView.resignFirstResponder()
        }
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: String, point: CGPoint) {
        let oldSelection = textView.selectedRange
        let _ = self.viewModel.performAction(.toggleCheckboxStatus(characterIndex, checkbox),
                                             textView: self.textView)
        
        // recover the selection position
        textView.selectedRange = oldSelection
    }
    
    private func _showAttachmentView(attachment: Attachment, atCharactor: Int) {
        let actionsView = ActionsViewController()

        let view = AttachmentViewFactory.create(attachment: attachment)
        
        let width = isMacOrPad ? 600 : self.view.bounds.width
        view.sizeAnchor(width: width, height: view.size(for: width).height)
        actionsView.preferredWidth = width
        
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
        
        actionsView.addAction(icon: nil, title: L10n.Attachment.preview) { viewController in
            viewController.dismiss(animated: true, completion: {
                let previewViewController = PreviewManager(url: attachment.url).createPreviewController()
                self.present(previewViewController, animated: true)
            })
        }
        
        actionsView.addAction(icon: nil, title: L10n.Attachment.share) { viewController in
            viewController.dismiss(animated: true, completion: {
                let exportManager = ExportManager(editorContext: self.viewModel.dependency.editorContext)
                exportManager.share(from: self, url: attachment.url)
            })
        }
        
        actionsView.addAction(icon: nil, title: L10n.General.Button.Title.close) { viewController in
            viewController.dismiss(animated: true)
        }
        

        actionsView.setCancel { viewController in
            viewController.dismiss(animated: true)
        }
        
        if let location = self.textView.rect(forStringRange: NSRange(location: atCharactor, length: 0)) {
            actionsView.present(from: self, at: self.textView, location: location.center)
        } else {
            actionsView.present(from: self)
        }
    }
    
    public func didTapOnTitle(at: CGPoint) {
        let renameFormViewController = ModalFormViewController()
        let title = L10n.Browser.Action.Rename.newName
        renameFormViewController.title = title
        renameFormViewController.addTextFied(title: title, placeHoder: "", defaultValue: self.viewModel.url.packageName) // 不需要显示 placeholder, default value 有值
        renameFormViewController.onSaveValueAutoDismissed = { [weak self] formValue in
            guard let strongSelf = self else { return }
            if let newName = formValue[title] as? String {
                let oldURL = strongSelf.viewModel.url
                strongSelf.viewModel.rename(to: newName.escaped) { error in
                    if let error = error {
                        log.error(error)
                    } else {
                        log.info("changed document")
                        DispatchQueue.runOnMainQueueSafely {
                            strongSelf.viewModel.context.dependency.settingAccessor.logOpenDocument(url: strongSelf.viewModel.url)
                            strongSelf.textView.setTitle(newName)
                            strongSelf.viewModel.dependency.eventObserver.emit(RenameDocumentEvent(oldUrl: oldURL, newUrl: strongSelf.viewModel.url))
                        }
                    }
                }
            }
        }
        
        // 显示给用户，是否可以使用这个文件名
        renameFormViewController.onValidating = { formData in
            if !self.viewModel.url.isNameAvailable(newName: formData[title] as! String) {
                return [title: L10n.Browser.Action.Rename.Warning.nameIsTaken]
            }
            
            return [:]
        }
        
        renameFormViewController.onCancel = { viewController in
            viewController.dismiss(animated: true)
        }

        renameFormViewController.present(from: self, at: self.textView, location: at)
    }
}
