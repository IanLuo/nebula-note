//
//  HeadingsOutlineViewController.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface
import Business

public enum OutlineLocation {
    case heading(DocumentHeading)
    case position(Int)
}

public protocol HeadingsOutlineViewControllerDelegate: class {
    func didSelect(url: URL, selection: OutlineLocation)
    func didCancel()
}

public class HeadingsOutlineViewController: SelectorViewController {
    private let viewModel: DocumentEditViewModel
    
    public weak var outlineDelegate: HeadingsOutlineViewControllerDelegate?
    
    public var ignoredHeadingLocation: Int? = nil
    
    public init(viewModel: DocumentEditViewModel) {
        self.viewModel = viewModel
        super.init()
        self.delegate = self
        viewModel.delegate = self
        self.emptyDataText = L10n.Document.Outlet.noHeading
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
        self.outlineDelegate?.didCancel()
    }
    
    public func SelectorDidSelect(index: Int, viewController: SelectorViewController) {
        switch index {
        case 0:
            self.outlineDelegate?.didSelect(url: self.viewModel.url, selection: .position(0))
        case self.items.count - 1:
            self.outlineDelegate?.didSelect(url: self.viewModel.url, selection: .position(self.viewModel.string.count))
        default:
            self.outlineDelegate?.didSelect(url: self.viewModel.url, selection: .heading(self.viewModel.documentHeading(at: index - 1))) // minus 1, because 1 is extra 'document beginnig'
        }
    }
}

extension HeadingsOutlineViewController: DocumentEditViewModelDelegate {
    public func documentContentCommandDidPerformed(result: DocumentContentCommandResult) {
        // ignore
    }
    
    public func didEnterTokens(_ tokens: [Token]) {
        // ignore
    }
    
    private func loadData() {
        let ignoredRange = self.viewModel.paragraphWithSubRange(at: self.ignoredHeadingLocation ?? -1)
        
        self.addItem(title: L10n.Browser.Outline.beginingOfDocument)
        
        for (index, heading) in self.viewModel.headings.enumerated() {
            let isEnabled = ignoredRange != nil ? ignoredRange!.intersection(heading.paragraphRange) == nil : true
            self.addItem(attributedString: self.attributedString(level: self.viewModel.level(index: index),
                                                                     string: self.viewModel.headingString(index: index)),
                         enabled: isEnabled)
        }
        
        self.addItem(title: L10n.Browser.Outline.endOfDocument)
        
        self.onCancel = { viewController in
            viewController.dismiss(animated: true, completion: nil)
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
        // ignore
    }
    
    public func updateHeadingInfo(heading: HeadingToken?) {
        // ignore
    }
    
    private func attributedString(level: Int, string: String) -> NSAttributedString {
        let prefix = "∙" * (level) * 1
        let infix = prefix.count > 0 ? " " : ""
        let labelString = prefix + infix + string
        let attributedString = NSMutableAttributedString(string: labelString)
        attributedString.setAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.descriptive,
                                        NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                                       range: NSRange(location: 0, length: prefix.nsstring.length))
        attributedString.setAttributes([NSAttributedString.Key.foregroundColor : InterfaceTheme.Color.interactive,
                                        NSAttributedString.Key.font : InterfaceTheme.Font.footnote],
                                       range: NSRange(location: prefix.count, length: labelString.nsstring.length - prefix.count))
        
        return attributedString
    }
}
