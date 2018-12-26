//
//  Application.swift
//  Iceland
//
//  Created by ian luo on 2018/11/10.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class Application: Coordinator {
    weak var window: UIWindow?
    
    private let documentManager = DocumentManager()
    private let documentSearchManager = DocumentSearchManager()

    public init(window: UIWindow) {
        self.window = window
        
        super.init(stack: UINavigationController())
        
        self.window?.rootViewController = self.stack
    }
    
    public override func start() {
        let documentCoord = DocumentCoordinator(stack: self.stack,
                                                usage: .pickDocument,
                                                documentManager: documentManager,
                                                documentSearchManager: documentSearchManager)
        self.addChild(documentCoord)
        documentCoord.start()
    }
}

public class Coordinator {
    private let id: String = UUID().uuidString
    private var children: [Coordinator] = []
    public let stack: UINavigationController
    
    public init(stack: UINavigationController) {
        self.stack = stack
    }
    
    public func addChild(_ coord: Coordinator) {
        self.children.append(coord)
    }
    
    public func remove(_ coord: Coordinator) {
        for (index, child) in self.children.enumerated() {
            if child.id == coord.id {
                self.children.remove(at: index)
            }
        }
    }
    
    public func start() { fatalError("子类必须重载这个方法") }
}
