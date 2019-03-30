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
            textStorage.enumerateAttribute(OutlineAttribute.button, in: glyphsToShow, options: []) { (value, range, stop) in
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
                    rect.origin.y = rect.origin.y - font.descender
                    rect.size.height = font.lineHeight - font.descender
                    
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
                    path.fill()
                    context.restoreGState()
                })

                super.drawGlyphs(forGlyphRange: range, at: origin)
            }
        } else {
            super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        }
        
    }
}
