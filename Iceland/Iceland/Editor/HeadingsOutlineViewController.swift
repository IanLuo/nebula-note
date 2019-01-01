//
//  HeadingsOutlineViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol HeadingsOutlineViewControllerDelegate: class {
    func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading)
}

public class HeadingsOutlineViewController: UIViewController {
    private let viewModel: DocumentEditViewModel
    
    public weak var delegate: HeadingsOutlineViewControllerDelegate?
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension HeadingsOutlineViewController: DocumentEditViewModelDelegate {
    public func didReadToEdit() {
        
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func showLink(url: URL) {
        
    }
    
    public func updateHeadingInfo(heading: OutlineTextStorage.Heading?) {
        
    }
}
