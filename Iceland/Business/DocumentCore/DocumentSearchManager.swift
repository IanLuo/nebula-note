//
//  DocumentSearchManager.swift
//  Iceland
//
//  Created by ian luo on 2018/12/25.
//  Copyright © 2018 wod. All rights reserved.
//

import Foundation

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
    
    public init(documentString: String, headingToken: HeadingToken, url: URL) {
        self.url = url
        self.level = headingToken.level
        self.length = headingToken.paragraphRange.length
        self.location = headingToken.range.location
        
        if let tagRange = headingToken.tags {
            self.tags = documentString.substring(tagRange).components(separatedBy: ":").filter { $0.count != 0 }
        } else {
            self.tags = nil
        }
        
        if let planning = headingToken.planning {
            self.planning = documentString.substring(planning)
        } else {
            self.planning = nil
        }
        
        if let priority = headingToken.priority {
            self.priority = documentString.substring(priority)
        } else {
            self.priority = nil
        }
        
        self.text = documentString.substring(headingToken.range)
        
        self.paragraphSummery = documentString.substring(NSRange(location: headingToken.contentRange.location,
                                                                 length: min(100, headingToken.contentRange.length)))
    }
}

public struct DocumentTextSearchResult {
    public let documentInfo: DocumentInfo
    public let highlightRange: NSRange
    public let context: String
    public let heading: DocumentHeading?
}

public struct DocumentHeadingSearchResult {
    public let dateAndTime: DateAndTimeType?
    public let documentInfo: DocumentInfo
    public let dateAndTimeRange: NSRange?
    public let tags: [String]?
    public let planning: String?
    public let headingString: String
    public let heading: DocumentHeading
}

public class DocumentSearchHeadingUpdateEvent: Event {
    public let oldHeadings: [DocumentHeadingSearchResult]
    public let newHeadings: [DocumentHeadingSearchResult]
    public init(oldHeadings: [DocumentHeadingSearchResult], newHeadings: [DocumentHeadingSearchResult]) {
        self.oldHeadings = oldHeadings
        self.newHeadings = newHeadings
    }
}

public class DocumentSearchManager {
    private let _headingSearchOperationQueue: OperationQueue
    private let _contentSearchOperationQueue: OperationQueue
    private let _headingChangeObservingQueue: OperationQueue
    
    private let _eventObserver: EventObserver
    private let _editorContext: EditorContext
    
    public init(eventObserver: EventObserver, editorContext: EditorContext) {
        self._headingSearchOperationQueue = OperationQueue()
        self._contentSearchOperationQueue = OperationQueue()
        self._headingChangeObservingQueue = OperationQueue()
        
        self._headingSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
        self._contentSearchOperationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
        self._headingChangeObservingQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        
        self._editorContext = editorContext
        self._eventObserver = eventObserver
        self._eventObserver.registerForEvent(on: self,
                                            eventType: DocumentHeadingChangeEvent.self,
                                            queue: self._headingChangeObservingQueue,
                                            action: { [weak self] (event: DocumentHeadingChangeEvent) -> Void in
                                                self?._handleDocumentHeadingsChange(event: event)
        })
    }
    
