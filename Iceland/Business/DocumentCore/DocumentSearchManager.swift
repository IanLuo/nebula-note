//
//  DocumentSearchManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

public struct DocumentSearchResult {
    public let url: URL
    public let highlightRange: NSRange
    public let context: String
    public let heading: Heading?
    public let documentInfo: DocumentInfo
    
    public init(url: URL, highlightRange: NSRange, context: String, heading: Heading?) {
        self.url = url
        self.highlightRange = highlightRange
        self.context = context
        self.heading = heading
        
        self.documentInfo = DocumentInfo(wrapperURL: url)
    }
}

public class DocumentSearchManager {
    private let headingSearchOperationQueue: OperationQueue
    private let contentSearchOperationQueue: OperationQueue
    
    public init() {
        self.headingSearchOperationQueue = OperationQueue()
        self.contentSearchOperationQueue = OperationQueue()
        
        self.headingSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
        self.contentSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
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
                       failed: ((Error) -> Void)?) {
        
        self.contentSearchOperationQueue.cancelAllOperations()
        let operation = BlockOperation()
        
        operation.completionBlock = {
            OperationQueue.main.addOperation {
                complete()
            }
        }
        
        operation.addExecutionBlock {
            do {
                let matcher = try NSRegularExpression(pattern: "\(contain)", options: NSRegularExpression.Options.caseInsensitive)
                try self.loadAllFiles().forEach { url in
                    let string = try String(contentsOf: url)
                    var item: [DocumentSearchResult] = []
                    matcher.enumerateMatches(in: string,
                                             options: NSRegularExpression.MatchingOptions.reportProgress,
                                             range: NSRange(location: 0, length: string.count),
                                             using: { (result: NSTextCheckingResult?,
                                                flags: NSRegularExpression.MatchingFlags,
                                                stop: UnsafeMutablePointer<ObjCBool>) in
                                                
                                                guard let range = result?.range else { return }
                                                
                                                let lowerBound = max(0, range.location - 10)
                                                let upperBound = min(range.upperBound + 30, string.count - 1)
                                                let contextRange = NSRange(location: lowerBound, length: upperBound - lowerBound)
                                                let highlightRange = NSRange(location: range.location - lowerBound, length: range.length)
                                                
                                                item.append(DocumentSearchResult(url: url.wrapperURL,
                                                                                 highlightRange: highlightRange,
                                                                                 context: (string as NSString).substring(with: contextRange),
                                                                                 heading: nil))
                    })
                    
                    OperationQueue.main.addOperation {
                        resultAdded(item)
                    }
                }
            } catch {
                log.error(error)
                
                OperationQueue.main.addOperation {
                    failed?(error)
                }
            }
        }
        
        self.contentSearchOperationQueue.addOperation(operation)
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
                       failed: ((Error) -> Void)?) {
        
        self.doSearchHeading(resultAdded: resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [Heading]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let tagsRange = heading.tags {
                                        let tagString = string.substring(tagsRange)
                                        for t in tags {
                                            let range = (tagString as NSString).range(of: t)
                                            if range.location != Int.max {
                                                searchResults.append(DocumentSearchResult(url: url.wrapperURL,
                                                                                          highlightRange: range.offset(-heading.range.location),
                                                                                          context: string.substring(heading.paragraphRange),
                                                                                          heading: heading))
                                            }
                                        }
                                    }
                                }
                                
                                return searchResults
        }
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
                       failed: ((Error) -> Void)?) {
        
        self.doSearchHeading(resultAdded: resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [Heading]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let scheduleRange = heading.schedule {
                                        let headingString = string.substring(heading.range)
                                        if let scheduleDate = DateAndTimeType.createFromSchedule(headingString)?.date {
                                            if scheduleDate <= schedule {
                                                searchResults.append(DocumentSearchResult(url: url.wrapperURL,
                                                                                          highlightRange: scheduleRange,
                                                                                          context: string.substring(heading.paragraphRange),
                                                                                          heading: heading))
                                            }
                                        }
                                    }
                                }
                                
                                return searchResults
        }
        
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
                       failed: ((Error) -> Void)?) {
        
        self.doSearchHeading(resultAdded:resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [Heading]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let dueRange = heading.due {
                                        let headingString = (string as NSString).substring(with: heading.range)
                                        
                                        if let dueDate = DateAndTimeType.createFromDue(headingString)?.date {
                                            if dueDate <= due {
                                                searchResults.append(DocumentSearchResult(url: url.wrapperURL,
                                                                                          highlightRange: dueRange,
                                                                                          context: string.substring(heading.paragraphRange),
                                                                                          heading: heading))
                                            }
                                        }
                                    }
                                }
                                
                                return searchResults
        }
        
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
                       failed: ((Error) -> Void)?) {
        
        self.doSearchHeading(resultAdded:resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [Heading]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let planningRange = heading.planning {
                                        let planningString = string.substring(planningRange)
                                        
                                        if plannings.contains(planningString) {
                                            searchResults.append(DocumentSearchResult(url: url.wrapperURL,
                                                                                      highlightRange: planningRange,
                                                                                      context: string.substring(heading.paragraphRange),
                                                                                      heading: heading))
                                        }
                                    }
                                }
                                
                                return searchResults
        }
    }
    
    public func headingHasPlanning(contained in: [String], text: String, heading: [String: NSRange]) -> Bool {
        if let planningRange = heading[OutlineParser.Key.Element.Heading.planning] {
            return `in`.contains(text.substring(planningRange))
        } else {
            return false
        }
    }
    
    /// 搜索所有的 heading
    private func doSearchHeading(resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                                 complete: @escaping () -> Void,
                                 failed: ((Error) -> Void)?,
                                 onEachHeadingMatch: @escaping (String, URL, [Heading]) -> [DocumentSearchResult]) {
        
        let operation = BlockOperation()
        
        operation.completionBlock = {
            OperationQueue.main.addOperation {
                complete()
            }
        }
        
        operation.addExecutionBlock {
            
            class ParseDelegate: OutlineParserDelegate {
                var headings: [Heading] = []
                func didFoundHeadings(text: String,
                                      headingDataRanges: [[String: NSRange]]) {
                    
                    self.headings = headingDataRanges.map { Heading(data: $0) }
                }
                
                func didCompleteParsing(text: String) {
                    var lastUpperBound = text.count
                    headings.reversed().forEach {
                        $0.contentLength = lastUpperBound - $0.range.upperBound
                        lastUpperBound = $0.range.location
                    }
                }
            }
            
            let parseDelegate = ParseDelegate()
            let parser = OutlineParser()
            parser.delegate = parseDelegate
            parser.includeParsee = .heading
            
            do {
                try self.loadAllFiles().forEach { url in
                    let string = try String(contentsOf: url)
                    parser.parse(str: string)
                    
                    if parseDelegate.headings.count > 0 {
                        let documentSearchResult = onEachHeadingMatch(string, url, parseDelegate.headings)
                        if documentSearchResult.count > 0 {
                            OperationQueue.main.addOperation {
                                resultAdded(documentSearchResult)
                            }
                        }
                        
                        parseDelegate.headings = []
                    }
                }
            } catch {
                OperationQueue.main.addOperation {
                    failed?(error)
                }
            }
        }
        
        headingSearchOperationQueue.addOperation(operation)
    }
    
    public func loadAllHeadingsThatIsUnfinished(complete: @escaping (([DocumentSearchResult]) -> Void),
                                                failure: @escaping (Error) -> Void) {
        var searchResults: [DocumentSearchResult] = []
        self.doSearchHeading(resultAdded: { result in
            searchResults.append(contentsOf: result)
        }, complete: {
            complete(searchResults)
        }, failed: { error in
            failure(error)
        }) { (text, url, headings) -> [DocumentSearchResult] in
            var resultsInThisFile: [DocumentSearchResult] = []
            for heading in headings {
                var shouldAppendThis = false
                if self.headingHasPlanning(contained: SettingsAccessor.shared.finishedPlanning,
                                           text: text,
                                           heading: heading.data) {
                    shouldAppendThis = false
                } else {
                    if self.headingHasPlanning(contained: SettingsAccessor.shared.unfinishedPlanning,
                                               text: text,
                                               heading: heading.data) {
                        shouldAppendThis = true
                    } else if heading.schedule != nil &&
                        heading.closed == nil {
                        shouldAppendThis = true
                    } else if heading.due != nil &&
                        heading.closed == nil  {
                        shouldAppendThis = true
                    }
                }
                
                if shouldAppendThis {
                    resultsInThisFile.append(DocumentSearchResult(url: url.wrapperURL,
                                                                  highlightRange: heading.range,
                                                                  context: text.substring(heading.paragraphRange),
                                                                  heading: heading))
                }
            }
            
            return resultsInThisFile
        }
    }
    
    public func loadAllTags(_ completion: @escaping ([DocumentSearchResult]) -> Void) {
        var allTagsSearchResult: [DocumentSearchResult] = []
        self.doSearchHeading(resultAdded: { searchResults in
            allTagsSearchResult.append(contentsOf: searchResults)
        }, complete: {
            completion(allTagsSearchResult)
        }, failed: { error in
            log.error(error)
        }) { (text, url, headings) -> [DocumentSearchResult] in
            var resultsInSingleFile: [DocumentSearchResult] = []
            for heading in headings {
                if let tagsRange = heading.tags {
                    let tags = text.substring(tagsRange).components(separatedBy: ":").filter { $0.count > 0 }
                    for tag in tags {
                        resultsInSingleFile.append(DocumentSearchResult(url: url.wrapperURL, highlightRange: tagsRange, context: tag, heading: nil))
                    }
                }
            }
            
            return resultsInSingleFile
        }
    }
    
    public func loadAllFiles() -> [URL] {
        var result: [URL] = []
        guard let enumerator = FileManager.default.enumerator(at: URL.documentBaseURL,
                                                              includingPropertiesForKeys: nil,
                                                              options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles,
                                                              errorHandler: nil) else { return result}
        
        for file in enumerator {
            if let url = file as? URL, url.pathExtension == Document.contentFileExtension {
                result.append(url)
            }
        }
        
        return result
    }
}
