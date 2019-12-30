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
    public enum ProductType {
        case monthlyMembership
        case yearlyMembership
        
        public var key: String {
            switch self {
            case .monthlyMembership:
                return "icetea_note_monthly_membership"
            case .yearlyMembership:
                return "yearly_icetea_note_membership"
            }
        }
    }
    
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
    
    /// find the expire date for both subscription, if one exists, use that one, if both exists, use later one
    public func findExpireDate() -> Observable<Date?> {
        Observable.combineLatest(self.validate(productId: ProductType.monthlyMembership.key),
                                 self.validate(productId: ProductType.yearlyMembership.key))
            .map { monthlyExpireDate, yearlyExpireDate in
                switch (monthlyExpireDate, yearlyExpireDate) {
                case let (monthlyExpireDate?, yearlyExpireDate?):
                    return max(monthlyExpireDate, yearlyExpireDate)
                case let (monthlyExpireDate?, nil):
                    return monthlyExpireDate
                case let (nil, yearlyExpireDate?):
                    return yearlyExpireDate
                case (nil, nil):
                    return nil
                }
        }
    }
    
    public func validate(productId: String) -> Observable<Date?> {
        return Observable.create { observer -> Disposable in
            
            let validator = AppleReceiptValidator(service: AppleReceiptValidator.VerifyReceiptURLType.sandbox, sharedSecret: "7dc6efbf319f46f5834b39b19110d3ee")
            SwiftyStoreKit.verifyReceipt(using: validator) { result in
                switch result {
                case .error(error: let error):
                    observer.onError(error)
                    observer.onCompleted()
                case .success(receipt: let receptInfo):
                    let purchaseResult = SwiftyStoreKit.verifySubscriptions(ofType: SubscriptionType.autoRenewable,
                                                                            productIds: [productId],
                                                                            inReceipt: receptInfo,
                                                                            validUntil: Date())
                    
                    var expireDate: Date? = nil
                    switch purchaseResult {
                    case .expired(expiryDate: let _expireDate, items: _):
                        expireDate = _expireDate
                    case .notPurchased:
                        expireDate = nil
                    case .purchased(expiryDate: let _expireDate, items: _):
                        expireDate = _expireDate
                    }
                    
                    observer.onNext(expireDate)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    public func purchase(productId: String) -> Observable<PurchaseDetails> {
        return Observable.create { observer -> Disposable in
            
            SwiftyStoreKit.purchaseProduct(productId, quantity: 1, atomically: false) { result in
                switch result {
                case .success(let product):
                    if product.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(product.transaction)
                    }
                    
                    observer.onNext(product)
                    observer.onCompleted()
                    
                case .error(let error):
                    
                    observer.onError(error)
                    observer.onCompleted()

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
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    public func loadProduct(productId: String) -> Observable<SKProduct?> {
        return Observable.create { observer -> Disposable in
            
            SwiftyStoreKit.retrieveProductsInfo([productId]) { result in
                observer.onNext(result.retrievedProducts.first)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    public func save(reception: SKPaymentTransaction) {
        // TOOD:
    }
    
    public func loadExpireDate() -> Date? {
        // TODO:
        return nil
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
    
    public func initTransactions() {
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
