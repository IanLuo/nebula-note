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
        
        _entranceWindow = CaptureGlobalEntranceWindow(frame: CGRect(x: UIScreen.main.bounds.width - 90,
                                                                    y: UIScreen.main.bounds.height - 90 - window.safeArea.bottom,
                                                                    width: 60,
                                                                    height: 60))
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
            self?.showCaptureEntrance()
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
    
    /// modal level
    public private(set) var level: Int = 0
    
    /// navigation index
    public private(set) var index: Int = 0

    public var viewController: UIViewController?
    
    public var isModal: Bool = false
    
    public weak var parent: Coordinator?
    
    // 临时显示的 view controller，比如 alert, actions 等
    public var tempViewControllers: [UIViewController] = []
    
    public let dependency: Dependency
    
    public var isShowing: Bool {
        return self.topViewController?.view.window != nil
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
            self.stack.presentingViewController?.dismiss(animated: animated,
                               completion: completion)
        }
    }
    
    open func moveIn(top: UIViewController?, animated: Bool) {
        if let viewController = self.viewController {
            if self.stack == self.parent?.stack {
                self.stack.pushViewController(viewController,
                                              animated: animated)
                
                self.index = self.parent!.index + 1
            } else { // means it's a modal
                self.isModal = true
                self.stack.pushViewController(viewController,
                                              animated: false)
                
                self.stack.modalPresentationStyle = viewController.modalPresentationStyle
                self.stack.transitioningDelegate = viewController.transitioningDelegate
                
                top?.present(self.stack, animated: animated, completion: nil)
                
                self.level = self.parent!.level + 1
            }
        }
    }
    
    @objc public func stop(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.tempViewControllers.forEach { $0.dismiss(animated: false, completion: nil) }
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
            self.moveIn(top: f.topViewController, animated: animated)
        }
    }
}

extension Coordinator {
    public func addToTemp(viewController: UIViewController) {
        self.tempViewControllers.append(viewController)
    }
    
    public func removeFromTemp(viewController: UIViewController) {
        for (index, v) in self.tempViewControllers.enumerated() {
            if v == viewController {
                self.tempViewControllers.remove(at: index)
                return
            }
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
    
    public func showCaptureEntrance() {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true

        let captureCoordinator = CaptureCoordinator(stack: navigationController, dependency: self.dependency)
        captureCoordinator.delegate = self
        
        if let topCoordinator = self.topCoordinator {
            captureCoordinator.start(from: topCoordinator)
            self.dependency.globalCaptureEntryWindow?.hide()
            log.info("showing capture entry on top of: \(topCoordinator)")
        } else {
            log.error("can't find a coordinator to start \n\(self.debugDescription)")
        }
    }
}

extension Coordinator {
    public var topCoordinator: Coordinator? {
        if self.isShowing {
            return self
        } else {
            for child in self.children.reversed() {
                if let top = child.topCoordinator {
                    return top
                }
            }
        }
        
        return nil
    }
    
    // find the top view controller in this coordinator
    public var topViewController: UIViewController? {
        if let presented = self.viewController?.presentedViewController {
            // 当前的 view controller 之上还有 modal view controller，如果在当前 coordinator 范围内，则返回之，否则属于其他的 coordinator，则忽略
            if self.tempViewControllers.contains(presented) {
                return presented
            }
        } else {
            return self.viewController
        }
        
        return nil
    }
}

extension Coordinator {
    public func showTempModal(_ viewController: UIViewController,
                            completion: (() -> Void)? = nil) {
        self.viewController?.present(viewController,
                                     animated: true,
                                     completion: { [weak self] in
                                        self?.addToTemp(viewController: viewController)
                                        completion?()
        })
    }
    
    public func dismisTempModal(_ viewController: UIViewController,
                            completion: (() -> Void)? = nil) {
        viewController.dismiss(animated: true) { [weak self] in
            self?.removeFromTemp(viewController: viewController)
            completion?()
        }
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

extension Coordinator: CustomDebugStringConvertible {
    public var debugDescription: String {
        var string = "\n\(type(of:self)) \(level) \(index)\n\(vcs)"
        for child in self.children {
            string.append("\n | \(child.debugDescription)")
        }
        
        return "\(string)"
    }
    
    private var vcs: String {
        var string = "   ↳ "
        if let vc = self.viewController {
            string.append("\(vc))")
        }
        
        for vc in self.tempViewControllers {
            string.append("\n     + \(vc) +")
        }
        
        return string
    }
}
