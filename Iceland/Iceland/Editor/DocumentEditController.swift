//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol DocumentEditViewControllerDelegate: class {
    func didTapLink(url: URL, title: String, point: CGPoint)
    func didChooseHeading(heading: OutlineTextStorage.Heading)
}

public class DocumentEditViewController: UIViewController {
    private let textView: OutlineTextView
    private let viewModel: DocumentEditViewModel
    
    public weak var delegate: DocumentEditViewControllerDelegate?
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero,
                                        textContainer: viewModel.editorController.textContainer)
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
        
        viewModel.open { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.textView.selectedRange = NSRange(location: strongSelf.viewModel.onLoadingLocation,
                                                        length: 0)
        }
        
    }
}

extension DocumentEditViewController: DocumentEditViewModelDelegate {
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func showLink(url: URL) {
        
    }
    
    public func updateHeadingInfo(heading: OutlineTextStorage.Heading?) {
        
    }
}
