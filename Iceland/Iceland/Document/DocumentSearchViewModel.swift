//
//  DocumentSearchViewModel.swift
//  Iceland
//
//  Created by ian luo on 2018/12/2.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public struct DocumentSearchResult {
    public let url: URL
    public let highlightRange: NSRange
    public let context: String
    public let heading: OutlineTextStorage.Heading?
}

public protocol DocumentSearchDelegate: class {

}

public class DocumentSearchViewModel {
    public typealias Dependency = DocumentCoordinator
    public weak var delegate: DocumentSearchDelegate?
    public weak var dependency: Dependency?
    
    private let documentSearchManager: DocumentSearchManager
    
    public init(documentSearchManager: DocumentSearchManager) {
        self.documentSearchManager = documentSearchManager
    }
    
    // MARK: -
    /// 搜索包含指定字符串的文件，染回搜索结果
    /// - parameter contain: 搜索中包含的字符串
    /// - parameter resultAdded: 每个文件的搜索完成后会调用这个 closure
    /// - parameter result: 封装的搜索结果, 其中, url 为对应的文件 url，contex 为包含搜索结果的一个字符串，提供搜索结果的上下文, highlightRange 为 context 中搜索结果的 range, heading 为 nil
    /// - parameter complete: 所有文件搜索完成后调用
    /// - parameter failed: 有错误产生的时候调用
    public func search(contain: String,
                       resultAdded: @escaping (_ result: [DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: @escaping ((Error) -> Void)) {
        
        self.documentSearchManager.search(contain: contain, resultAdded: resultAdded, complete: complete, failed: failed)
    }
    
    // MARK: -
    /// 搜索包含指定 tag 的所有 heading
    /// - parameter tags, 字符串数组，需要搜索的所有 tag
    /// - parameter resultAdded: 每个文件的搜索完成后会调用这个 closure
    /// - parameter result: 封装的搜索结果, 其中, url 为对应的文件 url，context 为整个 heading，提供搜索结果的上下文, highlightRange 为 context 中搜索结果的 range, heading 为 整个 heading 对象
    /// - parameter complete: 所有文件搜索完成后调用
    /// - parameter failed: 有错误产生的时候调用
    public func search(tags: [String],
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: @escaping  ((Error) -> Void)) {
        
        self.documentSearchManager.search(tags: tags, resultAdded: resultAdded, complete: complete, failed: failed)
    }
    
    // MARK: -
    /// - parameter schedule: 搜索 schedule 整个日期之前的所有 heading
    /// - parameter resultAdded: 每个文件的搜索完成后会调用这个 closure
    /// - parameter result: 封装的搜索结果, 其中, url 为对应的文件 url，context 为整个 heading，提供搜索结果的上下文, highlightRange 为 context 中搜索结果的 range, heading 为 整个 heading 对象
    /// - parameter complete: 所有文件搜索完成后调用
    /// - parameter failed: 有错误产生的时候调用
    public func search(schedule: Date,
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: @escaping  ((Error) -> Void)) {
        
        self.documentSearchManager.search(schedule: schedule, resultAdded: resultAdded, complete: complete, failed: failed)
    }
    
    // MARK: -
    /// - parameter schedule: 搜索 due 整个日期之前的所有 heading
    /// - parameter resultAdded: 每个文件的搜索完成后会调用这个 closure
    /// - parameter result: 封装的搜索结果, 其中, url 为对应的文件 url，context 为整个 heading，提供搜索结果的上下文, highlightRange 为 context 中搜索结果的 range, heading 为 整个 heading 对象
    /// - parameter complete: 所有文件搜索完成后调用
    /// - parameter failed: 有错误产生的时候调用
    public func search(due: Date,
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: @escaping  ((Error) -> Void)) {

        self.documentSearchManager.search(due: due, resultAdded: resultAdded, complete: complete, failed: failed)
    }
    
    // MARK: -
    /// - parameter planning: 搜索包含这些 planning 的所有 heading
    /// - parameter resultAdded: 每个文件的搜索完成后会调用这个 closure
    /// - parameter result: 封装的搜索结果, 其中, url 为对应的文件 url，context 为整个 heading，提供搜索结果的上下文, highlightRange 为 context 中搜索结果的 range, heading 为 整个 heading 对象
    /// - parameter complete: 所有文件搜索完成后调用
    /// - parameter failed: 有错误产生的时候调用
    public func search(plannings: [String],
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: @escaping ((Error) -> Void)) {
        
        
        self.documentSearchManager.search(plannings: plannings, resultAdded: resultAdded, complete: complete, failed: failed)
    }
}
