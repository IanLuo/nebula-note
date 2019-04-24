//
//  ExportProtocol.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol Exportable {
    var url: URL { get }
    var fileExtension: String { get }
    
    func export(content: String) -> String
}

public protocol ExportableItem {
    func generate() -> String
}

public struct ExportManager {
    public init() {}
    
    public let exportMethods: [String] = ["Org", "HTML", "TXT", "Markdown"]
    
    public func export(content: String, exportable: Exportable, completion: @escaping (URL) -> Void,
                       failure: @escaping (Error) -> Void) {
        let exportFileDir = URL.directory(location: URLLocation.temporary, relativePath: "export")
        exportFileDir.createDirectoryIfNeeded { error in
            
            if let error = error {
                failure(error)
            } else {
                let translated = exportable.export(content: content)
                let fileName = exportable.url.fileName
                let tempFileURL = URL.file(directory: exportFileDir, name: fileName, extension: exportable.fileExtension)
                
                do {
                    try translated.write(to: tempFileURL, atomically: true, encoding: .utf8)
                    completion(tempFileURL)
                } catch {
                    failure(error)
                }
            }
        }
    }
    
    public func share(from: UIViewController) {
        let activityViewController = UIActivityViewController(activityItems: [], applicationActivities: [])
        
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            
        }
        
        from.present(activityViewController, animated: true, completion: nil)
    }
}
