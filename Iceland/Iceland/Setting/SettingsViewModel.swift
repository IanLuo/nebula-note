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
    func didSetInterfaceStyle(newStyle: SettingsAccessor.InterfaceStyle)
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
    
    public var interfaceStyle: SettingsAccessor.InterfaceStyle {
        return self.coordinator!.dependency.settingAccessor.interfaceStyle
    }
    
    public func setInterfaceStyle(_ newStyle: SettingsAccessor.InterfaceStyle) {
        self.coordinator?.dependency.settingAccessor.setInterfaceStyle(newStyle, completion: { [weak self] in
            self?.delegate?.didSetInterfaceStyle(newStyle: newStyle)
        })
    }

    public func getPlanning(isForFinished: Bool) -> [String] {
        return (isForFinished
            ? self.coordinator?.dependency.settingAccessor.finishedPlanning ?? []
            : self.coordinator?.dependency.settingAccessor.unfinishedPlanning) ?? []
    }
    
    public var plannings: [String] {
        return self.coordinator?.dependency.settingAccessor.allPlannings ?? []
    }
    
    public var defaultPlannings: [String] {
        return self.coordinator?.dependency.settingAccessor.defaultPlannings ?? []
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
                    if enable {
                        self?.coordinator?.dependency.eventObserver.emit(iCloudEnabledEvent())
                    } else {
                        self?.coordinator?.dependency.eventObserver.emit(iCloudDisabledEvent())
                    }
                }
            }
        }
    }
}
