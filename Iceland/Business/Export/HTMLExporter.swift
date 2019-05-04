//
//  HTMLExporter.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct HTMLExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "html"
    
    public init(url: URL) {
        self.url = url
    }
    
    public func export() -> String {
        return  ""
    }
}
