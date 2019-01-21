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
    
    private let documentManager = DocumentManager()
    private let documentSearchManager = DocumentSearchManager()

    public init(window: UIWindow) {
        self.window = window
        
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        
        super.init(stack: navigationController,
                   context: Context(documentManager: DocumentManager(),
                                    documentSearchManager: DocumentSearchManager(),
                                    editorServiceServer: OutlineEditorServer.instance,
                                    headingTrimmer: OutlineTextTrimmer(parser: OutlineParser())))
        
        self.window?.rootViewController = self.stack
    }
    
    public override func start(from: Coordinator?, animated: Bool) {
        let homeCoord = HomeCoordinator(stack: self.stack,
                                        context: self.context)
        homeCoord.start(from: self, animated: animated)
    }
}

public struct Context {
    let documentManager: DocumentManager
    let documentSearchManager: DocumentSearchManager
    let editorServiceServer: OutlineEditorServer
    let headingTrimmer: OutlineTextTrimmer
}

public class Coordinator {
    private let id: String = UUID().uuidString
    private var children: [Coordinator] = []
    public let stack: UINavigationController
    
    public var viewController: UIViewController?
    
    public weak var parent: Coordinator?
    
    public let context: Context
    
    public init(stack: UINavigationController, context: Context) {
        self.stack = stack
        self.context = context
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
        top.navigationController?.popViewController(animated: true)
    }
    
    open func moveIn(top: UIViewController?, animated: Bool) {
        if let viewController = self.viewController {
            self.stack.pushViewController(viewController, animated: true)
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
        let documentCoordinator = EditorCoordinator(stack: self.stack, context: self.context, usage: EditorCoordinator.Usage.editor(url, location))
        documentCoordinator.start(from: self)
    }
}
