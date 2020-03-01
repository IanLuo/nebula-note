//
//  OutlineTextView.swift
//  Iceland
//
//  Created by ian luo on 2018/11/29.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public protocol OutlineTextViewDelegate: class {
    func didTapOnLevel(textView: UITextView, chracterIndex: Int, point: CGPoint)
    func didTapOnHiddenAttachment(textView: UITextView, characterIndex: Int, point: CGPoint)
    func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: String, point: CGPoint)
    func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String: String], point: CGPoint)
    func didTapOnTags(textView: UITextView, characterIndex: Int, tags: [String], point: CGPoint)
    func didTapDateAndTime(textView: UITextView, characterIndex: Int, dateAndTimeString: String, point: CGPoint)
    func didTapOnPlanning(textView: UITextView, characterIndex: Int, planning: String, point: CGPoint)
    func didTapOnPriority(textView: UITextView, characterIndex: Int, priority: String, point: CGPoint)
    func didTapOnAttachment(textView: UITextView, characterIndex: Int, type: String, value: String, point: CGPoint)
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
        self.tapGestureRecognizer.addTarget(self, action: #selector(tapped(gesture:)))
        self.tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(self.tapGestureRecognizer)
        self.alwaysBounceVertical = true
        self.autocapitalizationType = .none
        self.autocorrectionType = .no
        self.keyboardDismissMode = .interactive

        if #available(iOS 11.0, *) {
            self.smartDashesType = .no
        }
        
        self.tintColor = InterfaceTheme.Color.spotlight
        self.backgroundColor = InterfaceTheme.Color.background1
        self.typingAttributes = [NSAttributedString.Key.font: InterfaceTheme.Font.body,
                                 NSAttributedString.Key.foregroundColor: InterfaceTheme.Color.interactive]
    }
    
    private var lastTap: (CGPoint, Bool) = (.zero, true)
    
    @objc private func tapped(gesture: UITapGestureRecognizer) -> Bool {
        guard gesture.state == .ended else { return true }
        guard self.text.count > 0 else { return true }
        
        let location = gesture.view!.convert(gesture.location(in: self).applying(CGAffineTransform(translationX: 0,
                                                                                                   y: -self.textContainerInset.top)),
                                             to: self)
        
        guard location.x != lastTap.0.x else { return lastTap.1 }
        
        var fraction: CGFloat = 0
        let characterIndex = self.layoutManager.characterIndex(for: location,
                                                               in: self.textContainer,
                                                               fractionOfDistanceBetweenInsertionPoints: &fraction)
        
        guard fraction > 0 else { return true }
        
        if let outlineTextStorage = self.textStorage as? OutlineTextStorage {
            outlineTextStorage.updateCurrentInfo(at: characterIndex)
        }
        
        let attributes = self.textStorage.attributes(at: characterIndex, effectiveRange: nil)
        
        var shouldPassTapToOtherGuestureRecognizers = false
        if let hiddenValue = attributes[OutlineAttribute.tempShowAttachment] as? String {
            if hiddenValue == OutlineAttribute.Heading.folded.rawValue {
                self.outlineDelegate?.didTapOnHiddenAttachment(textView: self, characterIndex: characterIndex, point: location)
            }
        } else if let hiddenValue = attributes[OutlineAttribute.tempHidden] as? Int, hiddenValue == OutlineAttribute.hiddenValueFolded.intValue {
            // do nothing
        } else if let _ = attributes[OutlineAttribute.Heading.level] as? Int {
            self.outlineDelegate?.didTapOnLevel(textView: self, chracterIndex: characterIndex, point: location)
        } else if let checkbox = attributes[OutlineAttribute.checkbox] as? String {
            self.outlineDelegate?.didTapOnCheckbox(textView: self, characterIndex: characterIndex, checkbox: checkbox, point: location)
        } else if let linkStructure = attributes[OutlineAttribute.Link.title] as? [String: String] {
            self.resignFirstResponder()
            self.outlineDelegate?.didTapOnLink(textView: self, characterIndex: characterIndex, linkStructure: linkStructure, point: location)
        } else if let tags = attributes[OutlineAttribute.Heading.tags] as? [String] {
            self.resignFirstResponder()
            self.outlineDelegate?.didTapOnTags(textView: self, characterIndex: characterIndex, tags: tags, point: location)
        } else if let dateAndTimeString = attributes[OutlineAttribute.dateAndTime] as? String {
            self.resignFirstResponder()
            self.outlineDelegate?.didTapDateAndTime(textView: self, characterIndex: characterIndex, dateAndTimeString: dateAndTimeString, point: location)
        } else if let planning = attributes[OutlineAttribute.Heading.planning] as? String {
            self.resignFirstResponder()
            self.outlineDelegate?.didTapOnPlanning(textView: self, characterIndex: characterIndex, planning: planning, point: location)
        } else if let priority = attributes[OutlineAttribute.Heading.priority] as? String {
            self.resignFirstResponder()
            self.outlineDelegate?.didTapOnPriority(textView: self, characterIndex: characterIndex, priority: priority, point: location)
        }  else if let type = attributes[OutlineAttribute.Attachment.type] as? String,
            let value = attributes[OutlineAttribute.Attachment.value] as? String {
            self.resignFirstResponder()
            self.outlineDelegate?.didTapOnAttachment(textView: self, characterIndex: characterIndex, type: type, value: value, point: location)
        } else {
            shouldPassTapToOtherGuestureRecognizers = true
        }
        
        lastTap = (location, shouldPassTapToOtherGuestureRecognizers)
        
        return shouldPassTapToOtherGuestureRecognizers
    }
    
    // 调整光标的高度
    public override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        rect.size.height -= 10
        return rect
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
