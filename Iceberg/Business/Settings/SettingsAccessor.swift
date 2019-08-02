//
//  SettingsAccessor.swift
//  Iceland
//
//  Created by ian luo on 2018/12/15.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import Interface

public enum SettingsError: Error {
    case  removePlanningFailed(String)
}

/// used to fetch settings values
@objc public class SettingsAccessor: NSObject {
    public enum InterfaceStyle: String, CaseIterable {
        case dark
        case light
        case auto
    }
    
    private struct Constants {
        static var store: KeyValueStore { return KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom("Settings"))) }
        struct Keys {
            static let finishedPlannings = "finishedPlannings"
            static let unfinishedPlannings = "unfinishedPlannings"
            static let landingTabIndex = "landingTabIndex"
            static let interfaceStyle = "interfaceStyle"
        }
    }
    
    private static let instance = SettingsAccessor()
    private override init() {}
    @objc public static var shared: SettingsAccessor { return instance }
    
    public var customizedPlannings: [String]? {
        switch (self.customizedFinishedPlannings, self.customizedUnfinishedPlannings) {
        case let (lhs?, rhs?):
            return lhs + rhs
        case let (lhs?, nil):
            return lhs
        case let (nil, rhs):
            return rhs
        }
    }
    
    @objc public var lineHeight: CGFloat {
        return InterfaceTheme.Font.body.xHeight
    }
    
    public var maxLevel: Int {
        return 6
    }
    
    public var priorities: [String] {
        return OutlineParser.Values.Heading.Priority.all
    }
    
    public var interfaceStyle: InterfaceStyle {
        // 支持 dark mode 的系统，默认值为自动，否则为 light
        if #available(iOS 13, *) {
            return InterfaceStyle(rawValue: Constants.store.get(key: Constants.Keys.interfaceStyle, type: String.self) ?? InterfaceStyle.auto.rawValue) ?? InterfaceStyle.auto
        } else {
            return InterfaceStyle(rawValue: Constants.store.get(key: Constants.Keys.interfaceStyle, type: String.self) ?? InterfaceStyle.light.rawValue) ?? InterfaceStyle.light
        }
    }
    
    public func setInterfaceStyle(_ style: InterfaceStyle, completion: @escaping () -> Void) {
        Constants.store.set(value: style.rawValue, key: Constants.Keys.interfaceStyle, completion: completion)
    }
    
    public func setLandingTabIndex(_ index: Int, completion: @escaping () -> Void) {
        Constants.store.set(value: index, key: Constants.Keys.landingTabIndex, completion: completion)
    }
    
    public var landingTabIndex: Int {
        return Constants.store.get(key: Constants.Keys.landingTabIndex, type: Int.self) ?? 0
    }
    
    public var customizedUnfinishedPlannings: [String]? {
        if let plannings = Constants.store.get(key: Constants.Keys.unfinishedPlannings, type: [String].self) {
            return plannings.count > 0 ? plannings : nil
        } else {
            return nil
        }
    }
    
    public var customizedFinishedPlannings: [String]? {
        if let plannings = Constants.store.get(key: Constants.Keys.finishedPlannings, type: [String].self) {
            return plannings.count > 0 ? plannings : nil
        } else {
            return nil
        }
    }
    
    public var unfinishedPlanning: [String] {
        return (customizedUnfinishedPlannings ?? []) + [OutlineParser.Values.Heading.Planning.todo]
    }
    
    public var finishedPlanning: [String] {
        return (customizedFinishedPlannings ?? []) + [OutlineParser.Values.Heading.Planning.canceled, OutlineParser.Values.Heading.Planning.done]
    }
    
    public var allPlannings: [String] {
        return unfinishedPlanning + finishedPlanning
    }
    
    public var defaultPlannings: [String] {
        return [OutlineParser.Values.Heading.Planning.todo, OutlineParser.Values.Heading.Planning.canceled,
                OutlineParser.Values.Heading.Planning.done]
    }
    
    /// add new planning
    public func addPlanning(_ planning: String, isForFinished: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let key = isForFinished ? Constants.Keys.finishedPlannings : Constants.Keys.unfinishedPlannings
        if var plannings = Constants.store.get(key: key, type: [String].self) {
            plannings.append(planning)
            Constants.store.set(value: plannings, key: key) {
                completion(.success(()))
            }
        } else {
            Constants.store.set(value: [planning], key: key) {
                completion(.success(()))
            }
        }
    }
    
    /// remove specified planning if there's on in the setting's configuration
    public func removePlanning(_ planning: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let removePlanningAction: (String) -> Bool = { key in
            if var plannings = Constants.store.get(key: key, type: [String].self) {
                for (index, p) in plannings.enumerated() {
                    if p == planning {
                        plannings.remove(at: index)
                        Constants.store.set(value: plannings, key: key) {
                            completion(.success(()))
                        }
                        return true // planning found and removed, return true, so there's no need for another remove action for another planning list
                    }
                }
            } else {
                completion(.failure(SettingsError.removePlanningFailed("no planning found")))
            }
            
            return false
        }
        
        if !removePlanningAction(Constants.Keys.finishedPlannings) {
            _ = removePlanningAction(Constants.Keys.unfinishedPlannings)
        }
    }    
}