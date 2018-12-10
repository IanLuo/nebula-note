//
//  CaptureListViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/8.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public protocol CaptureListViewModelDelegate: class {

}

public class CaptureListViewModel {
    public weak var delegate: CaptureListViewModelDelegate?
    
    public var dataLoaded: (() -> Void)?
    
    public func loadAllCapturedData() {
        
    }
    
    public func delete(attachment: String) {
        
    }
    
    public func refile(headingLocation: Int, attachment: String) {
        
    }
    
    public func newHeading(before headingLocation: Int, attachment: String) {
        
    }
    
    public func newHeading(after headingLocation: Int, attachment: String) {
        
    }
    
    public func newFile(content: String, attachment: String) {
        
    }
}
