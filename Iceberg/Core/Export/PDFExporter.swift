//
//  PDFExporter.swift
//  Business
//
//  Created by ian luo on 2019/7/15.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import Interface
import WebKit

public class PDFExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "pdf"
    
    private let _editorContext: EditorContext
    
    public init(editorContext: EditorContext, url: URL) {
        self._editorContext = editorContext
        self.url = url
    }
    
    let tempDelegate = TempWebViewDelegate()
    var keeper: Any?
    
    public func export(isMember: Bool, completion: @escaping (ExportResult) -> Void) {
        let htmlExporter = HTMLExporter(editorContext: self._editorContext, url: self.url)
        htmlExporter.export(isMember: isMember) { exportContent in
            switch exportContent {
            case .string(let htmlString):
                self.keeper = self
                
                let fileURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: "exportHTML", extension: "html")
                try? htmlString.write(to: fileURL, atomically: false, encoding: .utf8)
                let webView = WKWebView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
                webView.navigationDelegate = self.tempDelegate
                webView.loadFileURL(fileURL, allowingReadAccessTo: URL.directory(location: URLLocation.temporary))
                UIApplication.shared.keyWindow?.addSubview(webView)
                self.tempDelegate.didLoaded = {
                    completion(.file(self._createPDF(string: htmlString)))
                    self.keeper = nil
                }
            default: break
            }
        }
    }
    
    class TempWebViewDelegate: NSObject, WKNavigationDelegate {
        var didLoaded: (() -> Void)?
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if !webView.isLoading {
                self.didLoaded?()
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            log.error(error)
        }
    }
    
    private func _createPDF(string: String) -> URL {
        let html = string
        let fmt = UIMarkupTextPrintFormatter(markupText: html)
        
        // 2. Assign print formatter to UIPrintPageRenderer
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(fmt, startingAtPageAt: 0)
        // 3. Assign paperRect and printableRect
        let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 841) // A4, 72 dpi
        let page = pageBounds//CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(page, forKey: "printableRect")
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageBounds, nil)
        let context = UIGraphicsGetCurrentContext()!
        
        for i in 0..<render.numberOfPages {
            UIGraphicsBeginPDFPage();
            
            let backCoverView = UIView(frame: pageBounds)
            backCoverView.backgroundColor = InterfaceTheme.Color.background1
            backCoverView.layer.render(in: context)
            context.clear(pageBounds)

            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext();
        // 5. Save PDF file
        let outputURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: self.url.packageName, extension: self.fileExtension)
        pdfData.write(to: outputURL, atomically: true)
        
        return outputURL
    }
}
