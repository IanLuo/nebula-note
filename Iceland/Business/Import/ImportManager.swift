//
//  ImportManager.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public protocol Importable {
    var url: URL { get }
    
    func createDocument(documentManager: DocumentManager)
}

public enum ImportType {
    case org
    case md
    case txt
}

public struct ImportManager {
    let documentManager: DocumentManager
    
    public func importFile(url: URL, type: ImportType) {
        
    }
}
