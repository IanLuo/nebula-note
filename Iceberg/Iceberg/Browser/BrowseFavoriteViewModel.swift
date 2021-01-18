//
//  BrowseFavoriteViewModel.swift
//  x3Note
//
//  Created by ian luo on 2021/1/17.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public class BrowseFavoriteViewModel: ViewModelProtocol {
    public var context: ViewModelContext<BrowserCoordinator>!
    
    public typealias CoordinatorType = BrowserCoordinator
    
    public required init() {
        
    }
    
    public let favoriteDocuments: BehaviorRelay<[URL]> = BehaviorRelay(value: [])
    
    public func loadData() {
        if let favorites = self.dependency.settingAccessor.getSetting(item: .favoriteDocuments, type: [String].self) {
            
        }
    }
}
