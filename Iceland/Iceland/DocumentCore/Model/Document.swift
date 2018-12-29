//
//  Document.swift
//  Iceland
//
//  Created by ian luo on 2018/12/3.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Storage

public class Document: UIDocument {
    public static let fileExtension = "org"
    var string: String = ""
    var title: String = ""
    
    public override init(fileURL url: URL) {
        let ext = url.absoluteString.hasSuffix(Document.fileExtension) ? "" : Document.fileExtension
        super.init(fileURL: url.appendingPathExtension(ext))
    }
    
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

extension URL {
    public func delete(completion: @escaping (Error?) -> Void) {
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)
        let fileAccessIntent = NSFileAccessIntent.writingIntent(with: self, options: NSFileCoordinator.WritingOptions.forDeleting)
        let queue = OperationQueue()
        queue.qualityOfService = .background
        fileCoordinator.coordinate(with: [fileAccessIntent], queue: queue) { error in
            if let error = error {
                completion(error)
            } else {
                do {
                    try FileManager.default.removeItem(at: fileAccessIntent.url)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    public func rename(url: URL, completion: ((Error?) -> Void)?) {
        let oldURL = self
        let newURL = url
        var error: NSError?
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            fileCoordinator.coordinate(writingItemAt: oldURL,
                                       options: NSFileCoordinator.WritingOptions.forMoving,
                                       writingItemAt: newURL,
                                       options: NSFileCoordinator.WritingOptions.forReplacing,
                                       error: &error,
                                       byAccessor: { (newURL1, newURL2) in
                                        do {
                                            let fileManager = FileManager.default
                                            fileCoordinator.item(at: oldURL, willMoveTo: newURL)
                                            try fileManager.moveItem(at: newURL1, to: newURL2)
                                            fileCoordinator.item(at: oldURL, didMoveTo: newURL)
                                            DispatchQueue.main.async {
                                                completion?(error)
                                            }
                                        } catch {
                                            DispatchQueue.main.async {
                                                completion?(error)
                                            }
                                        }
                                        
            })
        }
    }
}


extension String {
    public func subString(_ range: NSRange) -> String {
        return (self as NSString).substring(with: range)
    }
}
