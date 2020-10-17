//
//  Ant.swift
//  Ant
//
//  Created by ian luo on 2017/5/24.
//  Copyright © 2017年 wod. All rights reserved.
//

import Foundation

public typealias JSONDict = [String : Any]

public func KeypathParser<T>(_ type: T.Type, key: String) -> (JSONDict) -> T? {
    var comp = key.components(separatedBy: ".")
    
    if comp.count == 1 {
        return Parser(T.self, key: key)
    } else {
        let lastParser = Parser(T.self, key: comp.removeLast())
        
        var middleParser: ((JSONDict) -> JSONDict)? = nil
        for k in comp {
            if let m = middleParser {
                let p = m >>> Parser(JSONDict.self, key: k, or: [:])
                middleParser = p
            } else {
                let p = Parser(JSONDict.self, key: k, or: [:])
                middleParser = p
            }
        }
        
        if let middleParser = middleParser {
            return middleParser >>> lastParser
        } else {
            return lastParser
        }
    }
}

/// Returns a parser, which is able to take a dictionary and return specific value
/// - Parameter type: The type of the return value
/// - Parameter key: Dictioanry key。
/// - Parameter or: Default value when there's no value found
/// - Returns : The parser。
public func Parser<Type>(_ type: Type.Type, key: String, or: Type) -> (JSONDict) -> Type {
    return { map in
        if let value = map[key] as? Type {
            return value
        } else {
            print("Faild to get value with key: \(key) from dic: \(map)")
            return or
        }
    }
}

public func Parser<Type>(_ type: Type.Type, key: String) -> (JSONDict) -> Type? {
    return { map in
        if let value = map[key] as? Type {
            return value
        } else {
            return nil
        }
    }
}

public func JSONParserTestValue<Type: Comparable>(_ type: Type.Type, key: String, compareTo: Type) -> (JSONDict) -> Bool {
    return { map in
        if let value = map[key] as? Type {
            return value == compareTo
        } else {
            return false
        }
    }
}

/// Bind two parsers together, with which you can parse deeper from the dictionary
///
///     let data: JSONDict = ["type" : 1,
///                             "inner" : [
///                                 "name" : "John",
///                                 "age" : 18,
///                                 "address" : [
///                                     "street" : "Some street",
///                                     "number" : "No.1"
///                                 ]
///                              ]
///                            ]
///
///     let innerParser = JSONParser(JSONDict.self, key: "inner", or: [:])
///     let addressParser = JSONParser(JSONDict.self, key: "address", or: [:])
///     let streetParser =  JSONParser(String.self, key: "street", or: "")
///     print((innerParser >>> addressParser >>> streetParser)(data))
public func >>><Type>(lhs: @escaping (JSONDict) -> JSONDict, rhs: @escaping (JSONDict) -> Type) -> (JSONDict) -> Type {
    return { data in
        return rhs(lhs(data))
    }
}

infix operator |||: LogicalDisjunctionPrecedence
precedencegroup LogicalDisjunctionPrecedence {
    associativity : right
}

infix operator >>>: MultiplePrecedence
precedencegroup MultiplePrecedence {
    associativity : right
    higherThan : LogicalDisjunctionPrecedence
}
