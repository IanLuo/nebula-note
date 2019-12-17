//
//  DispatchQueue.swift
//  Business
//
//  Created by ian luo on 2019/12/17.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

extension DispatchQueue {
    public static func runOnMainQueueSafely(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}
