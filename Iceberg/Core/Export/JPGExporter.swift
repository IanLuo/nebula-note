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
    
    public func export(isMember: Bool, completion: @escaping (ExportResult) -> Void) {
        
    }
}
