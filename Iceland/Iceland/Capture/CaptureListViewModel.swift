//
//  CaptureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol CaptureListViewModelDelegate: class {
    func didLoadData()
    func didRefileAttachment(index: Int)
}

public class CaptureListViewModel {
    public typealias Dependency = CaptureCoordinator
    public weak var delegate: CaptureListViewModelDelegate?
    public weak var dependency: Dependency?
    
    public var data: [Attachment] = []
    
    public func loadAllCapturedData() {
        
    }
    
    public func delete(attachment: String) {
        
    }
    
    public func refile(headingLocation: Int, attachmentIndex: Int) {
        
    }
    
    public func newHeading(before headingLocation: Int, attachmentIndex: Int) {
        
    }
    
    public func newHeading(after headingLocation: Int, attachmentIndex: Int) {
        
    }
    
    public func newFile(content: String, attachmentIndex: Int) {
        
    }
}
