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
    
    func export(completion: @escaping (String) -> Void)
}

public enum ExportType {
    case org
    case html
    case txt
    case markdown
    
    public var fileExtension: String {
        switch self {
        case .org: return ".org"
        case .html: return ".html"
        case .txt: return ".txt"
        case .markdown: return ".md"
        }
    }
    
    public var title: String {
        switch self {
        case .org: return "Org"
        case .html: return "HTML"
        case .txt: return "TXT"
        case .markdown: return "Mark Down"
        }
    }
    
    public func exportable(url: URL, exportManager: ExportManager) -> Exportable {
        switch self {
        case .org: return OrgExporter(url: url)
        case .html: return HTMLExporter(editorContext: exportManager._editorContext, url: url)
        case .txt: return TxtExporter(editorContext: exportManager._editorContext, url: url)
        default: return OrgExporter(url: url)
        }
    }
}

public struct ExportManager {
    fileprivate let _editorContext: EditorContext
    public init(editorContext: EditorContext) {
        self._editorContext = editorContext
    }
    
    public let exportMethods: [ExportType] = [.org, .html, .txt, .markdown]
    
    public func export(url: URL,
                       type: ExportType, 
                       completion: @escaping (URL) -> Void,
                       failure: @escaping (Error) -> Void) {
        
        let exportable = type.exportable(url: url, exportManager: self)
        let exportFileDir = URL.directory(location: URLLocation.temporary, relativePath: "export")
        exportFileDir.createDirectoryIfNeeded { error in
            
            if let error = error {
                failure(error)
            } else {
                exportable.export { exportedContent in
                    let fileName = exportable.url.deletingPathExtension().lastPathComponent
                    let tempFileURL = URL.file(directory: exportFileDir, name: fileName, extension: exportable.fileExtension)
                    
                    do {
                        try exportedContent.write(to: tempFileURL, atomically: true, encoding: .utf8)
                        DispatchQueue.main.async {
                            completion(tempFileURL)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            failure(error)
                        }
                    }
                }
            }
        }
    }
    
    public func share(from: UIViewController, url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItem, error in
            // TODO:
        }
        
        activityViewController.excludedActivityTypes = nil
        
        from.present(activityViewController, animated: true, completion: nil)
    }
}
