//
//  Org.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct OrgExporter: Exportable {
    public func export(completion: @escaping (String) -> Void) {
        let doc = Document(fileURL: self.url)
        
        doc.open { [weak doc] result in
            guard let strongDoc = doc else { return }
            completion(strongDoc.string)
        }
    }
    
    public let url: URL
    public var fileExtension: String = "org"
        
    public init(url: URL) {
        self.url = url
    }
}
