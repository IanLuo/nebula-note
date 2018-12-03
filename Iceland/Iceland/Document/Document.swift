//
//  Document.swift
//  Iceland
//
//  Created by ian luo on 2018/12/3.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class Document: UIDocument {
    var string: String = ""
    
    public override var fileType: String? { return "txt" }
    
    public override func contents(forType typeName: String) throws -> Any {
        return string.data(using: .utf8) as Any
    }
    
    public override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let data = contents as? Data {
            self.string = String(data: data, encoding: .utf8)!
        }
    }
}
