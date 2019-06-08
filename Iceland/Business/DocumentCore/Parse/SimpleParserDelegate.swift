//
//  SimpleParserDelegate.swift
//  Business
//
//  Created by ian luo on 2019/6/8.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

class SimpleParserDelegate: OutlineParserDelegate {
    var headings: [HeadingToken] = []
    var dateAndTimes: [NSRange] = []
    
    func didStartParsing(text: String) {
        // clear earlier found data
        self.headings = []
        self.dateAndTimes = []
    }
    
    func didFoundHeadings(text: String,
                          headingDataRanges: [[String: NSRange]]) {
        
        self.headings = headingDataRanges.map { HeadingToken(data: $0) }
    }
    
    func didFoundDateAndTime(text: String, rangesData: [[String:NSRange]]) {
        self.dateAndTimes = rangesData.map { $0.values.first! }
    }
    
    // O(n) FIXME: 用二分查找提高效率
    public func heading(contains location: Int) -> HeadingToken? {
        for heading in self.headings.reversed() {
            if location >= heading.range.location {
                return heading
            }
        }
        
        return nil
    }
}
