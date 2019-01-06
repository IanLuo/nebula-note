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
        
        super.init(stack: UINavigationController())
        
        self.window?.rootViewController = self.stack
    }
    
    public override func start(from: Coordinator?) {
        let homeCoord = HomeCoordinator(stack: self.stack)
        homeCoord.start(from: self)
    }
}

public class Coordinator {
    private let id: String = UUID().uuidString
    private var children: [Coordinator] = []
    public let stack: UINavigationController
    
    public var viewController: UIViewController?
    
    public weak var parent: Coordinator?
    
    public init(stack: UINavigationController) {
        self.stack = stack
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
    
    open func moveOut() {
        self.viewController?.navigationController?.popViewController(animated: true)
    }
    
    open func moveIn() {
        if let viewController = self.viewController {
            self.stack.pushViewController(viewController, animated: true)
        }
    }
    
    public func stop() {
        self.moveOut()
        self.parent?.remove(self)
    }
    
    open func start(from: Coordinator?) {
        if let f = from {
            f.addChild(self)
        }
        
        self.moveIn()
    }
}
