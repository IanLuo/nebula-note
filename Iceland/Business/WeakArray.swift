//
//  WeakArray.swift
//  Business
//
//  Created by ian luo on 2019/3/12.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public class WeakArray<Element: AnyObject> {
    private var elements: NSPointerArray = NSPointerArray.weakObjects()
    
    public func append(_ element: Element?) {
        if let element = element {
            let pointer = Unmanaged.passUnretained(element).toOpaque()
            self.elements.addPointer(pointer)
        } else {
            self.elements.addPointer(nil)
        }
    }
    
    public func append(contentsOf: [Element]) {
        for e in contentsOf {
            self.append(e)
        }
    }
    
    public func insert(_ element: Element?, at index: Int) {
        if let element = element {
            let pointer = Unmanaged.passUnretained(element).toOpaque()
            self.elements.insertPointer(pointer, at: index)
        } else {
            self.elements.insertPointer(nil, at: index)
        }
    }
    
    public func insert(_ elements: [Element], at index: Int) {
        for i in 0..<elements.count {
            self.insert(elements[i], at: index + i)
        }
    }
    
    public subscript(_ index: Int) -> Element? {
        get {
            guard index < self.elements.count else { return nil }
            guard let pointer = self.elements.pointer(at: index) else { return nil }
            return Unmanaged<Element>.fromOpaque(pointer).takeUnretainedValue()
        }
        
        set {
            self.insert(newValue, at: index)
        }
    }
    
    public func remove(at index: Int) -> Element? {
        let element = self[index]
        self.elements.removePointer(at: index)
        return element
    }
    
    public func compact() -> Int {
        let count = self.count
        self.elements.addPointer(nil) // work around http://www.openradar.me/15396578
        self.elements.compact()
        return count - self.count
    }
    
    public func remove(_ condition: (Element) -> Bool) -> Int {
        var count = 0
        for i in 0..<self.count {
            if let e = self[i] {
                if condition(e) {
                    _ = self.remove(at: i)
                    count += 1
                }
            }
        }
        
        return count
    }
    
    public var allObjects: [Element] {
        return self.elements.allObjects.map { $0 as! Element }
    }
    
    public var count: Int {
        return self.elements.count
    }
}

extension WeakArray: CustomStringConvertible {
    public var description: String {
        return self.elements.debugDescription
    }
}
