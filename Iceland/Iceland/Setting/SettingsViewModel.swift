//
//  SettingsViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol SettingsViewModelDelegate: class {
    func didSetIsSyncEnabled(_ enabled: Bool)
    func didUpdateFinishedPlanning()
    func didUpdateUnfinishedPlanning()
}

public class SettingsViewModel {
    public weak var delegate: SettingsViewModelDelegate?
    
    public let coordinator: SettingsCoordinator
    
    public init(coordinator: SettingsCoordinator) {
        self.coordinator = coordinator
    }
    
    public var isSyncEnabled: Bool {
        return self.coordinator.dependency.settingAccessor.isSyncEnabled
    }

    public func getPlanning(isForFinished: Bool) -> [String] {
        return (isForFinished
            ? self.coordinator.dependency.settingAccessor.customizedFinishedPlannings ?? []
            : self.coordinator.dependency.settingAccessor.customizedUnfinishedPlannings) ?? []
    }
    
    public var plannings: [String] {
        return self.coordinator.dependency.settingAccessor.allPlannings
    }
    
    public func addPlanning(_ planning: String, isForFinished: Bool, completion: @escaping () -> Void) {
        self.coordinator.dependency.settingAccessor.addPlanning(planning, isForFinished: isForFinished) { result in
            switch result {
            case .success: completion()
            case .failure: break
            }
        }
    }
    
    public func removePlanning(_ planning: String, completion: @escaping () -> Void) {
        self.coordinator.dependency.settingAccessor.removePlanning(planning) { result in
            switch result {
            case .success: completion()
            case .failure: break
            }
        }
    }
    
    public func setSyncEnabled(_ enable: Bool, completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            self.coordinator.dependency.settingAccessor.setIsSyncEnabled(enable) { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                    completion()
                    self?.delegate?.didSetIsSyncEnabled(enable)
                })
            }
        }
    }
}
