//
//  Document.swift
//  Iceland
//
//  Created by ian luo on 2018/11/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol Document {
    func read(path: String)
    func write(path: String)
}

public class Outline: NSObject,  Document {
    public func read(path: String) {
        
    }
    
    public func write(path: String) {
        
    }
    
    /// 如果编辑了，设置为编辑位置 index of character
    var renderedIndex: Int = 0
    
    /// 当前的 heading
    var currentHeading: Int?
    
    public func scanHeadings() {}
    
    public func insertTag(heading: Int) {}
    
    public func insertPlanning(heading: Int) {}
    
    public func insertTODO(heading: Int) {}
}

public class Stack<T> {
    private var content: [T] = []
    
    public func pop() -> T? {
        return content.removeFirst()
    }
    
    public func push(_ new: T) {
        content.insert(new, at: 0)
    }
}
