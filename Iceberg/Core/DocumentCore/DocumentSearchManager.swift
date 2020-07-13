//
//  DocumentSearchManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation
import RxSwift

public struct DocumentHeading {
    public let level: Int
    public let priority: String?
    public let tags: [String]?
    public let planning: String?
    public let text: String
    public let paragraphSummery: String
    public let length: Int
    public let url: URL
    public let location: Int
    public let range: NSRange
    public let paragraphRange: NSRange
    public let paragraphWithSubRange: NSRange
    public var upperBoundWithoutLineBreak: Int
    
    public init(documentString: String, headingToken: HeadingToken, url: URL) {
        self.range = headingToken.range
        self.paragraphRange = headingToken.paragraphRange
        self.url = url
        self.level = headingToken.level
        self.length = headingToken.paragraphRange.length
        self.location = headingToken.range.location
        self.paragraphWithSubRange = headingToken.paragraphWithSubRange
        self.upperBoundWithoutLineBreak = headingToken.upperBoundWithoutLineBreak
        
        if let tagRange = headingToken.tags {
            self.tags = documentString.nsstring.substring(with: tagRange).components(separatedBy: ":").filter { $0.count != 0 }
        } else {
            self.tags = nil
        }
        
        if let planning = headingToken.planning {
            self.planning = documentString.nsstring.substring(with: planning)
        } else {
            self.planning = nil
        }
        
        if let priority = headingToken.priority {
            self.priority = documentString.nsstring.substring(with: priority)
        } else {
            self.priority = nil
        }
        
        self.text = documentString.nsstring.substring(with: headingToken.headingTextRange)
        
        if let contentRange = headingToken.contentRange {
            self.paragraphSummery = documentString.nsstring.substring(with: NSRange(location: contentRange.location,
                                                                                    length: min(100, contentRange.length)))
        } else {
            self.paragraphSummery = ""
        }
    }
}

public struct DocumentTextSearchResult {
    public let documentInfo: DocumentInfo
    public let highlightRange: NSRange
    public let context: String
    public let heading: DocumentHeading?
    public let location: Int
}

public class DocumentHeadingSearchResult {
    public init(dateAndTime: DateAndTimeType?, documentInfo: DocumentInfo, dateAndTimeRange: NSRange?, heading: DocumentHeading, parent: DocumentHeadingSearchResult? = nil) {
        self.dateAndTime = dateAndTime
        self.documentInfo = documentInfo
        self.dateAndTimeRange = dateAndTimeRange
        self.heading = heading
        self.parent = parent
    }
    
    public let dateAndTime: DateAndTimeType?
    public let documentInfo: DocumentInfo
    public let dateAndTimeRange: NSRange?
    public let heading: DocumentHeading
    public weak var parent: DocumentHeadingSearchResult?
    public var children: [DocumentHeadingSearchResult] = []
    
    public func getWholdTree() -> [DocumentHeadingSearchResult] {
        var allResults: [DocumentHeadingSearchResult] = []
        
        for r in self.children {
            allResults.append(contentsOf: r.getWholdTree())
        }
        
        allResults.insert(self, at: 0)
        
        return allResults
    }
}

public class TagAddedEvent: Event {
    public let tag: String
    public init(tag: String) {
        self.tag = tag
    }
}

public class TagDeleteEvent: Event {
    public let tag: String
    public init(tag: String) {
        self.tag = tag
    }
}

public class DocumentSearchManager {
    private let _headingSearchOperationQueue: OperationQueue
    private let _contentSearchOperationQueue: OperationQueue
    private let _headingChangeObservingQueue: OperationQueue
    private let _trashSearchOperationQueue: OperationQueue
    private let _documentSearchOperationQueue: OperationQueue
    
    public init() {
        self._headingSearchOperationQueue = OperationQueue()
        self._contentSearchOperationQueue = OperationQueue()
        self._headingChangeObservingQueue = OperationQueue()
        self._trashSearchOperationQueue = OperationQueue()
        self._documentSearchOperationQueue = OperationQueue()
        
        self._headingSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
        self._contentSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
        self._headingChangeObservingQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        self._trashSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        self._documentSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
    }
    
    public func searchAttachment(string: String, completion: @escaping ([[String: NSRange]]) -> Void) {
        self._documentSearchOperationQueue.addOperation {
            let parseDelegate = ParseDelegate()
            let parser = OutlineParser()
            parser.delegate = parseDelegate
            parser.includeParsee = [.attachment]
            
            parser.parse(str: string)
            completion(parseDelegate.attachments)
        }
    }
    
