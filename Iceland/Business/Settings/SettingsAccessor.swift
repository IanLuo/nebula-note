//
//  SettingsAccessor.swift
//  Iceland
//
//  Created by ian luo on 2018/12/15.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public enum SettingsError: Error {
    case  removePlanningFailed(String)
}

/// used to fetch settings values
public class SettingsAccessor {
    private struct Constants {
        static var store: KeyValueStore { return KeyValueStoreFactory.store(type: KeyValueStoreType.plist(PlistStoreType.custom("Settings"))) }
        struct Keys {
            static let finishedPlannings = "finishedPlannings"
            static let unfinishedPlannings = "unfinishedPlannings"
        }
    }
    
    private static let instance = SettingsAccessor()
    private init() {}
    public static var shared: SettingsAccessor { return instance }
    
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
    
    public var maxLevel: Int {
        return 6
    }
    
    public var priorities: [String] {
        return OutlineParser.Values.Heading.Priority.all
    }
    
    public var customizedUnfinishedPlannings: [String]? {
       return Constants.store.get(key: Constants.Keys.unfinishedPlannings, type: [String].self)
    }
    
    public var customizedFinishedPlannings: [String]? {
        return Constants.store.get(key: Constants.Keys.finishedPlannings, type: [String].self)
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
