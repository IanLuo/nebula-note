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
    
    private let toolBar: UIView = UIView()
    
    private var closeButton: UIButton!
    private var searchButton: UIButton!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.frame = self.view.bounds
        
        self.view.addSubview(self.textView)
        self.view.addSubview(self.toolBar)
        
        let image = self.viewModel.coordinator?.isModal == true ? UIImage(named: "down") : UIImage(named: "left")
        self.closeButton = self.createActionButton(icon: image?.withRenderingMode(.alwaysTemplate))
        self.searchButton = self.createActionButton(icon: UIImage(named: "zoom")?.withRenderingMode(.alwaysTemplate))
        
        self.closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        self.searchButton.addTarget(self, action: #selector(search), for: .touchUpInside)
        
        self.toolBar.addSubview(closeButton)
        self.toolBar.addSubview(searchButton)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.toolBar.size(width: self.view.bounds.width, height: 80)
            .align(to: self.view, direction: AlignmentDirection.top, position: AlignmentPosition.middle, inset: 0)

        self.closeButton.size(width: 40, height: 40)
            .alignToSuperview(direction: AlignmentDirection.right, position: AlignmentPosition.middle, inset: 30)
        
        self.searchButton.size(width: 40, height: 40)
            .alignToSuperview(direction: AlignmentDirection.left, position: AlignmentPosition.middle, inset: 30)
    }
    
    @objc private func cancel() {
        self.textView.endEditing(true)
        self.viewModel.save {}
        self.viewModel.coordinator?.stop()
    }
    
    @objc private func search() {
        self.viewModel.coordinator?.search()
    }
    
    private func createActionButton(icon: UIImage?) -> UIButton {
        let button = UIButton()
        button.setImage(icon, for: .normal)
        button.setBackgroundImage(UIImage.create(with: InterfaceTheme.Color.background2, size: .singlePoint), for: .normal)
        button.tintColor = InterfaceTheme.Color.interactive
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }
}

extension DocumentEditViewController: OutlineTextViewDelegate {
    public func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String : NSRange], point: CGPoint) {

    }
    
    public func didTapOnLevel(textView: UITextView, chracterIndex: Int, heading: [String : NSRange], point: CGPoint) {
        self.viewModel.changeFoldingStatus(location: chracterIndex)
    }
    
    public func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: [String : NSRange], point: CGPoint) {
        self.viewModel.changeCheckboxStatus(range: checkbox["status"]!)
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
