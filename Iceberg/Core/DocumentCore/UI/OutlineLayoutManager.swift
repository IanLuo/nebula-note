//
//  OutlineLayoutManager.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit
import Interface

public class OutlineLayoutManager: NSLayoutManager {
    public override init() {
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func invalidateGlyphs(forCharacterRange charRange: NSRange, changeInLength delta: Int, actualCharacterRange actualCharRange: NSRangePointer?) {
        super.invalidateGlyphs(forCharacterRange: charRange, changeInLength: delta, actualCharacterRange: actualCharRange)
        
        log.info("invalidateGlyphs at: \(charRange), length: \(delta)")
    }
    
    public override func invalidateLayout(forCharacterRange charRange: NSRange, actualCharacterRange actualCharRange: NSRangePointer?) {
        super.invalidateLayout(forCharacterRange: charRange, actualCharacterRange: actualCharRange)
        
        log.info("invalidateLayout at: \(charRange)")
    }
    
    public override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        if let textStorage = self.textStorage {
            var acturaRange: NSRange = NSRange(location: 0, length: 0)
            _ = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: &acturaRange)
            var stop: Bool = false
            
            self._handleButton(textStorage: textStorage, range: glyphsToShow, origin: origin, shouldStop: &stop)

            self._handleForQuote(textStorage: textStorage, range: glyphsToShow, origin: origin, shouldStop: &stop)

            self._handleForCode(textStorage: textStorage, range: glyphsToShow, origin: origin, shouldStop: &stop)
            
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        } else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        }
    }
    
    private func _handleButton(textStorage: NSTextStorage, range: NSRange, origin: CGPoint, shouldStop: inout Bool) {
        textStorage.enumerateAttribute(OutlineAttribute.button, in: range, options: []) { (value, range, stop) in
            guard let value = value else {
                super.drawGlyphs(forGlyphRange: range, at: origin);return
            }
            
            guard let color = (value as? UIColor) else { return }
            let glRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil);
            
            self.enumerateEnclosingRects(forGlyphRange: glRange, withinSelectedGlyphRange: NSRange(location: 0, length: 0), in: self.textContainers[0], using: { (rect, stop) in
                
                guard let context = UIGraphicsGetCurrentContext() else { return }
                let font = InterfaceTheme.Font.footnote
                context.saveGState()
                context.translateBy(x: origin.x, y: origin.y)
                color.setFill()
                        
                var rect = rect
                rect.origin.x = rect.origin.x - 1
                rect.origin.y = rect.origin.y - font.descender - 1
                rect.size.height = font.lineHeight - font.descender
                rect.size.width = rect.size.width + 2

                let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
                path.fill()
                context.restoreGState()
            })
            
        }
    }
    
    private func _handleForQuote(textStorage: NSTextStorage, range: NSRange, origin: CGPoint, shouldStop: inout Bool) {
        textStorage.enumerateAttribute(OutlineAttribute.Block.quote, in: range, options: []) { (value, range, stop) in
            guard var color = (value as? UIColor) else { return }
            
            // workaround on mac the cursor can't see
            if isMac {
                color = color.withAlphaComponent(0.5)
            }
            let glRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil);
            
            guard let context = UIGraphicsGetCurrentContext() else { return }
            let font = InterfaceTheme.Font.footnote
            context.saveGState()
            context.translateBy(x: origin.x, y: origin.y)
            color.setFill()
            
            var rect = self.boundingRect(forGlyphRange: glRange, in: self.textContainers[0])
            rect.origin.y = rect.origin.y + font.descender
            
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
            path.fill()
            context.restoreGState()
            
            context.saveGState()
            context.translateBy(x: origin.x, y: origin.y)
            InterfaceTheme.Color.spotlight.setFill()
            let lineRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: 3, height: rect.height)
            let lineRectPath = UIBezierPath(roundedRect: lineRect, cornerRadius: 0)
            lineRectPath.fill()
            context.restoreGState()
        }
    }
    
    private func _handleForCode(textStorage: NSTextStorage, range: NSRange, origin: CGPoint, shouldStop: inout Bool) {
        textStorage.enumerateAttribute(OutlineAttribute.Block.code, in: range, options: []) { (value, range, stop) in
            guard let value = value else {
                super.drawGlyphs(forGlyphRange: range, at: origin);return
            }
            
            guard var color = (value as? UIColor) else { return }
            
            // workaround on mac the cursor can't see
            if isMac {
                color = color.withAlphaComponent(0.5)
            }
            
            let glRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil);
            
            guard let context = UIGraphicsGetCurrentContext() else { return }
            let font = InterfaceTheme.Font.footnote
            context.saveGState()
            context.translateBy(x: origin.x, y: origin.y)
            color.setFill()
            
            var rect = self.boundingRect(forGlyphRange: glRange, in: self.textContainers[0])
            rect.origin.y = rect.origin.y + font.descender
            
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
            path.fill()
            context.restoreGState()
            
        }
    }
}
