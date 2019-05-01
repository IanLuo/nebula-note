//
//  Org.swift
//  Business
//
//  Created by ian luo on 2019/4/27.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct OrgImporter: Importable {
    public var url: URL
    
    public func createDocument(documentManager: DocumentManager, completion: @escaping (URL) -> Void) {
        documentManager.add(title: self.url.fileName, below: nil, completion: { url in
            if let url = url {
                completion(url)
            }
        })
    }
}
