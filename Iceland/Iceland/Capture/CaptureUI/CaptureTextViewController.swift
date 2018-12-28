//
//  CaptureTextViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/23.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class CaptureTextViewController: UIViewController {
    private let viewModel: CaptureViewModel
    
    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
