//
//  SettingsAccessor.swift
//  Iceland
//
//  Created by ian luo on 2018/12/15.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

/// used to fetch settings values
public class SettingsAccessor {
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
        return ["Pending", "Waiting"] // TODO: change to real funciton
    }
    
    public var customizedFinishedPlannings: [String]? {
        return ["Rejected"] // TODO: change to real function
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
}
