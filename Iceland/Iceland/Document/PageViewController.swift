//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public class PageViewController: UIViewController {
    private let textView: OutlineTextView
    private let viewModel: PageViewModel
    
    public init(viewModel: PageViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero, textContainer: viewModel.pageController.textContainer)
        self.textView.tapDelegate = viewModel.pageController
        
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
        
        viewModel.loadDocument()
    }
}

extension PageViewController: PageViewModelDelegate {
    public func didLoadDocument(text: String) {
        self.textView.text = text
    }
}


