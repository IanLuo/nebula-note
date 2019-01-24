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
    func didTapOnLevel(textView: UITextView, chracterIndex: Int, heading: [String: NSRange], point: CGPoint)
    func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: [String: NSRange], point: CGPoint)
    func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String: NSRange], point: CGPoint)
}

public class OutlineTextView: UITextView {
    public weak var outlineDelegate: OutlineTextViewDelegate?
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
        
        self.tintColor = InterfaceTheme.Color.spotLight
    }
    
    private var lastTap: (CGPoint, Bool) = (.zero, true)
    
    private func tapped(gesture: UITapGestureRecognizer) -> Bool {
        guard gesture.location(in: self) != lastTap.0 else { return lastTap.1 }
        
        guard self.text.count > 0 else { return true }
        
        let location = gesture.location(in: self)
        
        let characterIndex = self.layoutManager.characterIndex(for: location,
                                                               in: self.textContainer,
                                                               fractionOfDistanceBetweenInsertionPoints: nil)
        
        if let outlineTextStorage = self.textStorage as? OutlineTextStorage {
            outlineTextStorage.currentLocation = characterIndex
            outlineTextStorage.updateCurrentInfo()
        }
        
        let attributes = self.textStorage.attributes(at: characterIndex, effectiveRange: nil)
        
        var shouldPassTapToOtherGuestureRecognizers = false
        if let heading = attributes[OutlineAttribute.Heading.level] as? [String: NSRange] {
            self.outlineDelegate?.didTapOnLevel(textView: self, chracterIndex: characterIndex, heading: heading, point: location)
        } else if let checkbox = attributes[OutlineAttribute.Checkbox.box] as? [String: NSRange] {
            self.outlineDelegate?.didTapOnCheckbox(textView: self, characterIndex: characterIndex, checkbox: checkbox, point: location)
        } else if let linkStructure = attributes[OutlineAttribute.Link.link] as? [String: NSRange] {
            self.outlineDelegate?.didTapOnLink(textView: self, characterIndex: characterIndex, linkStructure: linkStructure, point: location)
        } else {
            shouldPassTapToOtherGuestureRecognizers = true
        }
        
        lastTap = (location, shouldPassTapToOtherGuestureRecognizers)
        
        return shouldPassTapToOtherGuestureRecognizers
    }
}

extension OutlineTextView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 拦截 textView 中点击到需要与用户交互的 tap, 比如折叠，checkbox，link 等
        if gestureRecognizer == self.tapGestureRecognizer {
            return self.tapped(gesture: self.tapGestureRecognizer)
        } else {
            return true
        }
    }
}
