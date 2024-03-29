//
//  ViewModelProtocol.swift
//  Iceberg
//
//  Created by ian luo on 2019/12/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public protocol ViewModelProtocol {
    associatedtype CoordinatorType: Coordinator
    var context: ViewModelContext<CoordinatorType>! { get set }
    var dependency: Dependency { get }
    init(coordinator: CoordinatorType)
    init()
    func didSetupContext()
}

extension ViewModelProtocol {
    public func didSetupContext() {}
}

public extension ViewModelProtocol {
    func openDocument(url: URL, location: Int = 0) {
        self.context.coordinator?.openDocument(url: url, location: location)
    }
        
    var isMember: Bool {
        return self.context.dependency.purchaseManager.isMember.value
    }
    
    var dependency: Dependency {
        return self.context.dependency
    }
    
    init(coordinator: CoordinatorType) {
        self.init()
        self.context = ViewModelContext(coordinator: coordinator, dependency: coordinator.dependency)
        self.didSetupContext()
    }
}

public struct ViewModelContext<CoordinatorType: Coordinator> {
    public weak var coordinator: CoordinatorType?
    
    public var dependency: Dependency
}
