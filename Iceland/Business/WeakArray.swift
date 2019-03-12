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
    
    public func compact() {
        self.elements.addPointer(nil) // work around http://www.openradar.me/15396578
        self.elements.compact()
    }
    
    public var allObjects: [Element] {
        return self.elements.allObjects.map { $0 as! Element }
    }
    
    public var count: Int {
        return self.elements.count
    }
}
