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

public struct SyncedDictionary<KeyType: Hashable, ValueType>: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (KeyType, ValueType)...) {
        self.innerDictionary = Dictionary(uniqueKeysWithValues: elements)
    }
    
    public typealias Key = KeyType
    public typealias Value = ValueType
    
    private var innerDictionary: Dictionary<KeyType, ValueType>
    private let queue = DispatchQueue(label: "atomic dictioanry")
    
    public var count: Int {
        return self.innerDictionary.count
    }
    
    public subscript(key: KeyType) -> ValueType? {
        get {
            var value: ValueType?
            queue.sync {
                value = self.innerDictionary[key]
            }
            
            return value
        }
        
        set {
            queue.sync {
                self.innerDictionary[key] = newValue
            }
        }
    }
}
