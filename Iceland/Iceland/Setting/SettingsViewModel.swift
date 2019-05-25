//
//  SettingsViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Business

public protocol SettingsViewModelDelegate: class {
    func didSetIsSyncEnabled(_ enabled: Bool)
    func didUpdateFinishedPlanning()
    func didUpdateUnfinishedPlanning()
    func didSetLandingTabIndex(index: Int)
    func didSetInterfaceTheme(isOn: Bool)
}

public class SettingsViewModel {
    public weak var delegate: SettingsViewModelDelegate?
    
    public weak var coordinator: SettingsCoordinator?
    
    public init(coordinator: SettingsCoordinator) {
        self.coordinator = coordinator
    }
    
    public var isSyncEnabled: Bool {
        return self.coordinator?.dependency.syncManager.iCloudAccountStatus != .closed
            && SyncManager.status == .on
    }
    
    public var isDarkInterfaceOn: Bool {
        return self.coordinator?.dependency.settingAccessor.isDarkInterfaceOn ?? false
    }
    
    public func setDarkInterfaceOn(_ isOn: Bool) {
        self.coordinator?.dependency.settingAccessor.setIsDarkInterfaceOn(isOn, completion: { [weak self] in
            self?.delegate?.didSetInterfaceTheme(isOn: isOn)
        })
    }

    public func getPlanning(isForFinished: Bool) -> [String] {
        return (isForFinished
            ? self.coordinator?.dependency.settingAccessor.customizedFinishedPlannings ?? []
            : self.coordinator?.dependency.settingAccessor.customizedUnfinishedPlannings) ?? []
    }
    
    public var plannings: [String] {
        return self.coordinator?.dependency.settingAccessor.allPlannings ?? []
    }
    
    public func setLandingTabIndex(_ index: Int) {
        self.coordinator?.dependency.settingAccessor.setLandingTabIndex(index) { [weak self] in
            self?.delegate?.didSetLandingTabIndex(index: index)
        }
    }
    
    public var currentLandigTabIndex: Int {
        return self.coordinator?.dependency.settingAccessor.landingTabIndex ?? 0
    }
    
    public func addPlanning(_ planning: String, isForFinished: Bool, completion: @escaping () -> Void) {
        self.coordinator?.dependency.settingAccessor.addPlanning(planning, isForFinished: isForFinished) { result in
            switch result {
            case .success: completion()
            case .failure: break
            }
        }
    }
    
    public func removePlanning(_ planning: String, completion: @escaping () -> Void) {
        self.coordinator?.dependency.settingAccessor.removePlanning(planning) { result in
            switch result {
            case .success: completion()
            case .failure: break
            }
        }
    }
    
    public func setSyncEnabled(_ enable: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        self.coordinator?.dependency.syncManager.swithiCloud(on: enable) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                } else {
                    SyncManager.status = enable ? .on : .off
                    completion(.success(()))
                    self?.delegate?.didSetIsSyncEnabled(enable)
                }
            }
        }
    }
}
