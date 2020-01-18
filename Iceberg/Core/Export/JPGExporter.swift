//
//  JPGExportor.swift
//  Business
//
//  Created by ian luo on 2019/12/21.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import WebKit

public class JPGExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "jpg"
    
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
                let webView = WKWebView(frame: UIScreen.main.bounds)
                webView.alpha = 0.1
                webView.navigationDelegate = self.tempDelegate
                UIApplication.shared.keyWindow?.addSubview(webView)
                webView.loadHTMLString(htmlString, baseURL: nil)
                self.tempDelegate.didLoaded = {
                    webView.evaluateJavaScript("document.documentElement.scrollHeight") { (height, error) in
                        guard let height = height as? CGFloat else { return }
                        completion(.file(self._createImage(size: CGSize(width: webView.bounds.width, height: height), htmlString: htmlString)))
                        webView.removeFromSuperview()
                        self.keeper = nil
                    }
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
    
    private func _createImage(size: CGSize, htmlString: String) -> URL {
        let html = htmlString
        let fmt = UIMarkupTextPrintFormatter(markupText: html)
                
        // 2. Assign print formatter to UIPrintPageRenderer
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(fmt, startingAtPageAt: 0)
        // 3. Assign paperRect and printableRect
        let pageBounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let page = pageBounds//CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4, 72 dpi
        render.setValue(page, forKey: "paperRect")
        render.setValue(page, forKey: "printableRect")
        
        var image: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(InterfaceTheme.Color.background1.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        for i in 0..<render.numberOfPages {
            render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        
        image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        // 5. Save file
        let outputURL = URL.file(directory: URL.directory(location: URLLocation.temporary), name: self.url.packageName, extension: self.fileExtension)
        if let image = image {
            do {
                try image.jpegData(compressionQuality: 1)?.write(to: outputURL)
            } catch {
                log.error(error)
            }
        }
        
        return outputURL
    }
}
