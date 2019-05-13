//
//  ExtensionProperty.swift
//  UIComponent
//
//  Created by ian luo on 2017/9/26.
//  Copyright © 2017年 wod. All rights reserved.
//

import Foundation

extension NSObject {
    internal func setValue(_ value: Any!, key: UnsafeRawPointer) {
        objc_setAssociatedObject(self, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    internal func getValue(key: UnsafeRawPointer) -> Any? {
        return objc_getAssociatedObject(self, key)
    }
}
