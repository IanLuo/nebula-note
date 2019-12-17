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

public class MembershipViewModel: ViewModelProtocol {
    struct Output {
        let items: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    }
    
    public var context: ViewModelContext<MembershipCoordinator>!
    
    public typealias CoordinatorType = MembershipCoordinator
    
    required public init() {}
    
    public func purchase(item: String) {
        
    }
    
    public func restore() {
        
    }
}
