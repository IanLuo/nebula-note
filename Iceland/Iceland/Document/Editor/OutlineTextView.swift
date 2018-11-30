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
    private let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()
    
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    private func tapped(guesture: UITapGestureRecognizer) -> Bool {
        let location = guesture.location(in: self)
        
        let characterIndex = self.layoutManager.characterIndex(for: location,
                                                               in: self.textContainer,
                                                               fractionOfDistanceBetweenInsertionPoints: nil)
        
        if let outlineTextStorage = self.textStorage as? OutlineTextStorage {
            outlineTextStorage.currentLocation = characterIndex
            outlineTextStorage.updateCurrentInfo()
        }
        
        let attributes = self.textStorage.attributes(at: characterIndex, effectiveRange: nil)
        
        var shouldPassTapToOtherGuestureRecognizers = false
        if attributes[OutlineAttribute.Heading.level] != nil {
            self.tapDelegate?.didTapOnLevel(textView: self, chracterIndex: characterIndex)
        } else if let statusRange = attributes[OutlineAttribute.Checkbox.box] as? NSRange {
            self.tapDelegate?.didTapOnCheckbox(textView: self, characterIndex: characterIndex, statusRange: statusRange)
        } else if let linkRange = attributes[OutlineAttribute.link] as? NSRange {
            self.tapDelegate?.didTapOnLink(textView: self, characterIndex: characterIndex, linkRange: linkRange)
        } else {
            shouldPassTapToOtherGuestureRecognizers = true
        }
        
        return shouldPassTapToOtherGuestureRecognizers
    }
}

extension OutlineTextView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.tapGestureRecognizer {
            return self.tapped(guesture: self.tapGestureRecognizer)
        } else {
            return true
        }
    }
}
