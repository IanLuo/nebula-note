//
//  SettingsViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol SettingsViewModelDelegate: class {
    
}

public class SettingsViewModel {
    public weak var delegate: SettingsViewModelDelegate?
    
    public func getPlanningKeywords() -> [String] {
        return []
    }
}
