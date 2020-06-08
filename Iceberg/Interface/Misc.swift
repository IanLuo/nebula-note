//
//  Misc.swift
//  Interface
//
//  Created by ian luo on 2020/5/8.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation

public var isPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

public var isPad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

public var isMac: Bool {
    #if targetEnvironment(macCatalyst)
    return true
    #else
    return false
    #endif
}

public var isMacOrPad: Bool {
    return isPad || isMac
}
