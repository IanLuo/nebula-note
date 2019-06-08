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
    public let range: NSRange
    public let paragraphRange: NSRange
    public let paragraphWithSubRange: NSRange
    
    public init(documentString: String, headingToken: HeadingToken, url: URL) {
        self.range = headingToken.range
        self.paragraphRange = headingToken.paragraphRange
        self.url = url
        self.level = headingToken.level
        self.length = headingToken.paragraphRange.length
        self.location = headingToken.range.location
        self.paragraphWithSubRange = headingToken.paragraphWithSubRange
        
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
        
        self.paragraphSummery = documentString.nsstring.substring(with: NSRange(location: headingToken.contentRange.location,
                                                                 length: min(100, headingToken.contentRange.length)))
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
            
            do {
                
                var results: [DocumentHeadingSearchResult] = []
                try self.loadAllFiles().forEach { url in
                    
                    let string = try String(contentsOf: url)
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
                
            } catch {
                failure(error)
            }
            
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
                
                try self.loadAllFiles().forEach { url in
                    
                    let string = try String(contentsOf: url)
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
            return DocumentHeadingSearchResult(dateAndTime: nil,
                                               documentInfo: DocumentInfo(wrapperURL: event.url.wrapperURL),
                                               dateAndTimeRange: nil,
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
