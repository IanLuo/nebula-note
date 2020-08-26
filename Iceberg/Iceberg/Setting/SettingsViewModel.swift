//
//  SettingsViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Core
import Interface

public protocol SettingsViewModelDelegate: class {
    func didSetIsSyncEnabled(_ enabled: Bool)
    func didUpdateFinishedPlanning()
    func didUpdateUnfinishedPlanning()
    func didSetLandingTabIndex(index: Int)
    func didSetInterfaceStyle(newStyle: SettingsAccessor.InterfaceStyle)
    func didUpdateUnfoldWhenOpen(unfold: Bool)
}

public class SettingsViewModel: ViewModelProtocol {
    public enum ItemValue {
        case list(Int, [String], [UIImage]?)
        case `switch`(Bool)
    }
    
    public struct Item {
        let label: String
        let value: ItemValue
        let action: ((Any) -> Void)
    }
    
    public class Group {
        let title: String
        var items: [Item] = []
        
        public init(title: String, items: [Item]) {
            self.title = title
        }
        
        public func addItem(_ item: Item) {
            self.items.append(item)
        }
    }
    
    public class Page {
        var groups: [Group] = []
        
        public func addGroup(_ group: Group) {
            self.groups.append(group)
        }
    }
    
    public func makeData() -> Page {
        let mainPage = Page()
        mainPage.addGroup(SettingsViewModel.Group(title: "General", items: [
            Item(label: "Default first screen",
                 value: ItemValue.list(SettingsAccessor.Item.landingTabIndex.get(Int.self) ?? 3,
                                       LandingTab.allCases.map { $0.name },
                                       LandingTab.allCases.map { $0.icon }),
                 action: { newIndex in
                    SettingsAccessor.Item.landingTabIndex.set(newIndex, completion: {})
            })
        ]))
        
        mainPage.addGroup(SettingsViewModel.Group(title: "Customized status", items: [
            // TODO:
        ]))
        
        
        return mainPage
    }
    
    
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
            DispatchQueue.runOnMainQueueSafely {
                self?.delegate?.didSetInterfaceStyle(newStyle: newStyle)
            }
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
            DispatchQueue.runOnMainQueueSafely {
                self?.delegate?.didSetLandingTabIndex(index: index)
            }
        }
    }
    
    public var foldWhenOpen: Bool {
        SettingsAccessor.Item.foldAllEntriesWhenOpen.get(Bool.self) ?? false
    }
    
    public func setFoldWhenOpen(_ unfold: Bool) {
        SettingsAccessor.Item.foldAllEntriesWhenOpen.set(unfold) { [weak self] in
            DispatchQueue.runOnMainQueueSafely {
                self?.delegate?.didUpdateUnfoldWhenOpen(unfold: unfold)
            }
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
            case .success:
                DispatchQueue.runOnMainQueueSafely {
                    completion()
                }
            case .failure: break
            }
        }
    }
    
    public func removePlanning(_ planning: String, completion: @escaping () -> Void) {
        self.dependency.settingAccessor.removePlanning(planning) { result in
            switch result {
            case .success:
                DispatchQueue.runOnMainQueueSafely {
                    completion()
                }
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

enum LandingTab: CaseIterable {
    case agenda, captureList, search, browser
    
    var name: String {
        switch self {
        case .agenda: return  L10n.Agenda.title
        case .captureList: return L10n.CaptureList.title
        case .search: return L10n.Search.title
        case .browser: return L10n.Browser.title
        }
    }
    
    var icon: UIImage {
        switch self {
        case .agenda: return Asset.Assets.agenda.image.fill(color: InterfaceTheme.Color.interactive)
        case .captureList: return Asset.Assets.inspiration.image.fill(color: InterfaceTheme.Color.interactive)
        case .search: return Asset.Assets.zoom.image.fill(color: InterfaceTheme.Color.interactive)
        case .browser: return Asset.Assets.document.image.fill(color: InterfaceTheme.Color.interactive)
        }
    }
}
