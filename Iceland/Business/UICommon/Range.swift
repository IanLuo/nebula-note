//
//  Range.swift
//  Business
//
//  Created by ian luo on 2019/1/31.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

extension NSRange {
    public func moveLeft(by: Int) -> NSRange {
        return NSRange(location: self.location + by, length: self.length - by)
    }
    
    public func moveRight(by: Int) -> NSRange {
        return NSRange(location: self.location, length: self.length + by)
    }
    
    public func shift(by: Int) -> NSRange {
        return NSRange(location: self.location + by, length: self.length)
    }
    
    public func withNewUpperBound(_ new: Int) -> NSRange {
        let diff = new - self.upperBound
        return self.moveRight(by: diff)
    }
    
    public func withNewLowerBound(_ new: Int) -> NSRange {
        let diff = new - self.lowerBound
        return self.moveLeft(by: diff)
    }
}
