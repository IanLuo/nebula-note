//
//  HeadingsOutlineViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Business

public protocol HeadingsOutlineViewControllerDelegate: class {
    func didSelectHeading(url: URL, heading: Document.Heading)
}

public class HeadingsOutlineViewController: SelectorViewController {
    private let viewModel: DocumentEditViewModel
    
    public weak var outlineDelegate: HeadingsOutlineViewControllerDelegate?
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        viewModel.delegate = self
        self.emptyDataText = "There's no heading in this document yet"
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.showProcessingAnimation()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

extension HeadingsOutlineViewController: SelectorViewControllerDelegate {
    public func SelectorDidCancel(viewController: SelectorViewController) {
        self.viewModel.dependency?.stop()
    }
    
    public func SelectorDidSelect(index: Int, viewController: SelectorViewController) {
        self.outlineDelegate?.didSelectHeading(url: self.viewModel.url, heading: self.viewModel.headings[index])
    }
}

extension HeadingsOutlineViewController: DocumentEditViewModelDelegate {
    private func loadData() {
        for index in 0..<self.viewModel.headings.count {
            self.addItem(attributedString: self.attributedString(level: self.viewModel.level(index: index),
                                                                     string: self.viewModel.headingString(index: index)))
        }
        
        self.view.hideProcessingAnimation()
        
        if self.items.count == 0 {
            super.showEmptyDataView()
        }
    }
    
    public func didReadyToEdit() {
        self.loadData()
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func showLink(url: URL) {
        
    }
    
    public func updateHeadingInfo(heading: Document.Heading?) {
        
    }
    
    private func attributedString(level: Int, string: String) -> NSAttributedString {
        let prefix = "∙" * (level - 1) * 3
        let infix = prefix.count > 0 ? " " : ""
        let labelString = prefix + infix + string
        let attributedString = NSMutableAttributedString(string: labelString)
        attributedString.setAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive,
                                        NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                                       range: NSRange(location: 0, length: prefix.count))
        attributedString.setAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.interactive,
                                        NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                                       range: NSRange(location: prefix.count, length: labelString.count - prefix.count))
        
        return attributedString
    }
}

fileprivate func *(lhs: String, rhs: Int) -> String {
    guard rhs > 0 else { return "" }
    var s = lhs
    for _ in 1..<rhs {
        s.append(lhs)
    }
    
    return s
}