    // MARK: -
    /// 搜索包含指定字符串的文件，染回搜索结果
    /// - parameter contain: 搜索中包含的字符串
    /// - parameter resultAdded: 每个文件的搜索完成后会调用这个 closure
    /// - parameter result: 封装的搜索结果, 其中, url 为对应的文件 url，contex 为包含搜索结果的一个字符串，提供搜索结果的上下文, highlightRange 为 context 中搜索结果的 range, heading 为 nil
    /// - parameter complete: 所有文件搜索完成后调用
    /// - parameter failed: 有错误产生的时候调用
    public func search(contain: String,
                       completion: @escaping ([DocumentTextSearchResult]) -> Void,
                       failed: ((Error) -> Void)?) {

        guard contain.count > 0 else { return }
        
        self._contentSearchOperationQueue.cancelAllOperations()
        let operation = BlockOperation()
        
        operation.addExecutionBlock {
            do {
                let parseDelegate = ParseDelegate()
                let parser = OutlineParser()
                parser.delegate = parseDelegate
                parser.includeParsee = [.heading]
                
                
                var items: [DocumentTextSearchResult] = []
                let matcher = try NSRegularExpression(pattern: "\(contain)", options: NSRegularExpression.Options.caseInsensitive)
                try self.loadAllFiles().forEach { url in
                    
                    // 1. 先获取所有文档的 heading
                    let string = try String(contentsOf: url)
                    parser.parse(str: string)
                    
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
                                                
                                                let documentHeading = parseDelegate.heading(contains: range.location).map {
                                                    return DocumentHeading(documentString: string,
                                                                           headingToken: $0,
                                                                           url: url)
                                                }
                                                
                                                items.append(DocumentTextSearchResult(documentInfo: DocumentInfo(wrapperURL: url.wrapperURL),
                                                                                      highlightRange: highlightRange,
                                                                                      context: string.substring(contextRange),
                                                                                      heading: documentHeading))
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
            
            do {
                
                var results: [DocumentHeadingSearchResult] = []
                try self.loadAllFiles().forEach { url in
                    
                    let string = try String(contentsOf: url)
                    parser.parse(str: string)
                    
                    var resultsInFile: [DocumentHeadingSearchResult] = []
                    parseDelegate.dateAndTimes.forEach { dateAndTimeRange in
                        
                        if let headingToken = parseDelegate.heading(contains: dateAndTimeRange.location) {
                            let result = DocumentHeadingSearchResult(dateAndTime: DateAndTimeType(string.substring(dateAndTimeRange))!,
                                                     documentInfo: DocumentInfo(wrapperURL: url.wrapperURL),
                                                     dateAndTimeRange: dateAndTimeRange,
                                                     tags: nil,
                                                     planning: nil,
                                                     headingString: string.substring(headingToken.headingTextRange),
                                                     heading: DocumentHeading(documentString: string,
                                                                              headingToken: headingToken,
                                                                              url: url))
                            
                            resultsInFile.append(result)
                            
                        }
                    }
                    
                    results.append(contentsOf: resultsInFile)
                }
                
                completion(results)
                
            } catch {
                failure(error)
            }
            
        }
        
        self._headingSearchOperationQueue.addOperation(operation)
    }
    
    public func searchPlanning(_ planningToSearch: String, completion: @escaping ([DocumentHeadingSearchResult]) -> Void, failure: @escaping (Error) -> Void) {
        
        self.allHeadings(completion: { headings in
            var results: [DocumentHeadingSearchResult] = []
            
            headings.forEach { heading in
                if let planning = heading.planning {
                    let result = DocumentHeadingSearchResult(dateAndTime: nil,
                                                             documentInfo: DocumentInfo(wrapperURL: heading.url.wrapperURL),
                                                             dateAndTimeRange: nil,
                                                             tags: nil,
                                                             planning: planning,
                                                             headingString: heading.text,
                                                             heading: heading)
                    
                    results.append(result)
                }
            }
        }) { error in
            failure(error)
        }
    }
    
    public func searchTag(_ tagToSearch: String, completion: @escaping ([DocumentHeadingSearchResult]) -> Void, failure: @escaping (Error) -> Void) {
        self.allHeadings(completion: { heading in
            var results: [DocumentHeadingSearchResult] = []
            heading.forEach({ heading in
                if let tagsArray = heading.tags {
                    if tagsArray.contains(tagToSearch)
                    {
                        let result = DocumentHeadingSearchResult(dateAndTime: nil,
                                                                 documentInfo: DocumentInfo(wrapperURL: heading.url.wrapperURL),
                                                                 dateAndTimeRange: nil,
                                                                 tags: tagsArray,
                                                                 planning: nil,
                                                                 headingString: heading.text,
                                                                 heading: heading)
                        
                        results.append(result)
                    }
                    
                }
            })
        }) { error in
            failure(error)
        }
    }
    
    public func allHeadings(completion: @escaping ([DocumentHeading]) -> Void, failure: @escaping (Error) -> Void) {
        let operation = BlockOperation()
        
        operation.addExecutionBlock {
            
            // 解析文件中的全部 heading
            let parseDelegate = ParseDelegate()
            let parser = OutlineParser()
            parser.delegate = parseDelegate
            parser.includeParsee = .heading
            
            var headings: [DocumentHeading] = []
            do {
                try self.loadAllFiles().forEach { url in
                    
                    let string = try String(contentsOf: url)
                    parser.parse(str: string)
                
                    headings.append(contentsOf: parseDelegate.headings.map { headingToken in
                        DocumentHeading(documentString: string,
                                        headingToken: headingToken,
                                        url: url)
                    })
                }
                
                completion(headings)
            } catch {
                failure(error)
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
    
    private func _handleDocumentHeadingsChange(event: DocumentHeadingChangeEvent) {
        let newHeadings = event.newHeadings.map { (headingToken: HeadingToken) -> DocumentHeadingSearchResult in
            // 这里能收到 heading change 的 document 肯定是已经 open 了的，因为发 heading change 事件是在 OutlineTextStorage 文档解析完成的时候
            let headingString = self._editorContext.request(url: event.url).string.substring(headingToken.range)
            
            return DocumentHeadingSearchResult(dateAndTime: nil,
                                               documentInfo: DocumentInfo(wrapperURL: event.url.wrapperURL),
                                               dateAndTimeRange: nil,
                                               tags: nil,
                                               planning: nil,
                                               headingString: headingString,
                                               heading: DocumentHeading(documentString: self._editorContext.request(url: event.url).string,
                                                                        headingToken: headingToken,
                                                                        url: event.url))
        }

        let documentSearchHeadingChangeEvent = DocumentSearchHeadingUpdateEvent(oldHeadings: [], newHeadings: newHeadings)
        self._eventObserver.emit(documentSearchHeadingChangeEvent)
    }
}


class ParseDelegate: OutlineParserDelegate {
    var headings: [HeadingToken] = []
    var dateAndTimes: [NSRange] = []
    
    func didStartParsing(text: String) {
        // clear earlier found data
        self.headings = []
        self.dateAndTimes = []
    }
    
    func didFoundHeadings(text: String,
                          headingDataRanges: [[String: NSRange]]) {
        
        self.headings = headingDataRanges.map { HeadingToken(data: $0) }
    }
    
    func didFoundDateAndTime(text: String, rangesData: [[String:NSRange]]) {
        self.dateAndTimes = rangesData.map { $0.values.first! }
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
