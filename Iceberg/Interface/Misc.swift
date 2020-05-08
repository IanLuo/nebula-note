//
//  Misc.swift
//  Interface
//
//  Created by ian luo on 2020/5/8.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation

public var isPad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

public var isMacOrPad: Bool {
    #if targetEnvironment(macCatalyst)
    return true
    #else
    return isPad
    #endif
}
