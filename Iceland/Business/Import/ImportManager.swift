//
//  ImportManager.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public enum ImportError: Error {
    case wrongTypeOfFile
    case failToCreateDocument
    case invalidContent
}

public protocol Importable {
    var url: URL { get }
    
    func createDocument(documentManager: DocumentManager, completion: @escaping (Result<URL, ImportError>) -> Void)
}

public enum ImportType: String {
    case org
    case md
    case txt
    
    public var title: String {
        switch self {
        case .org: return "Org"
        case .md: return "Mark Down"
        case .txt: return "TXT"
        }
    }
    
    public func importer(url: URL) -> Importable {
        switch self {
        default: return OrgImporter(url: url)
        }
    }
}

public struct ImportManager {
    let documentManager: DocumentManager
    
    public func importFile(url: URL, completion: @escaping (Result<URL, ImportError>) -> Void) {
        guard let type = ImportType(rawValue: url.pathExtension) else { completion(Result.failure(ImportError.wrongTypeOfFile)); return }
        
        type.importer(url: url).createDocument(documentManager: self.documentManager, completion: completion)
    }
}
