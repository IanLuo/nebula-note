//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

/// 用户的活动中心
/// 每天的任务安排显示在此处
public class AgendaCoordinator: Coordinator {
    public enum FilterType {
        case tag(String)
        case overdue
        case scheduled
        case dueSoon
        case scheduledSoon
        case withoutDate
    }
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        let viewModel = AgendaViewModel(documentSearchManager: dependency.documentSearchManager)
        viewModel.coordinator = self
        let viewController = AgendaViewController(viewModel: viewModel)
        self.viewController = viewController
    }
    
    /// 显示指定 tag 的所有 heading 列表
    public init(filterType: FilterType, stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        let viewModel = AgendaViewModel(documentSearchManager: dependency.documentSearchManager)
        viewModel.filterType = filterType
        viewModel.coordinator = self
        let viewController = FilteredItemsViewController(viewModel: viewModel)
        self.viewController = viewController
    }
}
