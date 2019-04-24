//
//  Org.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct OrgExporter: Exportable {
    public let url: URL
    public var fileExtension: String = "org"
    
    public func export(content: String) -> String {
        return content
    }
    
    public init(url: URL) {
        self.url = url
    }
}
