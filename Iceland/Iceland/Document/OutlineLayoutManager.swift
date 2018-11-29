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
        let controlCharProps: UnsafeMutablePointer<NSLayoutManager.GlyphProperty> = UnsafeMutablePointer(mutating: props)
        for i in 0..<glyphRange.length {
            let attributes = self.textStorage!.attributes(at: glyphRange.location + i, effectiveRange: nil)
        
            if attributes[OutlineTextStorage.OutlineAttribute.Heading.folded] != nil {
                controlCharProps[i] = .null
            } else if attributes[OutlineTextStorage.OutlineAttribute.link] != nil
                && attributes[OutlineTextStorage.OutlineAttribute.Link.title] == nil {
                controlCharProps[i] = .null
            } else if attributes[OutlineTextStorage.OutlineAttribute.Checkbox.status] != nil
                && attributes[OutlineTextStorage.OutlineAttribute.Checkbox.box] == nil {
                controlCharProps[i] = .null
            }
        }
        
        layoutManager.setGlyphs(glyphs,
                                properties: controlCharProps,
                                characterIndexes: charIndexes,
                                font: aFont,
                                forGlyphRange: glyphRange)
        
        return glyphRange.length
    }
}

private func hasMarkToHide(glyphs: UnsafePointer<CGGlyph>) -> Bool {
    // 隐藏文字中的标记，比如 ~~, **, 之类
    // 隐藏需要折叠的 heading 下的内容

    return false
}


