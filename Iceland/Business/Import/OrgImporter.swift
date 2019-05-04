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
    
    public func createDocument(documentManager: DocumentManager, completion: @escaping (Result<URL, ImportError>) -> Void) {
        guard let content = try? String(contentsOf: self.url, encoding: .utf8) else { completion(.failure(.invalidContent)); return }
        documentManager.add(title: self.url.deletingPathExtension().lastPathComponent, below: nil, content: content, completion: { url in
            if let url = url {
                completion(.success(url))
            } else {
                completion(.failure(.failToCreateDocument))
            }
        })
    }
}
