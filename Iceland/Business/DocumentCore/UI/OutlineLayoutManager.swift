//
//  OutlineLayoutManager.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

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
            textStorage.enumerateAttribute(OutlineAttribute.button, in: acturaRange, options: []) { (value, range, stop) in
                guard let value = value else {
                    super.drawGlyphs(forGlyphRange: range, at: origin);return
                }
                
                guard let color = (value as? UIColor) else { return }
                let glRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil);
                //UInt here is because otherwise playground does not want to execute, although compiler
                //is actually letting me know that this is wrong. However, this makes the playground work
                //if it doesn't work for you, try removing UInt wrapping here.
                guard let tContainer = textContainer(forGlyphAt: Int(glRange.location),
                                                     effectiveRange: nil) else { return }
                //draw background rectangle
                guard let context = UIGraphicsGetCurrentContext() else { return }
                let font = InterfaceTheme.Font.body
                context.saveGState()
                context.translateBy(x: origin.x, y: origin.y)
                color.setFill()
                var rect = boundingRect(forGlyphRange: glRange, in: tContainer)
                rect.origin.x = rect.origin.x - 5
                if(rect.origin.y == 0) {
                    rect.origin.y = rect.origin.y - 1
                } else {
                    rect.origin.y = rect.origin.y - 2
                }
                rect.size.width = rect.size.width + 10
                rect.size.height = font.lineHeight + 4
                
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
                path.fill()
                context.restoreGState()
                super.drawGlyphs(forGlyphRange: range, at: origin)
            }
        } else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        }
        
    }
}
