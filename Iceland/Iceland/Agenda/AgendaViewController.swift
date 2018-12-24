//
//  AgendaViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class AgendaViewController: UIViewController {
    private let viewModel: AgendaViewModel
    
    public init(viewModel: AgendaViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.loadTODOs()
    }
}

extension AgendaViewController: AgendaViewModelDelegate {
    public func didLoadData() {
        
    }
    
    public func didFailed(_ error: Error) {
        
    }
}
