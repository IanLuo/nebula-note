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
    init(coordinator: CoordinatorType)
    init()
}

public extension ViewModelProtocol {
    func openDocument(url: URL, location: Int = 0) {
        self.context.coordinator!.openDocument(url: url, location: location)
    }
    
    func hideGlobalCaptureEntry() {
        self.context.coordinator!.dependency.globalCaptureEntryWindow?.hide()
    }
    
    func showGlobalCaptureEntry() {
        self.context.coordinator!.dependency.globalCaptureEntryWindow?.show()
    }
    
    var isMember: Bool {
        return self.context.coordinator!.dependency.purchaseManager.isMember.value
    }
    
    var dependency: Dependency {
        return self.context.coordinator!.dependency
    }
    
    init(coordinator: CoordinatorType) {
        self.init()
        self.context = ViewModelContext(coordinator: coordinator)
    }
}

public struct ViewModelContext<CoordinatorType: Coordinator> {
    public weak var coordinator: CoordinatorType?
    
    public var dependency: Dependency {
        return self.coordinator!.dependency
    }
}
