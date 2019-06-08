//
//  String+Conenience.swift
//  Business
//
//  Created by ian luo on 2019/6/8.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public func *(lhs: String, rhs: Int) -> String {
    guard rhs > 0 else { return "" }
    var s = lhs
    for _ in 1..<rhs {
        s.append(lhs)
    }
    
    return s
}
