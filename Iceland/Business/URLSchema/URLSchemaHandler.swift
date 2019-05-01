//
//  URLSchemaHandler.swift
//  Business
//
//  Created by ian luo on 2019/4/28.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct URLSchemaHandler {
    public func handleFile(url: URL) {
        switch url.fileExtension {
        case "org": break
        case "md": break
        default: break
        }
    }
}
