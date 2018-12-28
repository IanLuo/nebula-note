//
//  DocumentSearchViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol DocumentSearchViewControllerDelegate: class {
    
}

public class DocumentSearchViewController: UIViewController {
    private let viewModel: DocumentSearchViewModel
    
    public weak var delegate: DocumentSearchViewControllerDelegate?
    
    public init(viewModel: DocumentSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension DocumentSearchViewController: DocumentSearchViewModelDelegate {
    
}
