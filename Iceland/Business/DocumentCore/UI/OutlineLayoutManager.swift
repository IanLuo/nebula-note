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
}


