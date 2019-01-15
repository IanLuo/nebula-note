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
    func didSelectHeading(url: URL, heading: OutlineTextStorage.Heading)
}

public class HeadingsOutlineViewController: UIViewController {
    private let viewModel: DocumentEditViewModel
    
    public weak var delegate: HeadingsOutlineViewControllerDelegate?
    
    private let selector:SelectorViewController = SelectorViewController()
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        viewModel.delegate = self
        self.setupUI()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func setupUI() {
        self.view.addSubview(self.selector.view)
        
        self.selector.delegate = self
    }
}

extension HeadingsOutlineViewController: SelectorViewControllerDelegate {
    public func SelectorDidCancel(viewController: SelectorViewController) {
        self.viewModel.dependency?.stop()
    }
    
    public func SelectorDidSelect(index: Int, viewController: SelectorViewController) {
        self.delegate?.didSelectHeading(url: self.viewModel.url, heading: self.viewModel.headings[index])
    }
}

extension HeadingsOutlineViewController: DocumentEditViewModelDelegate {
    private func loadData() {
        for index in 0..<self.viewModel.headings.count {
            selector.addItem(attributedString: self.attributedString(level: self.viewModel.level(index: index),
                                                                     string: self.viewModel.headingString(index: index)))
        }
    }
    
    public func didReadyToEdit() {
        self.loadData()
    }
    
    public func documentStatesChange(state: UIDocument.State) {
        
    }
    
    public func showLink(url: URL) {
        
    }
    
    public func updateHeadingInfo(heading: OutlineTextStorage.Heading?) {
        
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
