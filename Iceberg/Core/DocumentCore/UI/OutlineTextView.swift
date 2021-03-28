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
import RxSwift

public protocol OutlineTextViewDelegate: class {
    func didTapOnLevel(textView: UITextView, chracterIndex: Int, point: CGPoint)
    func didTapOnHiddenAttachment(textView: UITextView, characterIndex: Int, point: CGPoint)
    func didTapOnCheckbox(textView: UITextView, characterIndex: Int, checkbox: String, point: CGPoint)
    func didTapOnLink(textView: UITextView, characterIndex: Int, linkStructure: [String: Any], point: CGPoint)
    func didTapOnTags(textView: UITextView, characterIndex: Int, tags: [String], point: CGPoint)
    func didTapDateAndTime(textView: UITextView, characterIndex: Int, dateAndTimeString: String, point: CGPoint)
    func didTapOnPlanning(textView: UITextView, characterIndex: Int, planning: String, point: CGPoint)
    func didTapOnPriority(textView: UITextView, characterIndex: Int, priority: String, point: CGPoint)
    func didTapOnAttachment(textView: UITextView, characterIndex: Int, type: String, value: String, point: CGPoint)
    func didTapOnTitle(at: CGPoint)
}

public class OutlineTextView: UITextView {
    public weak var outlineDelegate: OutlineTextViewDelegate?
    
