//
//  PDFExporter.swift
//  Business
//
//  Created by ian luo on 2019/7/15.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

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
    
    public func export(completion: @escaping (ExportResult) -> Void) {
        let htmlExporter = HTMLExporter(editorContext: self._editorContext, url: self.url)
        htmlExporter.export { exportContent in
            switch exportContent {
            case .string(let htmlString):
                self.keeper = self
                let webView = UIWebView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
                webView.delegate = self.tempDelegate
                webView.loadHTMLString(htmlString, baseURL: nil)
                UIApplication.shared.keyWindow?.addSubview(webView)
                self.tempDelegate.didLoaded = {
                    completion(.file(self._createPDF(string: htmlString)))
                    self.keeper = nil
                }
            default: break
            }
        }
    }
    
    class TempWebViewDelegate: NSObject, UIWebViewDelegate {
        var didLoaded: (() -> Void)?
        func webViewDidFinishLoad(_ webView: UIWebView) {
            didLoaded?()
        }
        
        func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
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
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(page, forKey: "printableRect")
        // 4. Create PDF context and draw
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, .zero, nil)
        for i in 0..<render.numberOfPages {
            UIGraphicsBeginPDFPage();
            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext();
        // 5. Save PDF file
        let outputURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: self.url.packageName, extension: self.fileExtension)
        pdfData.write(to: outputURL, atomically: true)
        
        return outputURL
    }
}
