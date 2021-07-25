//
//  Dictionary.swift
//  Core
//
//  Created by ian luo on 2021/7/18.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation

extension Dictionary where Value == Array<Any> {
    public mutating func appendToGroup(key: Key,value: Any) {
        if var array = self[key] {
            array.append(value)
            self[key] = array
        } else {
            self[key] = [value]
        }
    }
}
