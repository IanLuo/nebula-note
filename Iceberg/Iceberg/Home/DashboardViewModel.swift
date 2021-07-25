//
//  HomeViewModel.swift
//  Iceland
//
//  Created by ian luo on 2019/1/7.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Core
import Interface

public class DashboardViewModel: ViewModelProtocol {
    public required init() {}
    
    public var context: ViewModelContext<CoordinatorType>!
    
    public typealias CoordinatorType = HomeCoordinator
}
