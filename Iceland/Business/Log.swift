//
//  Log.swift
//  Business
//
//  Created by ian luo on 2018/12/30.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import SwiftyBeaver

internal let log = SwiftyBeaver.self

public struct Log {
    let console = ConsoleDestination()
    
    public init() {
        console.format = "$DHH:mm:ss$d $L $M"
        console.minLevel = .info
        
        log.addDestination(console)
    }
}
