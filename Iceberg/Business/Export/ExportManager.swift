//
//  ExportProtocol.swift
//  Business
//
//  Created by ian luo on 2019/4/24.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import QuickLook

public protocol Exportable {
    var url: URL { get }
    var fileExtension: String { get }
    
    func export(completion: @escaping (ExportResult) -> Void)
}

public enum ExportResult {
    case string(String)
    case file(URL)
}

public enum ExportType: CaseIterable {
    case org
    case html
    case txt
    case markdown
    case pdf
    
    public var fileExtension: String {
        switch self {
        case .org: return ".org"
        case .html: return ".html"
        case .txt: return ".txt"
        case .markdown: return ".md"
        case .pdf: return ".pdf"
        }
    }
    
    public var title: String {
        switch self {
        case .org: return "Org"
        case .html: return "HTML"
        case .txt: return "TXT"
        case .markdown: return "Mark Down"
        case .pdf: return "PDF"
        }
    }
    
    public func exportable(url: URL, exportManager: ExportManager) -> Exportable {
        switch self {
        case .org: return OrgExporter(url: url)
        case .html: return HTMLExporter(editorContext: exportManager._editorContext, url: url)
        case .txt: return TxtExporter(editorContext: exportManager._editorContext, url: url)
        case .pdf: return PDFExporter(editorContext: exportManager._editorContext, url: url)
        default: return OrgExporter(url: url)
        }
    }
}

public struct ExportManager {
    fileprivate let _editorContext: EditorContext
    public init(editorContext: EditorContext) {
        self._editorContext = editorContext
    }
    
    public let exportMethods: [ExportType] = [.org, .html, .txt, .markdown, .pdf]
    
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
                exportable.export { exportedResult in
                    switch exportedResult {
                    case .string(let exportedContent):
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
                    case .file(let url):
                        completion(url)
                    }
                }
            }
        }
    }
    
    public func share(from: UIViewController, url: URL) {
        let activityViewController = self.createShareViewController(url: url)
        
        from.present(activityViewController, animated: true, completion: nil)
    }
    
    public func preview(from: UIViewController, url: URL) {
        let previewManager = PreviewManager(url: url)
        previewManager.preview(from: from)
    }
    
    public func createPreviewController(url: URL) -> UIViewController {
        return PreviewManager(url: url).createPreviewController()
    }
    
    public func createShareViewController(url: URL) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { [weak activityViewController] activityType, completed, returnedItem, error in
            activityViewController?.dismiss(animated: true, completion: nil)
        }
        
        activityViewController.excludedActivityTypes = nil
        
        return activityViewController
    }
}
