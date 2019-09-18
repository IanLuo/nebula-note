//
//  DocumentBrowserCellModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol DocumentBrowserCellModelDelegate: class {
    func didRename(from: URL, to: URL)
    func didDelete(url: URL)
    
}

public class DocumentBrowserCellModel {
    public var url: URL
    public var isFolded: Bool = true
    public var parent: URL?
    public var levelFromRoot: Int
    public var shouldShowActions: Bool = true
    public var shouldShowChooseHeadingIndicator: Bool = false
    public var cover: UIImage?
    
    public init(url: URL) {
        self.url = url
        self.parent = url.parentDocumentURL
        self.levelFromRoot = url.documentRelativePath.components(separatedBy: "/").filter { $0.count > 0 }.count
    }
    
    public func parentChanged(newParent: URL) {
        self.parent = newParent
        
        self.url = newParent.convertoFolderURL.appendingPathComponent(self.url.lastPathComponent)
    }
    
    public func rename(to: URL) {
        
    }
    
    public func delete() {
        
    }
    
    /// check if there's sub files, any delete empty folder if there is any empty child file folder
    /// `an empty child file folder is remained, if child file move to other place, or deleted`
    public var hasSubDocuments: Bool {
        if url.hasSubDocuments {
            if url.isEmptyFolder {
                url.convertoFolderURL.delete(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background)) { error in
                    if let error = error {
                        log.error(error)
                    }
                }
                return false
            }
            
            return true
        }
        
        return false
    }
}
