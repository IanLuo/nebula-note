//
//  PDFExporter.swift
//  Business
//
//  Created by ian luo on 2019/7/15.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation

public struct PDFExporter: Exportable {
    public var url: URL
    
    public var fileExtension: String = "pdf"
    
    private let _editorContext: EditorContext
    
    public init(editorContext: EditorContext, url: URL) {
        self._editorContext = editorContext
        self.url = url
    }
    
    public func export(completion: @escaping (ExportResult) -> Void) {
        let htmlExporter = HTMLExporter(editorContext: self._editorContext, url: self.url)
        htmlExporter.export { exportContent in
            switch exportContent {
            case .string(let htmlString):
                completion(.file(self._createPDF(string: htmlString)))
            default: break
            }
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
        guard let outputURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(self.url.packageName).appendingPathExtension(self.fileExtension)
            else { fatalError("Destination URL not created") }
        pdfData.write(to: outputURL, atomically: true)
        
        return outputURL
    }
}
