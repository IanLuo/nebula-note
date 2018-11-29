//
//  OutlineTextView.swift
//  Iceland
//
//  Created by ian luo on 2018/11/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol OutlineTextViewDelegate: class {
    func didTapOnLevel(textView: UITextView, chracterIndex: Int)
    func didTapOnCheckbox(textView: UITextView, characterIndex: Int, statusRange: NSRange)
    func didTapOnLink(textView: UITextView, characterIndex: Int, linkRange: NSRange)
}

public class OutlineTextView: UITextView {
    public weak var tapDelegate: OutlineTextViewDelegate?
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    
    @objc func tapped(guesture: UITapGestureRecognizer) {
        let location = guesture.location(in: self)
        
        let characterIndex = self.layoutManager.characterIndex(for: location,
                                                               in: self.textContainer,
                                                               fractionOfDistanceBetweenInsertionPoints: nil)
        
        if let outlineTextStorage = self.textStorage as? OutlineTextStorage {
            outlineTextStorage.currentLocation = characterIndex
            outlineTextStorage.updateCurrentInfo()
        }
        
        let attributes = self.textStorage.attributes(at: characterIndex, effectiveRange: nil)
        
        if attributes[OutlineTextStorage.OutlineAttribute.Heading.level] != nil {
            self.tapDelegate?.didTapOnLevel(textView: self, chracterIndex: characterIndex)
        } else if let statusRange = attributes[OutlineTextStorage.OutlineAttribute.Checkbox.box] as? NSRange {
            self.tapDelegate?.didTapOnCheckbox(textView: self, characterIndex: characterIndex, statusRange: statusRange)
        } else if let linkRange = attributes[OutlineTextStorage.OutlineAttribute.link] as? NSRange {
            self.tapDelegate?.didTapOnLink(textView: self, characterIndex: characterIndex, linkRange: linkRange)
        }
    }
}