    // MARK: - deleted -
    public func searchTrash(completion: @escaping ([URL]) -> Void) {
        
        var result: [URL] = []
        
        let operation = BlockOperation {
            guard let enumerator = FileManager.default.enumerator(at: URL.documentBaseURL,
                                                                  includingPropertiesForKeys: nil,
                                                                  options: [],
                                                                  errorHandler: nil) else { return }
            
            for file in enumerator {
                if let url = file as? URL, url.pathExtension == Document.fileExtension,
                    url.packageName.hasPrefix(SyncCoordinator.Prefix.deleted.rawValue) {
                    result.append(url)
                }
            }
        }
        
        operation.completionBlock = {
            completion(result)
        }
        
        self._trashSearchOperationQueue.addOperation(operation)
    }
    
    // MARK: -
    /// 搜索包含指定字符串的文件，染回搜索结果
    /// - parameter contain: 搜索中包含的字符串
    /// - parameter resultAdded: 每个文件的搜索完成后会调用这个 closure
    /// - parameter result: 封装的搜索结果, 其中, url 为对应的文件 url，contex 为包含搜索结果的一个字符串，提供搜索结果的上下文, highlightRange 为 context 中搜索结果的 range, heading 为 nil
    /// - parameter complete: 所有文件搜索完成后调用
    /// - parameter failed: 有错误产生的时候调用
    public func search(contain: String,
                       cancelOthers: Bool = true,
                       completion: @escaping ([DocumentTextSearchResult]) -> Void,
                       failed: ((Error) -> Void)?) {
        
        guard contain.count > 0 else {  return }
        
        if cancelOthers {
            self._contentSearchOperationQueue.cancelAllOperations()
        }
        let operation = BlockOperation()
        
        operation.addExecutionBlock {
            do {
                let parseDelegate = ParseDelegate()
                let parser = OutlineParser()
                parser.delegate = parseDelegate
                parser.includeParsee = [.heading]
                
                var items: [DocumentTextSearchResult] = []
                let matcher = try NSRegularExpression(pattern: "\(contain)", options: NSRegularExpression.Options.caseInsensitive)
                
                URL.read(urls: self.loadAllFiles()) { url, string in
                    // 0. match file name
                    let range = (url.packageName as NSString).range(of: contain, options: [.caseInsensitive])
                    if range.length > 0 {
                        items.append(DocumentTextSearchResult(documentInfo: DocumentInfo(wrapperURL: url.wrapperURL),
                        highlightRange: range,
                        context: url.packageName,
                        heading: nil,
                        location: 0))
                    }
                    
                    // 1. 先获取所有文档的 heading
                    parser.parse(str: string)
                    
                    matcher.enumerateMatches(in: string,
                                             options: NSRegularExpression.MatchingOptions.reportProgress,
                                             range: NSRange(location: 0, length: string.nsstring.length),
                                             using: { (result: NSTextCheckingResult?,
                                                flags: NSRegularExpression.MatchingFlags,
                                                stop: UnsafeMutablePointer<ObjCBool>) in
                                                
                                                guard let range = result?.range else { return }
                                                
                                                let lowerBound = max(0, range.location - 10)
                                                let upperBound = min(range.upperBound + 30, string.nsstring.length)
                                                let contextRange = NSRange(location: lowerBound, length: upperBound - lowerBound)
                                                let highlightRange = NSRange(location: range.location - lowerBound, length: range.length)
                                                
                                                let documentHeading = parseDelegate.heading(contains: range.location).map {
                                                    return DocumentHeading(documentString: string,
                                                                           headingToken: $0,
                                                                           url: url)
                                                }
                                                
                                                items.append(DocumentTextSearchResult(documentInfo: DocumentInfo(wrapperURL: url.wrapperURL),
                                                                                      highlightRange: highlightRange,
                                                                                      context: string.nsstring.substring(with: contextRange),
                                                                                      heading: documentHeading,
                                                                                      location: range.location))
                    })
                }
                
                OperationQueue.main.addOperation {
                    completion(items)
                }
            } catch {
                log.error(error)
                
                OperationQueue.main.addOperation {
                    failed?(error)
                }
            }
        }
        
        self._contentSearchOperationQueue.addOperation(operation)
    }
    
    /// 只有写在 heading 中的 datetime 才会被列入结果
    public func searchDateAndTime(completion: @escaping ([DocumentHeadingSearchResult]) -> Void,
                                  failure: @escaping (Error) -> Void) {
        let operation = BlockOperation()
        
        operation.addExecutionBlock {
            
            // 解析文件中的全部 heading
            let parseDelegate = ParseDelegate()
            let parser = OutlineParser()
            parser.delegate = parseDelegate
            parser.includeParsee = [.heading, .dateAndTime]
            
            var results: [DocumentHeadingSearchResult] = []
            
            URL.read(urls: self.loadAllFiles()) { url, string in
                parser.parse(str: string)
                
                var resultsInFile: [DocumentHeadingSearchResult] = []
                parseDelegate.dateAndTimes.forEach { dateAndTimeRange in
                    
                    if let headingToken = parseDelegate.heading(contains: dateAndTimeRange.location) {
                        let result = DocumentHeadingSearchResult(dateAndTime: DateAndTimeType(string.nsstring.substring(with: dateAndTimeRange))!,
                                                                 documentInfo: DocumentInfo(wrapperURL: url.wrapperURL),
                                                                 dateAndTimeRange: dateAndTimeRange,
                                                                 heading: DocumentHeading(documentString: string,
                                                                                          headingToken: headingToken,
                                                                                          url: url))
                        
                        resultsInFile.append(result)
                        
                    }
                }
                
                results.append(contentsOf: resultsInFile)
            }
            
            completion(results)
            
        }
        
        self._headingSearchOperationQueue.addOperation(operation)
    }
    
