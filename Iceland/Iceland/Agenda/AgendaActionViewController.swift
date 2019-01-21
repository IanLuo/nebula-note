//
//  AgendaActionViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/27.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class AgendaActionViewController: UIViewController {
    private let viewModel: AgendaActionViewModel
    
    public init(viewModel: AgendaActionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension AgendaActionViewController: AgendaActionViewModelDelegate {
    public func didUpdated() {
        
    }
}
