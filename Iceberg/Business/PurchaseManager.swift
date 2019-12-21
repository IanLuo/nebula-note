//
//  PurchaseManager.swift
//  Icetea
//
//  Created by ian luo on 2019/12/19.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift

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

public struct PurchaseManager {
    public init() {}
    
    public func restore() -> Observable<Product> {
        return Observable.create { observer -> Disposable in
            
            // TODO:
            return Disposables.create()
        }
    }
    
    public func purchase(product: Product) -> Observable<Product> {
        return Observable.create { observer -> Disposable in
            
            // TODO:
            return Disposables.create()
        }
    }
    
    public func loadProducts() -> Observable<[Product]> {
        return Observable.create { observer -> Disposable in
            
            // TODO:
            return Disposables.create()
        }
    }
}
