//
//  AgendaActionViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/27.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol AgendaActionViewControllerDelegate: class {
    func openDocument(url: URL)
}

public class AgendaActionViewController: UIViewController {
    private let viewModel: AgendaActionViewModel
    public weak var delegate: AgendaActionViewControllerDelegate?
    
    public init(viewModel: AgendaActionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension AgendaActionViewController: AgendaActionViewModelDelegate {
    
}
