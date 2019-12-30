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

public struct Product {
    let type: PurchaseManager.ProductType
    var name: String?
    var description: String?
    var price: String?
    var expireDate: Date?
}

public class MembershipViewModel: ViewModelProtocol {
    public struct Output {
        let monthlyProduct: BehaviorRelay<Product> = BehaviorRelay(value: Product(type: .monthlyMembership))
        let yearlyProduct: BehaviorRelay<Product> = BehaviorRelay(value: Product(type: .yearlyMembership))
        let errorOccurs: PublishSubject<Error> = PublishSubject()
    }
    
    public var context: ViewModelContext<MembershipCoordinator>!
    
    public typealias CoordinatorType = MembershipCoordinator
    
    private var purchaseManager: PurchaseManager!
    
    private let disposeBag = DisposeBag()
    
    public let output: Output = Output()
    
    required public init() {}
    
    public convenience init(purchaseManager: PurchaseManager, coordinator: MembershipCoordinator) {
        self.init(coordinator: coordinator)
        self.purchaseManager = purchaseManager
    }
    
    public func purchaseMonthlyMembership() {
        self.purchase(productId: PurchaseManager.ProductType.monthlyMembership.key)
            .flatMap { [unowned self] purchaseDetails in
                return self.purchaseManager.validate(productId: purchaseDetails.productId)
        }.subscribe(onNext: { [weak self] date in
            if let oldProduct = self?.output.monthlyProduct.value {
                self?.output.monthlyProduct.accept(Product(type: oldProduct.type,
                                                           name: oldProduct.name,
                                                           description: oldProduct.description,
                                                           price: oldProduct.price,
                                                           expireDate: date))
            }
            }, onError: { [weak self] in
                self?.output.errorOccurs.onNext($0)
    }).disposed(by: self.disposeBag)
}
    
    public func purchaseYearlyMembership() {
        self.purchase(productId: PurchaseManager.ProductType.yearlyMembership.key)
            .flatMap { [unowned self] purchaseDetails in
                return self.purchaseManager.validate(productId: purchaseDetails.productId)
        }.subscribe(onNext: { [weak self] date in
            if let oldProduct = self?.output.yearlyProduct.value {
                self?.output.yearlyProduct.accept(Product(type: oldProduct.type,
                                                          name: oldProduct.name,
                                                          description: oldProduct.description,
                                                          price: oldProduct.price,
                                                          expireDate: date))
            }
        }, onError: { [weak self] in
            self?.output.errorOccurs.onNext($0)
        }).disposed(by: self.disposeBag)
    }
    
    public func loadProducts() {
        Observable.combineLatest(self.purchaseManager.loadProduct(productId: PurchaseManager.ProductType.monthlyMembership.key),
                                 self.purchaseManager.validate(productId: PurchaseManager.ProductType.monthlyMembership.key))
            .skipWhile { $0.0 == nil }
            .map { product, expireDate in
                return Product(type: PurchaseManager.ProductType.yearlyMembership,
                               name: product?.localizedTitle,
                               description: product?.localizedDescription,
                               price: product?.localizedPrice,
                               expireDate: expireDate)
        }.bind(to: self.output.monthlyProduct)
            .disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.purchaseManager.loadProduct(productId: PurchaseManager.ProductType.yearlyMembership.key),
                                 self.purchaseManager.validate(productId: PurchaseManager.ProductType.yearlyMembership.key))
            .skipWhile { $0.0 == nil }
            .map { product, expireDate in
                return Product(type: PurchaseManager.ProductType.monthlyMembership,
                               name: product?.localizedTitle,
                               description: product?.localizedDescription,
                               price: product?.localizedPrice,
                               expireDate: expireDate)
        }.bind(to: self.output.yearlyProduct)
            .disposed(by: self.disposeBag)
    }
    
    public func restore() -> Observable<[Purchase]> {
        self.purchaseManager
            .restore()
            .do(onNext: { purchases in
                for purchase in purchases {
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                }
            })
    }
    
    private func purchase(productId: String) -> Observable<PurchaseDetails> {
        return self.purchaseManager
            .purchase(productId: productId)
            .do(onNext: { purchase in
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            })
    }
    
}
