//
//  Coordinator+Navigate.swift
//  x3Note
//
//  Created by ian luo on 2020/9/6.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import Interface
import Core
import UIKit

extension Coordinator {
    public func openDocument(url: URL, location: Int) {
        let navigationController = Coordinator.createDefaultNavigationControlller(transparentBar: false)
        
        let documentCoordinator = EditorCoordinator(stack: navigationController, dependency: self.dependency,
                                                    usage: EditorCoordinator.Usage.editor(url, location))
        
        documentCoordinator.start(from: self)
        self.dependency.globalCaptureEntryWindow?.isForcedToHide = true
    }
    
    public func showAttachmentPicker(from coordinator: Coordinator? = nil, kind: Attachment.Kind, at: UIView?, location: CGPoint?, accessoryData: [String: Any]? = nil, complete: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        
        switch kind {
        case .video:
            guard UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.rear) || UIImagePickerController.isCameraDeviceAvailable(UIImagePickerController.CameraDevice.front) else {
                let alert = UIAlertController(title: "Camera is not available", message: nil, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.topCoordinator?.viewController?.present(alert, animated: true, completion: nil)
                cancel()
                return
            }
        default: break
        }
        
        
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let attachmentCoordinator = AttachmentCoordinator(stack: navigationController,
                                                          dependency: self.dependency,
                                                          kind: kind,
                                                          at: at, location: location)
        attachmentCoordinator.onSaveAttachment = complete
        attachmentCoordinator.onCancel = cancel
        attachmentCoordinator.fromView = at
        attachmentCoordinator.fromLocation = location
        attachmentCoordinator.accessoryData = accessoryData
        
        if let coordinator = coordinator {
            attachmentCoordinator.start(from: coordinator)
        } else if let topCoordinator = self.topCoordinator {
            attachmentCoordinator.start(from: topCoordinator)
        } else {
            log.error("can't find a coordinator to start")
        }
    }
    
    public func showCaptureEntrance(at: UIView? = nil) {
        let navigationController = Coordinator.createDefaultNavigationControlller()
        
        let captureCoordinator = CaptureCoordinator(stack: navigationController, dependency: self.dependency)
        captureCoordinator.fromView = at
        captureCoordinator.delegate = self
        
        if let topCoordinator = self.topCoordinator {
            captureCoordinator.start(from: topCoordinator)
            self.dependency.globalCaptureEntryWindow?.hide()
            log.info("showing capture entry on top of: \(topCoordinator)")
        } else {
            log.error("can't find a coordinator to start \n\(self.debugDescription)")
        }
    }
    
    public func showDateSelector(title: String,
                                 current: DateAndTimeType?,
                                 add: @escaping (DateAndTimeType) -> Void,
                                 delete: @escaping () -> Void,
                                 cancel: @escaping () -> Void) {
        
        self.dependency.globalCaptureEntryWindow?.hide()
        
        let dateAndTimeSelectViewController = DateAndTimeSelectViewController(nibName: "DateAndTimeSelectViewController", bundle: nil)
        dateAndTimeSelectViewController.title = title
        dateAndTimeSelectViewController.passInDateAndTime = current
        dateAndTimeSelectViewController.didSelectAction = { [unowned dateAndTimeSelectViewController] dateAndTime in
            dateAndTimeSelectViewController.dismiss(animated: true, completion: {
                self.dependency.globalCaptureEntryWindow?.show()
            })
            
            add(dateAndTime)
        }
        
        dateAndTimeSelectViewController.didDeleteAction = { [unowned dateAndTimeSelectViewController] in
            dateAndTimeSelectViewController.dismiss(animated: true, completion: {
                self.dependency.globalCaptureEntryWindow?.show()
            })
            
            delete()
        }
        
        dateAndTimeSelectViewController.didCancelAction = { [unowned dateAndTimeSelectViewController] in
            dateAndTimeSelectViewController.dismiss(animated: true, completion: {
                self.dependency.globalCaptureEntryWindow?.show()
            })
            
            cancel()
        }
        
        self.viewController?.present(dateAndTimeSelectViewController, animated: true, completion: nil)
    }
    
    public func showMembership() {
        let nav = Coordinator.createDefaultNavigationControlller()
        let membershipCoordinator = MembershipCoordinator(stack: nav, dependency: self.dependency)
        membershipCoordinator.start(from: self)
    }
    
    public func showAttachmentManager() {
        let attachmentManagerCoordinator = AttachmentManagerCoordinator(stack: self.stack, dependency: self.dependency)
        attachmentManagerCoordinator.start(from: self)
    }
    
    public func showExportSelector(document url: URL, at: UIView?, complete: @escaping () -> Void) {
        let exportManager = self.dependency.exportManager
        
        let selector = SelectorViewController()
        selector.title = L10n.Document.Export.msg
        for item in exportManager.exportMethods {
            selector.addItem(title: item.title)
        }
        
        selector.onSelection = { index, viewController in
            viewController.dismiss(animated: true, completion: {
                complete()
                exportManager.export(isMember: self.dependency.purchaseManager.isMember.value, url: url, type:exportManager.exportMethods[index], completion: { url in
                    let shareViewController = exportManager.createPreviewController(url: url)
                    self.viewController?.present(shareViewController, animated: true)
                }, failure: { error in
                    // TODO: show error
                })
            })
        }
        
        selector.onCancel = { viewController in
            viewController.dismiss(animated: true, completion: nil)
            complete()
        }
        
        if let viewController = self.viewController {
            selector.present(from: viewController, at: at)
        }
    }
    
    public func toggleEditorFullScreen() {
        (self.rootCoordinator as? Application)?.homeCoordinator?.toggleFullScreen()
    }
    
    public func toggleDesktopLeftPart() {
        (self.rootCoordinator as? Application)?.homeCoordinator?.toggleLeftPart()
    }
    
    public func toggleDesktopMiddlePart() {
        (self.rootCoordinator as? Application)?.homeCoordinator?.toggleMiddlePart()
    }
    
    func enableGlobalNavigateKeyCommands() {
        let binding = KeyBinding()
        
        binding.addAction(for: KeyAction.toggleLeftPart, on: self.viewController, block: {
            self.toggleDesktopLeftPart()
        })
        
        binding.addAction(for: KeyAction.toggleMiddlePart, on: self.viewController, block: {
            self.toggleDesktopMiddlePart()
        })
        
        binding.addAction(for: KeyAction.toggleFullWidth, on: self.viewController, block: {
            self.toggleEditorFullScreen()
        })
        
        binding.addAction(for: KeyAction.captureIdea, on: self.viewController) {
            self.showCaptureEntrance()
        }
        
        binding.addAction(for: KeyAction.agendaTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(at: 0)
        }
        
        binding.addAction(for: KeyAction.ideaTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(at: 1)
        }
        
        binding.addAction(for: KeyAction.searchTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(at: 2)
        }
        
        binding.addAction(for: KeyAction.browserTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(at: 3)
        }
    }
}

extension Array where Element == UIKeyCommand {
    static public func +=(lhs: inout [Element], rhs: Element) {
        lhs.append(rhs)
    }
    
    static public func +=(lhs: inout [Element], rhs: [Element]) {
        lhs.append(contentsOf: rhs)
    }
}
