//
//  DocumentBrowserViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/4.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol DocumentBrowserViewControllerDelegate: class {
    func didSelectDocument(url: URL)
    
    func didSelectDocumentHeading(url: URL, heading: OutlineTextStorage.Heading)
}

public class DocumentBrowserViewController: UIViewController {
    let viewModel: DocumentBrowserViewModel
    
    public weak var delegate: DocumentBrowserViewControllerDelegate?
    
    public init(viewModel: DocumentBrowserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocumentBrowserViewController: DocumentBrowserViewModelDelegate {
    
}
