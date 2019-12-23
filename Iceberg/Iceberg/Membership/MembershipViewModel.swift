//
//  MembershipViewModel.swift
//  Icetea
//
//  Created by ian luo on 2019/12/17.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyStoreKit
import Business

public enum Product {
    case monthly
    case yearly
    
    var productKey: String {
        switch self {
        case .monthly: return ""
        case .yearly: return ""
        }
    }
}

public class MembershipViewModel: ViewModelProtocol {
    struct Output {
        let items: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    }
    
    public var context: ViewModelContext<MembershipCoordinator>!
    
    public typealias CoordinatorType = MembershipCoordinator
    
    private var purchaseManager: PurchaseManager!
    
    required public init() {}
    
    public convenience init(purchaseManager: PurchaseManager, coordinator: MembershipCoordinator) {
        self.init(coordinator: coordinator)
        self.purchaseManager = purchaseManager
    }
    
    public func purchase(product: String) {
        
    }
    
    public func restore() {
        
    }
}
