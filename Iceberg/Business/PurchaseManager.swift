//
//  PurchaseManager.swift
//  Icetea
//
//  Created by ian luo on 2019/12/19.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import StoreKit
import SwiftyStoreKit

public struct PurchaseManager {
    public init() {}
    
    public func restore() -> Observable<[Purchase]> {
        return Observable.create { observer -> Disposable in
            
            SwiftyStoreKit.restorePurchases(atomically: true) { results in
                observer.onNext(results.restoredPurchases)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    public func purchase(product: SKProduct) -> Observable<PurchaseDetails> {
        return Observable.create { observer -> Disposable in
            
            SwiftyStoreKit.purchaseProduct(product.productIdentifier, quantity: 1, atomically: false) { result in
                switch result {
                case .success(let product):
                    if product.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(product.transaction)
                    }
                    
                    observer.onNext(product)
                    observer.onCompleted()
                    
                case .error(let error):
                    switch error.code {
                    case .unknown: print("Unknown error. Please contact support")
                    case .clientInvalid: print("Not allowed to make the payment")
                    case .paymentCancelled: break
                    case .paymentInvalid: print("The purchase identifier was invalid")
                    case .paymentNotAllowed: print("The device is not allowed to make the payment")
                    case .storeProductNotAvailable: print("The product is not available in the current storefront")
                    case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                    case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                    case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                    default: print((error as NSError).localizedDescription)
                    
                    observer.onError(error)
                    observer.onCompleted()
                        
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    public func loadProducts() -> Observable<[SKProduct]> {
        return Observable.create { observer -> Disposable in
            
            SwiftyStoreKit.retrieveProductsInfo(["icetea_note_monthly_membership", "yearly_icetea_note_membership"]) { result in
                observer.onNext(Array(result.retrievedProducts))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    public func initialize() {
        // see notes below for the meaning of Atomic / Non-Atomic
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
    }
}
