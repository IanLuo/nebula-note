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
    
    public init(window: UIWindow) {
        self.window = window
        
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
                                          eventObserver: eventObserver))
        
        self.window?.rootViewController = self.stack
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
}

public class Coordinator {
    private let id: String = UUID().uuidString
    private var children: [Coordinator] = []
    public let stack: UINavigationController
    
    public var viewController: UIViewController?
    
    public var isModal: Bool = false
    
    public weak var parent: Coordinator?
    
    public let dependency: Dependency
    
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
    
    open func moveOut(top: UIViewController, animated: Bool) {
        if self.stack == parent?.stack {
            self.stack.popViewController(animated: animated)
        } else {
            top.dismiss(animated: animated,
                        completion: nil)
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
                top?.present(self.stack, animated: animated, completion: nil)
            }
        }
    }
    
    @objc public func stop(animated: Bool = true) {
        if let viewController = self.viewController {
            self.moveOut(top: viewController, animated: animated)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
                self.parent?.remove(self)
            }
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
    
    public func showAttachmentPicker(type: Attachment.AttachmentType, complete: @escaping (String) -> Void) {
        let attachmentCoordinator = AttachmentCoordinator(stack: self.stack,
                                                          dependency: self.dependency,
                                                          type: type)
        attachmentCoordinator.onSaveAttachment = complete
        attachmentCoordinator.start(from: self)
    }
}