    private let disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = UILabel().font(UIFont.preferredFont(forTextStyle: .title1)).numberOfLines(0)
        
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.setup()
    }
    
    deinit {
        self.textStorage.removeLayoutManager(self.layoutManager)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.alwaysBounceVertical = true
        self.autocapitalizationType = .sentences
        self.autocorrectionType = .no
        self.keyboardDismissMode = .interactive

        if #available(iOS 11.0, *) {
            self.smartDashesType = .no
        }
        
        self.interface { (me, interface) in
            let textView = me as! OutlineTextView
            textView.tintColor = interface.color.spotlight
            textView.backgroundColor = interface.color.background1
            textView.typingAttributes = [NSAttributedString.Key.font: interface.font.body,
                                     NSAttributedString.Key.foregroundColor: interface.color.interactive]
            
            textView.titleLabel.textColor = interface.color.descriptive
            
            // work around for cursor coloring on mac
            if isMac {
                let textInputTraits = self.value(forKey: "textInputTraits") as? NSObject
                textInputTraits?.setValue(interface.color.spotlight, forKey: "insertionPointColor")
            }
        }
        
        self.addSubview(self.titleLabel)
        
        self.titleLabel.sideAnchor(for: [.left, .top], to: self, edgeInsets: UIEdgeInsets(top: 0, left: Layout.edgeInsets.left, bottom: 0, right: -Layout.edgeInsets.right))
        
        let tapOnNameGesture = UITapGestureRecognizer()
        tapOnNameGesture.rx.event.asDriver().drive(onNext: { event in
            switch event.state {
            case .ended:
                self.outlineDelegate?.didTapOnTitle(at: event.location(in: self))
            default: break
            }
        }).disposed(by: self.disposeBag)
        
        self.titleLabel.isUserInteractionEnabled = true
        self.titleLabel.addGestureRecognizer(tapOnNameGesture)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.updateCharacterborder(string: self.text)
        
        self.adjustEdgeInsetsForTitle()
    }
    
    public func updateCharacterborder(string: String) {
        if string.count == 0 {
            self.characterBorder = (.zero, .zero)
        } else {
            let begin = self.layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: 1), in: self.textContainer)
            let end = self.layoutManager.boundingRect(forGlyphRange: self.layoutManager.glyphRange(forCharacterRange: NSRange(location: self.text.count - 1, length: 1), actualCharacterRange: nil), in: self.textContainer)
            self.characterBorder = (begin, end)
        }
    }
    
    public func setTitle(_ text: String) {
        self.titleLabel.text = text
        
        self.adjustEdgeInsetsForTitle()
    }
    
    private func adjustEdgeInsetsForTitle() {
        let width = self.bounds.width - self.contentInset.left - self.contentInset.right
        let size = self.titleLabel.sizeThatFits(CGSize(width: width,
                                                       height: CGFloat.greatestFiniteMagnitude))
        let edgeContentSize = self.titleLabel.sizeThatFits(size)
        self.textContainerInset = UIEdgeInsets(top: edgeContentSize.height + 30, left: 0, bottom: 0, right: 0)
        
        var frame = self.titleLabel.frame
        frame.size = edgeContentSize
        self.titleLabel.frame = frame
    }
    
    private var lastTap: (CGPoint, Bool, Double) = (.zero, true, 0)
    
    private var characterBorder: (begin: CGRect, end: CGRect) = (.zero, .zero)
    
    private let isPointInBorder: (CGPoint, (begin: CGRect, end: CGRect)) -> Bool = { point, border in
        
        // same row, let side of first character
        if point.x < border.begin.origin.x && point.y < border.begin.origin.y + border.begin.size.height {
            return false
        }
        
        // above first row
        if point.y < border.begin.origin.y {
            return false
        }
        
//        // same row, right side of last character
//        if point.y > border.end.origin.y + border.end.size.height && point.x > border.end.origin.x {
//            return false
//        }
        
        // below last row
        if point.y > border.end.origin.y + border.end.size.height {
            return false
        }
        
        return true
    }
    
    @objc private func tapped(location: CGPoint, event: UIEvent?) -> Bool {
        guard let event = event, event.type == .touches else { return true }
        
        // handle multiple entrance
        guard location.x != lastTap.0.x || (CFAbsoluteTimeGetCurrent() - lastTap.2 > 0.5) else { return lastTap.1 }
        
        var fraction: CGFloat = 0
        let characterIndex = self.layoutManager.characterIndex(for: location,
                                                               in: self.textContainer,
                                                               fractionOfDistanceBetweenInsertionPoints: &fraction)
        
        
        // check if the character is with range of all characters
        guard isPointInBorder(location, self.characterBorder) else { return true }
        
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
        } else if let linkStructure = attributes[OutlineAttribute.Link.title] as? [String: Any] {
            self.hideKeyboardIfNeeded()
            self.outlineDelegate?.didTapOnLink(textView: self, characterIndex: characterIndex, linkStructure: linkStructure, point: location)
        } else if let tags = attributes[OutlineAttribute.Heading.tags] as? [String] {
            self.hideKeyboardIfNeeded()
            self.outlineDelegate?.didTapOnTags(textView: self, characterIndex: characterIndex, tags: tags, point: location)
        } else if let dateAndTimeString = attributes[OutlineAttribute.dateAndTime] as? String {
            self.hideKeyboardIfNeeded()
            self.outlineDelegate?.didTapDateAndTime(textView: self, characterIndex: characterIndex, dateAndTimeString: dateAndTimeString, point: location)
        } else if let planning = attributes[OutlineAttribute.Heading.planning] as? String {
            self.hideKeyboardIfNeeded()
            self.outlineDelegate?.didTapOnPlanning(textView: self, characterIndex: characterIndex, planning: planning, point: location)
        } else if let priority = attributes[OutlineAttribute.Heading.priority] as? String {
            self.hideKeyboardIfNeeded()
            self.outlineDelegate?.didTapOnPriority(textView: self, characterIndex: characterIndex, priority: priority, point: location)
        }  else if let type = attributes[OutlineAttribute.Attachment.type] as? String,
            let value = attributes[OutlineAttribute.Attachment.value] as? String {
            self.hideKeyboardIfNeeded()
            self.outlineDelegate?.didTapOnAttachment(textView: self, characterIndex: characterIndex, type: type, value: value, point: location)
        } else {
            shouldPassTapToOtherGuestureRecognizers = true
        }
        
        lastTap = (location, shouldPassTapToOtherGuestureRecognizers, CFAbsoluteTimeGetCurrent())
        
        return shouldPassTapToOtherGuestureRecognizers
    }
    
    private func hideKeyboardIfNeeded() {
        if isPhone {
            self.resignFirstResponder()
        }
    }
    
    // 调整光标的高度
    public override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        let height = self.font?.lineHeight ?? rect.size.height - 10
        rect.size.height = max(height, rect.size.height - 10)
        return rect
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let textLocation = CGPoint(x: point.x - self.textContainerInset.left,
                                   y: point.y - self.textContainerInset.top)
        
        if self.tapped(location: textLocation, event: event) {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
    
    public func flashLine(location: Int) {
        var effectiveRange: NSRange = NSRange(location: 0, length: 0)
        let rect = self.layoutManager.lineFragmentRect(forGlyphAt: location, effectiveRange: &effectiveRange)
        
        let view: UIView = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        view.alpha = 0
        view.frame = rect
        self.insertSubview(view, at: 0)
        
        UIView.animateKeyframes(withDuration: 1.3, delay: 0, options: []) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.4) {
                view.alpha = 1
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.6) {
                view.alpha = 0
            }
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
}

extension UITextView {
    // avoid crash
    #if targetEnvironment(macCatalyst)
    @objc(_focusRingType)
    var focusRingType: UInt {
        return 1 //NSFocusRingTypeNone
    }
    #endif
}


extension UITextView {
    
    /// 查找文本范围所在的矩形范围
    ///
    /// - Parameter range: 文本范围
    /// - Returns: 文本范围所在的矩形范围
    public func rect(forStringRange range: NSRange) -> CGRect? {
        var range = range
        if range.location == self.text.count {
            range = range.offset(-1)
        }
        
        guard let start = self.position(from: self.beginningOfDocument, offset: range.location) else { return nil }
        guard let end = self.position(from: start, offset: range.length) else { return nil }
        guard let textRange = self.textRange(from: start, to: end) else { return nil }
        let rect = self.firstRect(for: textRange)
        return self.convert(rect, from: self.textInputView)
    }
    
}
