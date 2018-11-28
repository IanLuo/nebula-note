//
//  Storage.swift
//  Storage
//
//  Created by ian luo on 2018/11/5.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public struct Settings {
    private static var instance: [String : Any] = [:]
    public static var isLogEnabled: Bool {
        set { instance["isLogEnabled"] = newValue }
        get { return instance["isLogEnabled"] as? Bool ?? false }
    }
}
