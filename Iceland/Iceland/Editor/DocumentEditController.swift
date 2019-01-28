//
//  Page.swift
//  Iceland
//
//  Created by ian luo on 2018/11/6.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol DocumentEditViewControllerDelegate: class {
    func didTapLink(url: URL, title: String, point: CGPoint)
}

public class DocumentEditViewController: UIViewController {
    private let textView: OutlineTextView
    private let viewModel: DocumentEditViewModel
    
    public weak var delegate: DocumentEditViewControllerDelegate?
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        self.textView = OutlineTextView(frame: .zero,
                                        textContainer: viewModel.container)
        self.textView.contentInset = UIEdgeInsets(top: 160, left: 30, bottom: 80, right: 30)

        super.init(nibName: nil, bundle: nil)
        
        self.textView.outlineDelegate = self
        self.textView.delegate = self
        viewModel.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.frame = self.view.bounds
        
        self.view.addSubview(self.textView)
        
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "cross")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.descriptive, size: .singlePoint), for: .normal)
        closeButton.tintColor = InterfaceTheme.Color.interactive
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        closeButton.layer.cornerRadius = 20
        closeButton.layer.masksToBounds = true
        
        self.view.addSubview(closeButton)
        closeButton.sideAnchor(for: [.left, .top], to: self.view, edgeInset: 30)
        closeButton.sizeAnchor(width: 40, height: 40)
    }
    
    @objc private func cancel() {
        self.textView.endEditing(true)
        self.viewModel.dependency?.stop()
    }
}

extension DocumentEditViewController: OutlineTextViewDelegate {
    public func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String : NSRange], point: CGPoint) {

    }
    
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int, heading: [String : NSRange], point: CGPoint) {
        self.viewModel.changeFoldingStatus(location: chracterIndex)
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: [String : NSRange], point: CGPoint) {
        self.viewModel.changeCheckboxStatus(range: checkbox["checkbox-box"]!)
    }
}

extension DocumentEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.viewModel.didUpdate()
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}

extension DocumentEditViewController: DocumentEditViewModelDelegate {
    public func didReadyToEdit() {
        self.textView.selectedRange = NSRange(location: self.viewModel.onLoadingLocation,
                                                    length: 0)
        self.textView.scrollRangeToVisible(self.textView.selectedRange)
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func showLink(url: URL) {
        
    }
    
    public func updateHeadingInfo(heading: Document.Heading?) {
        
    }
}
