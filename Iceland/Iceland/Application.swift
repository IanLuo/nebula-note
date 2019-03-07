//
//  Application.swift
//  Iceland
//
//  Created by ian luo on 2018/11/10.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public class Application: Coordinator {
    weak var window: UIWindow?
    private let _entranceWindow: CaptureGlobalEntranceWindow

    public init(window: UIWindow) {
        self.window = window
        
        _entranceWindow = CaptureGlobalEntranceWindow(frame: CGRect(x: UIScreen.main.bounds.width - 90, y: UIScreen.main.bounds.height - 90, width: 60, height: 60))
        _entranceWindow.makeKeyAndVisible()
        
        let navigationController = UINavigationController()
        navigationController.navigationBar.barTintColor = InterfaceTheme.Color.background1
        navigationController.navigationBar.tintColor = InterfaceTheme.Color.interactive
        
        let eventObserver = EventObserver()
        let editorContext = EditorContext(eventObserver: eventObserver)
        
        super.init(stack: navigationController,
                   dependency: Dependency(documentManager: DocumentManager(editorContext: editorContext,
                                                                           eventObserver: eventObserver),
                                          documentSearchManager: DocumentSearchManager(eventObserver: eventObserver,
                                                                                       editorContext: editorContext),
                                          editorContext: editorContext,
                                          textTrimmer: OutlineTextTrimmer(parser: OutlineParser()),
                                          eventObserver: eventObserver,
                                          globalCaptureEntryWindow: _entranceWindow))
        
        self.window?.rootViewController = self.stack
        
        _entranceWindow.entryAction = { [weak self] in
            self?.showCaptureEntry()
        }
    }
    
    public override func start(from: Coordinator?, animated: Bool) {
        let homeCoord = HomeCoordinator(stack: self.stack,
                                        dependency: self.dependency)
        homeCoord.start(from: self, animated: animated)
        
    }
}

public struct Dependency {
    let documentManager: DocumentManager
    let documentSearchManager: DocumentSearchManager
    let editorContext: EditorContext
    let textTrimmer: OutlineTextTrimmer
    let eventObserver: EventObserver
    weak var globalCaptureEntryWindow: CaptureGlobalEntranceWindow?
}

public class Coordinator {
    private let id: String = UUID().uuidString
    private var children: [Coordinator] = []
    public let stack: UINavigationController

    public var viewController: UIViewController?
    
    public var isModal: Bool = false
    
    public weak var parent: Coordinator?
    
    public let dependency: Dependency
    
    public var isShowing: Bool {
        return self.viewController?.view.window != nil
    }
    
    public init(stack: UINavigationController,
                dependency: Dependency) {
        self.stack = stack
        self.dependency = dependency
    }
    
    public func addChild(_ coord: Coordinator) {
        self.children.append(coord)
        coord.parent = self
    }
    
    public func remove(_ coord: Coordinator) {
        for (index, child) in self.children.enumerated() {
            if child.id == coord.id {
                self.children.remove(at: index)
            }
        }
    }
    
    open func moveOut(top: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if self.stack == parent?.stack {
            self.stack.popViewController(animated: animated)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                completion?()
            }
        } else {
            top.dismiss(animated: animated,
                        completion: completion)
        }
    }
    
    open func moveIn(top: UIViewController?, animated: Bool) {
        if let viewController = self.viewController {
            if self.stack == self.parent?.stack {
                self.stack.pushViewController(viewController,
                                              animated: animated)
            } else {
                self.isModal = true
                self.stack.pushViewController(viewController, animated: false)
                
                self.stack.modalPresentationStyle = viewController.modalPresentationStyle
                self.stack.transitioningDelegate = viewController.transitioningDelegate
                top?.present(self.stack, animated: animated, completion: nil)
            }
        }
    }
    
    @objc public func stop(animated: Bool = true, completion: (() -> Void)? = nil) {
        if let viewController = self.viewController {
            self.moveOut(top: viewController, animated: animated, completion: {
                self.parent?.remove(self)
                completion?()
            })
        }
    }
    
    open func start(from: Coordinator?, animated: Bool = true) {
        if let f = from {
            f.addChild(self)
            self.moveIn(top: f.viewController, animated: animated)
        }
    }
}

extension Coordinator {
    public func openDocument(url: URL, location: Int) {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        
        let documentCoordinator = EditorCoordinator(stack: navigationController, dependency: self.dependency,
                                                    usage: EditorCoordinator.Usage.editor(url, location))
        documentCoordinator.start(from: self)
    }
    
    public func showAttachmentPicker(kind: Attachment.Kind, complete: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        
        let attachmentCoordinator = AttachmentCoordinator(stack: navigationController,
                                                          dependency: self.dependency,
                                                          kind: kind)
        attachmentCoordinator.onSaveAttachment = complete
        attachmentCoordinator.onCancel = cancel
        
        if let topCoordinator = self.topCoordinator {
            attachmentCoordinator.start(from: topCoordinator)
        } else {
            log.error("can't find a coordinator to start")
        }
    }
    
    public func showCaptureEntry() {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true

        let captureCoordinator = CaptureCoordinator(stack: navigationController, dependency: self.dependency)
        captureCoordinator.delegate = self
        
        if let topCoordinator = self.topCoordinator {
            captureCoordinator.start(from: topCoordinator)
            self.dependency.globalCaptureEntryWindow?.hide()
        } else {
            log.error("can't find a coordinator to start")
        }
    }
    
    public var topCoordinator: Coordinator? {
        for child in self.children {
            if child.isShowing {
                return child
            } else {
                return child.topCoordinator
            }
        }
        return nil
    }
}

extension Coordinator: CaptureCoordinatorDelegate {
    public func didCancel(coordinator: CaptureCoordinator) {
        self.dependency.globalCaptureEntryWindow?.show()
    }
    
    public func didSelect(attachmentKind: Attachment.Kind, coordinator: CaptureCoordinator) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
            coordinator.stop {
                self.showAttachmentPicker(kind: attachmentKind, complete: { [weak self] attachmentId in
                    self?.dependency.globalCaptureEntryWindow?.show()
                    coordinator.addAttachment(attachmentId: attachmentId) {
                        self?.dependency.eventObserver.emit(NewCaptureAddedEvent(attachmentId: attachmentId, kind: attachmentKind.rawValue))
                    }
                }, cancel: { [weak self] in
                    self?.dependency.globalCaptureEntryWindow?.show()
                })
            }
        }
    }
}
