//
//  Thread+Helper.swift
//  Core
//
//  Created by ian luo on 2021/8/10.
//  Copyright © 2021 wod. All rights reserved.
//

import Foundation

extension Thread {
    public func perform(_ block: @escaping () -> Void) {
        guard Thread.current != self else { return block() }
        self.perform(#selector(runBlock(_:)), on: self, with: block, waitUntilDone: true)
    }
    
    @objc private func runBlock(_ block: () -> Void) {
        block()
    }
}
