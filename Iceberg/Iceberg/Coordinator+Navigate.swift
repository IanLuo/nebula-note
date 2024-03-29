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
        self.dependency.eventObserver.emit(OpenDocumentEvent(url: url, location: location))
        self.dependency.eventObserver.emit(SwitchTabEvent(toTabIndex: 5))
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
//        attachmentCoordinator.fromLocation = location
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
        captureCoordinator.fromView = at ?? UIApplication.shared.windows.first(where: { $0.isHidden == false })
        captureCoordinator.delegate = self
        
        if let topCoordinator = self.topCoordinator {
            captureCoordinator.start(from: topCoordinator)
            log.info("showing capture entry on top of: \(topCoordinator)")
        } else {
            log.error("can't find a coordinator to start \n\(self.debugDescription)")
        }
    }
    
    public func showDateSelector(title: String,
                                 current: DateAndTimeType?,
                                 point: CGPoint? = nil,
                                 from: UIView? = nil,
                                 add: @escaping (DateAndTimeType) -> Void,
                                 delete: @escaping () -> Void,
                                 cancel: @escaping () -> Void) {
        
        let dateAndTimeSelectViewController = DateAndTimeSelectViewController(nibName: "DateAndTimeSelectViewController", bundle: nil)
        dateAndTimeSelectViewController.title = title
        dateAndTimeSelectViewController.passInDateAndTime = current
        dateAndTimeSelectViewController.didSelectAction = { [unowned dateAndTimeSelectViewController] dateAndTime in
            dateAndTimeSelectViewController.dismiss(animated: true)
            
            add(dateAndTime)
            self.dependency.globalCaptureEntryWindow?.modalViewDisappear()
        }
        
        dateAndTimeSelectViewController.didDeleteAction = { [unowned dateAndTimeSelectViewController] in
            dateAndTimeSelectViewController.dismiss(animated: true)
            
            delete()
            self.dependency.globalCaptureEntryWindow?.modalViewDisappear()
        }
        
        dateAndTimeSelectViewController.didCancelAction = { [unowned dateAndTimeSelectViewController] in
            dateAndTimeSelectViewController.dismiss(animated: true)
            
            cancel()
            self.dependency.globalCaptureEntryWindow?.modalViewDisappear()
        }
        
        self.dependency.globalCaptureEntryWindow?.modalViewAppear()
        dateAndTimeSelectViewController.present(from: self.viewController!, at: from, location: point, completion: nil)
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
                exportManager.export(isMember: self.dependency.purchaseManager.isMember.value, url: url, type:exportManager.exportMethods[index], useDefaultStyle: true, completion: { url in
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
    
//    public func toggleDesktopMiddlePart() {
//        (self.rootCoordinator as? Application)?.homeCoordinator?.toggleMiddlePart()
//    }
    
    @available(iOS 13.0, *)
    func enableGlobalNavigateKeyCommands() {
        let binding = KeyBinding()
        
        binding.addAction(for: KeyAction.toggleLeftPart, on: self.viewController, block: {
            self.toggleDesktopLeftPart()
        })
        
//        binding.addAction(for: KeyAction.toggleMiddlePart, on: self.viewController, block: {
//            self.toggleDesktopMiddlePart()
//        })
        
        binding.addAction(for: KeyAction.toggleFullWidth, on: self.viewController, block: {
            self.toggleEditorFullScreen()
        })
        
        binding.addAction(for: KeyAction.captureIdea, on: self.viewController) {
            self.showCaptureEntrance()
        }
        
        binding.addAction(for: KeyAction.agendaTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(.agenda)
        }
        
        binding.addAction(for: KeyAction.ideaTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(.idea)
        }
        
        binding.addAction(for: KeyAction.searchTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(.search)
        }
        
        binding.addAction(for: KeyAction.browserTab, on: self.viewController) {
            (self.rootCoordinator as? Application)?.homeCoordinator?.selectTab(.browser)
        }
        
        binding.addAction(for: KeyAction.cancel, on: self.viewController) {
            if self.rootCoordinator.topMostCoordinator.isModal == true {
                if let topVC = self.topViewController, topVC.presentingViewController != nil {
                    topVC.dismiss(animated: true)
                } else {
                    self.rootCoordinator.topMostCoordinator.stop()
                }
            } else if let topVC = self.topViewController, topVC.presentingViewController != nil {
                topVC.dismiss(animated: true)
            }
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
