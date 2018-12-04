//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class DocumentEditViewController: UIViewController {
    private let textView: OutlineTextView
    private let viewModel: DocumentEditViewModel
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero, textContainer: viewModel.editorController.textContainer)
        self.textView.outlineDelegate = viewModel.editorController
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.frame = self.view.bounds
        
        self.view.addSubview(self.textView)
        
        viewModel.delegate = self
        
        viewModel.open()
    }
}

extension DocumentEditViewController: DocumentEditDelegate {
    public func didCloseDocument() {
        
    }
    
    public func didFailedToCloseDocument() {
        
    }
    
    public func didDeleteDocument(url: URL) {
        
    }
    
    public func didFailedToDeleteDocument(error: Error) {
        
    }
    
    public func didRename() {
        
    }
    
    public func didFailToRename(with error: Error) {
        
    }
    
    public func didSaveDocument() {
        
    }
    
    public func didFailedToSaveDocument(with error: Error) {
        
    }
    
    public func didFailedToOpenDocument(with error: Error) {
        
    }
    
    public func didOpenDocument(text: String) {
        self.textView.text = text
    }
}


