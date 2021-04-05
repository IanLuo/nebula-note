//
//  MembershipViewModel.swift
//  x3
//
//  Created by ian luo on 2019/12/17.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyStoreKit
import Core
import Interface

public struct Product {
    let type: PurchaseManager.ProductType
    var name: String
    var description: String
    var price: String?
    var expireDate: Date?
}

public enum MemberFunctions: CaseIterable {
    case customizedStatus
    case unlimitedLevelSubDocument
    case advancedAttachments
//    case refile
    case moveToOtherDocument
    case removeExportWaterprint
    case kanbanFilter
    case andMoreToCome
    
    public var name: String {
        switch self {
        case .customizedStatus: return L10n.Membership.Function.customStatus
        case .unlimitedLevelSubDocument: return L10n.Membership.Function.unlimitedLevelOfSubDocuments
        case .advancedAttachments: return L10n.Membership.Function.advancedAttachments
//        case .refile: return L10n.Membership.Function.refile
        case .moveToOtherDocument: return L10n.Membership.Function.moveToOtherDocument
        case .andMoreToCome: return L10n.Membership.Function.andMoreToCome
        case .removeExportWaterprint: return L10n.Membership.Function.removeExportWaterprint
        case .kanbanFilter: return L10n.Membership.Function.kanbanFilter
        }
    }
}

public class MembershipViewModel: ViewModelProtocol {
    public struct Output {
        let monthlyProduct: BehaviorRelay<Product> = BehaviorRelay(value: Product(type: .monthlyMembership, name: L10n.Membership.Monthly.title, description: L10n.Membership.Monthly.description))
        let yearlyProduct: BehaviorRelay<Product> = BehaviorRelay(value: Product(type: .yearlyMembership, name: L10n.Membership.Yearly.title, description: L10n.Membership.Yearly.description))
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
                return Product(type: PurchaseManager.ProductType.monthlyMembership,
                               name: product!.localizedTitle,
                               description: product!.localizedDescription,
                               price: product!.localizedPrice,
                               expireDate: expireDate)
        }.subscribe(onNext: { [weak self] in
            self?.output.monthlyProduct.accept($0)
        }, onError: { [weak self] in
            self?.output.errorOccurs.onNext($0)
        }).disposed(by: self.disposeBag)
        
        Observable.combineLatest(self.purchaseManager.loadProduct(productId: PurchaseManager.ProductType.yearlyMembership.key),
                                 self.purchaseManager.validate(productId: PurchaseManager.ProductType.yearlyMembership.key))
            .skipWhile { $0.0 == nil }
            .map { product, expireDate in
                return Product(type: PurchaseManager.ProductType.yearlyMembership,
                               name: product!.localizedTitle,
                               description: product!.localizedDescription,
                               price: product!.localizedPrice,
                               expireDate: expireDate)
        }.subscribe(onNext: { [weak self] in
            self?.output.yearlyProduct.accept($0)
        }, onError: { [weak self] in
            self?.output.errorOccurs.onNext($0)
        }).disposed(by: self.disposeBag)
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
