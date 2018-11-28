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
        self.delegate = self
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OutlineLayoutManager: NSLayoutManagerDelegate {
    public func layoutManager(_ layoutManager: NSLayoutManager, shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>, properties props: UnsafePointer<NSLayoutManager.GlyphProperty>, characterIndexes charIndexes: UnsafePointer<Int>, font aFont: UIFont, forGlyphRange glyphRange: NSRange) -> Int {
        
        if hasMarkToHide(glyphs: glyphs) {
            layoutManager.setGlyphs(glyphs, properties: props,
                                    characterIndexes: charIndexes,
                                    font: aFont,
                                    forGlyphRange: glyphRange)
            
            return glyphRange.length
        }
        
        return 0
    }
    
    public func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
        
        return false
    }
}

private func hasMarkToHide(glyphs: UnsafePointer<CGGlyph>) -> Bool {
    // 隐藏文字中的标记，比如 ~~, **, 之类
    // 隐藏需要折叠的 heading 下的内容

    return false
}


