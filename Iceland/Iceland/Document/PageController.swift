//
//  OutlineTextStorage.swift
//  Iceland
//
//  Created by ian luo on 2018/11/11.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import UIKit

public protocol OutlineMasterDelegate: class {
    func didUpdateHeadings(headings: [NSRange])
}

public class PageController: NSObject {
    
    let layoutManager: NSLayoutManager
    
    let textContainer: NSTextContainer
    
    let textStorage: OutlineTextStorage
    
    var parser: OutlineParser!
    
    public convenience init(parser: OutlineParser) {
        self.init()
        self.parser = parser
        self.parser.delegate = self.textStorage
    }
    
    public override init() {
        self.textStorage = OutlineTextStorage()
        self.textContainer = NSTextContainer(size: UIScreen.main.bounds.size)
        self.layoutManager = OutlineLayoutManager()
        layoutManager.allowsNonContiguousLayout = true
        layoutManager.addTextContainer(textContainer)
        super.init()
        self.textStorage.delegate = self
        self.textStorage.addLayoutManager(layoutManager)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PageController: NSTextStorageDelegate {
    public func textStorage(_ textStorage: NSTextStorage, willProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        
        // 清空 attributes
        var i: OutlineTextStorage.Item? = self.textStorage.item(after: editedRange.location)
        repeat {
            if let range = i?.actualRange {
                textStorage.attributes(at: range.location, longestEffectiveRange: nil, in: range).forEach {
                    textStorage.removeAttribute($0.key, range: range)
                }
            }
            
            i = i?.next
        } while i != nil
    }
    
    /// 添加文字属性
    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        // heading
        // 根据文字 mark 添加不同的显示样式
        // 解析字符串内容
        // 找到 heading，将 heading 下的内容进行分组
        
        /// 当前交互的位置
        self.textStorage.currentLocation = editedRange.location
        
        // 扩大需要解析的字符串范围
        self.textStorage.currentParseRange = editedRange.expand(string: textStorage.string)
        
        // 更新 item 索引缓存
        self.textStorage.updateItemIndexAndRange(delta: delta)

        parser.parse(str: textStorage.string,
                     range: self.textStorage.currentParseRange!)
        
        // 更新当前状态缓存
        self.textStorage.updateCurrentInfo()
    }
}

extension NSRange {
    /// 将在字符串中的选择区域扩展到前一个换行符之后，后一个换行符之前
    internal func expand(string: String) -> NSRange {
        var extendedRange = self
        // 向上, 到上一个 '\n' 之后
        while extendedRange.location > 0 &&
            extendedRange.upperBound < string.count - 1 &&
            (string as NSString)
                .substring(with: NSRange(location: extendedRange.location - 1, length: 1)) != "\n" {
                    extendedRange = NSRange(location: extendedRange.location - 1, length: extendedRange.length + 1)
        }
        
        // 向下，下一个 '\n' 之前
        while extendedRange.upperBound < string.count - 1 &&
            (string as NSString)
                .substring(with: NSRange(location: extendedRange.upperBound, length: 1)) != "\n" {
                    extendedRange = NSRange(location: extendedRange.location, length: extendedRange.length + 1)
        }
        
        return extendedRange
    }
}
