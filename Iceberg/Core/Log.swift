//
//  Log.swift
//  Business
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public let log = Log()

public struct Log {
    public func error(_ error: Any) {
        print("[ERROR] \(error)")
    }
    
    public func info(_ info: Any) {
        print("[INFO] \(info)")
    }
    
    public func verbose(_ verbose: Any) {
        #if DEBUG
        print("[VERBOSE] \(verbose)")
        #endif
    }
}
