//
//  Localization.swift
//  Business
//
//  Created by ian luo on 2019/1/1.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

extension String {
    public var localizable: String {
        return NSLocalizedString(self, comment: "")
    }
}
