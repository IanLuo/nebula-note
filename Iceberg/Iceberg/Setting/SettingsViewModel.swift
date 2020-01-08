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
    func didUpdateUnfoldWhenOpen(unfold: Bool)
}

public class SettingsViewModel: ViewModelProtocol {
    public var context: ViewModelContext<SettingsCoordinator>!
    
    public typealias CoordinatorType = SettingsCoordinator
    
    public weak var delegate: SettingsViewModelDelegate?
    
    required public init() {}
    
    public var isSyncEnabled: Bool {
        return self.dependency.syncManager.iCloudAccountStatus != .closed
            && iCloudDocumentManager.status == .on
    }
    
    public var interfaceStyle: SettingsAccessor.InterfaceStyle {
        return self.dependency.settingAccessor.interfaceStyle
    }
    
    public func setInterfaceStyle(_ newStyle: SettingsAccessor.InterfaceStyle) {
        SettingsAccessor.Item.interfaceStyle.set(newStyle.rawValue) { [weak self] in
            self?.delegate?.didSetInterfaceStyle(newStyle: newStyle)
        }
    }

    public func getPlanning(isForFinished: Bool) -> [String] {
        return (isForFinished
            ? self.dependency.settingAccessor.finishedPlanning
            : self.dependency.settingAccessor.unfinishedPlanning)
    }
    
    public var plannings: [String] {
        return self.dependency.settingAccessor.allPlannings
    }
    
    public var defaultPlannings: [String] {
        return self.dependency.settingAccessor.defaultPlannings
    }
    
    public func setLandingTabIndex(_ index: Int) {
        SettingsAccessor.Item.landingTabIndex.set(index) { [weak self] in
            self?.delegate?.didSetLandingTabIndex(index: index)
        }
    }
    
    public var unfoldWhenOpen: Bool {
        SettingsAccessor.Item.unfoldAllEntriesWhenOpen.get(Bool.self) ?? false
    }
    
    public func setUnfoldWhenOpen(_ unfold: Bool) {
        SettingsAccessor.Item.unfoldAllEntriesWhenOpen.set(unfold) { [weak self] in
            self?.delegate?.didUpdateUnfoldWhenOpen(unfold: unfold)
        }
    }
    
    public var currentLandigTabIndex: Int {
        return SettingsAccessor.Item.landingTabIndex.get(Int.self) ?? 3
    }
    
    public var exportShowIndex: Bool {
        return SettingsAccessor.Item.exportShowIndex.get(Bool.self) ?? true
    }
    
    public func setExportShowIndex(_ showIndex: Bool, completion: @escaping () -> Void) {
        SettingsAccessor.Item.exportShowIndex.set(showIndex, completion: completion)
    }
    
    public func addPlanning(_ planning: String, isForFinished: Bool, completion: @escaping () -> Void) {
        self.dependency.settingAccessor.addPlanning(planning, isForFinished: isForFinished) { result in
            switch result {
            case .success: completion()
            case .failure: break
            }
        }
    }
    
    public func removePlanning(_ planning: String, completion: @escaping () -> Void) {
        self.dependency.settingAccessor.removePlanning(planning) { result in
            switch result {
            case .success: completion()
            case .failure: break
            }
        }
    }
    
    public func setSyncEnabled(_ enable: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        self.dependency.syncManager.swithiCloud(on: enable) { [weak self] error in
            DispatchQueue.runOnMainQueueSafely {
                if let error = error {
                    completion(.failure(error))
                } else {
                    iCloudDocumentManager.status = enable ? .on : .off
                    completion(.success(()))
                    self?.delegate?.didSetIsSyncEnabled(enable)
                    
                    if enable {
                        self?.dependency.eventObserver.emit(iCloudEnabledEvent())
                    } else {
                        self?.dependency.eventObserver.emit(iCloudDisabledEvent())
                    }
                }
            }
        }
    }
}
