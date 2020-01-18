//
//  Range.swift
//  Business
//
//  Created by ian luo on 2019/1/31.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

extension NSRange {
    public func offset(_ offset: Int) -> NSRange {
        return NSRange(location: self.location + offset, length: self.length)
    }
}

extension NSRange {
    public func moveLeftBound(by: Int) -> NSRange {
        return NSRange(location: self.location + by, length: self.length - by)
    }
    
    public func moveRightBound(by: Int) -> NSRange {
        return NSRange(location: self.location, length: self.length + by)
    }
    
    public func withNewUpperBound(_ new: Int) -> NSRange {
        let diff = new - self.upperBound
        return self.moveRightBound(by: diff)
    }
    
    public func withNewLowerBound(_ new: Int) -> NSRange {
        let diff = new - self.lowerBound
        return self.moveLeftBound(by: diff)
    }
}

extension NSRange {
    public func tail(_ length: Int) -> NSRange {
        if length <= self.length {
            return NSRange(location: self.location + (self.length - length), length: length)
        } else {
            return self
        }
    }
    
    public func head(_ length: Int) -> NSRange {
        if length <= self.length {
            return NSRange(location: self.location, length: length)
        } else {
            return self
        }
    }
    
    public func xor(_ range: NSRange) -> [NSRange]? {
        if self.lowerBound >= range.lowerBound && self.upperBound <= range.upperBound {
            return nil
        } else if self.lowerBound < range.lowerBound && self.upperBound <= range.upperBound {
            return [NSRange(location: range.location, length: range.lowerBound - self.upperBound)]
        } else if self.lowerBound >= range.lowerBound && self.upperBound > range.upperBound {
            return [NSRange(location: self.location, length: range.upperBound - self.upperBound)]
        } else {
            return [NSRange(location: self.location, length: range.location - self.location),
                    NSRange(location: range.location, length: self.upperBound - range.upperBound)]
        }
    }
}
