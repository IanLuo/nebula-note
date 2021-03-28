//
//  TabContainerViewModel.swift
//  x3Note
//
//  Created by ian luo on 2021/3/24.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation

public class TabContainerViewModel: ViewModelProtocol {
    public var context: ViewModelContext<TabContainerCoordinator>!
    
    public typealias CoordinatorType = TabContainerCoordinator
    
    public required init() {}
}
