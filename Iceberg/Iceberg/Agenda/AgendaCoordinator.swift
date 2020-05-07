//
//  AgendaCoordinator.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Core

public protocol AgendaCoordinatorDelegate: class {
    func didSelectDocument(url: URL, location: Int)
}

/// 用户的活动中心
/// 每天的任务安排显示在此处
public class AgendaCoordinator: Coordinator {
    public enum FilterType {
        case tag(String)
        case planning(String)
        case unfinished([DocumentHeadingSearchResult])
        case finished([DocumentHeadingSearchResult])
        case overdue([DocumentHeadingSearchResult])
        case scheduled([DocumentHeadingSearchResult])
        case dueSoon([DocumentHeadingSearchResult])
        case startSoon([DocumentHeadingSearchResult])
        case today([DocumentHeadingSearchResult])
    }
    
    public weak var delegate: AgendaCoordinatorDelegate?
    
    public override init(stack: UINavigationController, dependency: Dependency) {
        super.init(stack: stack, dependency: dependency)
        let viewModel = AgendaViewModel(documentSearchManager: dependency.documentSearchManager)
        viewModel.coordinator = self
        let viewController = AgendaViewController(viewModel: viewModel)
        viewController.delegate = self
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

extension AgendaCoordinator: AgendaViewControllerDelegate {
    public func didSelectDocument(url: URL, location: Int) {
        self.delegate?.didSelectDocument(url: url, location: location)
    }
}