    public func searchPlanning(_ planningToSearch: String, completion: @escaping ([DocumentHeadingSearchResult]) -> Void, failure: @escaping (Error) -> Void) {
        
        self.allHeadings(completion: { headingResults in
            let results = headingResults.filter { heading in
                if let planning = heading.heading.planning, planning == planningToSearch {
                    return true
                } else {
                    return false
                }
            }
            
            completion(results)
        }) { error in
            failure(error)
        }
    }
    
    public func searchTag(_ tagToSearch: String, completion: @escaping ([DocumentHeadingSearchResult]) -> Void, failure: @escaping (Error) -> Void) {
        self.allHeadings(completion: { headingResults in
            let results = headingResults.filter { heading in
                if let tags = heading.heading.tags, tags.contains(tagToSearch) {
                    return true
                } else {
                    return false
                }
            }
            
            completion(results)
        }) { error in
            failure(error)
        }
    }
    
    public func searchWithoutTag(completion: @escaping ([DocumentHeadingSearchResult]) -> Void, failure: @escaping (Error) -> Void) {
        self.allHeadings(completion: { heading in
            let results = heading.filter({ headingResult in
                headingResult.heading.tags == nil
            })
            
            completion(results)
        }) { error in
            failure(error)
        }
    }
    
    public func allHeadings(completion: @escaping ([DocumentHeadingSearchResult]) -> Void, failure: @escaping (Error) -> Void) {
        let operation = BlockOperation()
        
        operation.addExecutionBlock {
            
            // 解析文件中的全部 heading
            let parseDelegate = ParseDelegate()
            let parser = OutlineParser()
            parser.delegate = parseDelegate
            parser.includeParsee = .heading
            
            var headings: [DocumentHeadingSearchResult] = []
            do {
                
                func figureOutParentChildRelation(headingStack: inout [DocumentHeadingSearchResult], new result: DocumentHeadingSearchResult) {
                    if let last = headingStack.last {
                        if last.heading.level < result.heading.level {
                            result.parent = last
                            last.children.append(result)
                        } else {
                            headingStack.removeLast() // has run out of children
                            figureOutParentChildRelation(headingStack: &headingStack, new: result)
                        }
                    }
                }
                
                URL.read(urls: self.loadAllFiles(), each: { url, string in
                    
                    parser.parse(str: string)
                    
                    var headingStack: [DocumentHeadingSearchResult] = []
                    headings.append(contentsOf: parseDelegate.headings.map { headingToken in
                        
                        let result = DocumentHeadingSearchResult(dateAndTime: nil,
                                                                 documentInfo: DocumentInfo(wrapperURL: url.wrapperURL),
                                                                 dateAndTimeRange: nil,
                                                                 heading: DocumentHeading(documentString: string,
                                                                                          headingToken: headingToken,
                                                                                          url: url))
                        
                        // make the result parent/child relationship
                        figureOutParentChildRelation(headingStack: &headingStack, new: result)
                        
                        headingStack.append(result)
                        
                        return result
                    })
                })
                
                completion(headings)
            }
            
        }
        
        self._headingSearchOperationQueue.addOperation(operation)
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


class ParseDelegate: OutlineParserDelegate {
    var headings: [HeadingToken] = []
    var dateAndTimes: [NSRange] = []
    var attachments: [[String: NSRange]] = []
    
    func didStartParsing(text: String) {
        // clear earlier found data
        self.headings = []
        self.dateAndTimes = []
        self.attachments = []
    }
    
    func didFoundHeadings(text: String,
                          headingDataRanges: [[String: NSRange]]) {
        
        self.headings = headingDataRanges.map { HeadingToken(data: $0) }
    }
    
    func didFoundDateAndTime(text: String, rangesData: [[String:NSRange]]) {
        self.dateAndTimes = rangesData.map { $0.values.first! }
    }
    
    func didFoundAttachment(text: String, attachmentRanges: [[String : NSRange]]) {
        self.attachments = attachmentRanges
    }
    
    // O(n) FIXME: 用二分查找提高效率
    public func heading(contains location: Int) -> HeadingToken? {
        for heading in self.headings.reversed() {
            if location >= heading.range.location {
                return heading
            }
        }
        
        return nil
    }
}
