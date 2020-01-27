//
//  Array.swift
//  Core
//
//  Created by ian luo on 2020/1/18.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation

public extension Array {
    func intersects<Element2>(another array: Array<Element2>, compare: (Element, Element2) -> Bool) -> [Element]? {
        var result: [Element] = []
        
        for itemSelf in self {
            for itemAnother in array {
                if compare(itemSelf, itemAnother) {
                    result.append(itemSelf)
                }
            }
        }
        
        return result.count > 0 ? result : nil
    }
}
