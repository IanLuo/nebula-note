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
    public let tags: [String]?
    public let planning: String?
//    public let due: DateAndTimeType?
//    public let schedule: DateAndTimeType?
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
        
//        if let due = headingToken.due {
//            self.due = DateAndTimeType.createFromDue(documentString.substring(due))
//        } else {
//            self.due = nil
//        }
//        
//        if let schedule = headingToken.schedule {
//            self.schedule = DateAndTimeType.createFromSchedule(documentString.substring(schedule))
//        } else {
//            self.schedule = nil
//        }
        
        self.text = documentString.substring(headingToken.range)
        
        self.paragraphSummery = documentString.substring(NSRange(location: headingToken.range.upperBound,
                                                                 length: min(100, headingToken.contentRange.length)))
    }
}

public struct DocumentSearchResult {
    public let url: URL
    public let highlightRange: NSRange
    public let context: String
    public let heading: HeadingToken?
    public let documentInfo: DocumentInfo
    
    public init(url: URL, highlightRange: NSRange, context: String, heading: HeadingToken?) {
        self.url = url
        self.highlightRange = highlightRange
        self.context = context
        self.heading = heading
        
        self.documentInfo = DocumentInfo(wrapperURL: url)
    }
}

public class DocumentSearchHeadingUpdateEvent: Event {
    public let oldHeadings: [DocumentSearchResult]
    public let newHeadings: [DocumentSearchResult]
    public init(oldHeadings: [DocumentSearchResult], newHeadings: [DocumentSearchResult]) {
        self.oldHeadings = oldHeadings
        self.newHeadings = newHeadings
    }
}

public struct DocumentHeadingSearchOptions: OptionSet {
    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public static let tag: DocumentHeadingSearchOptions = DocumentHeadingSearchOptions(rawValue: 1 << 1)
    public static let due: DocumentHeadingSearchOptions = DocumentHeadingSearchOptions(rawValue: 1 << 2)
    public static let schedule: DocumentHeadingSearchOptions = DocumentHeadingSearchOptions(rawValue: 1 << 3)
    public static let archived: DocumentHeadingSearchOptions = DocumentHeadingSearchOptions(rawValue: 1 << 5)
    public static let planning: DocumentHeadingSearchOptions = DocumentHeadingSearchOptions(rawValue: 1 << 4)
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
                       resultAdded: @escaping (_ result: [DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: ((Error) -> Void)?) {

        guard contain.count > 0 else { return }
        
        self._contentSearchOperationQueue.cancelAllOperations()
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
        
        self._contentSearchOperationQueue.addOperation(operation)
    }
    
    class ParseDelegate: OutlineParserDelegate {
        var headings: [HeadingToken] = []
        func didFoundHeadings(text: String,
                              headingDataRanges: [[String: NSRange]]) {
            
            self.headings = headingDataRanges.map { HeadingToken(data: $0) }
        }
    }
    
    public func searchHeading(options: DocumentHeadingSearchOptions,
                              filter: ((DocumentHeading) -> Bool)? = nil,
                              resultAdded: @escaping ([DocumentHeading]) -> Void,
                              complete: @escaping () -> Void,
                              failed: @escaping (Error) -> Void) {
        
        let operation = BlockOperation()
        
        operation.addExecutionBlock {
            let parseDelegate = ParseDelegate()
            let parser = OutlineParser()
            parser.delegate = parseDelegate
            parser.includeParsee = .heading
            
            do {
                try self.loadAllFiles().forEach { url in
                    let string = try String(contentsOf: url)
                    parser.parse(str: string)
                    
                    if parseDelegate.headings.count > 0 {
                        
                        let documentSearchResult = parseDelegate.headings.filter { heading in
                            if options.contains(DocumentHeadingSearchOptions.tag) && heading.tags != nil { return true }
                            if options.contains(DocumentHeadingSearchOptions.due) && heading.due != nil { return true }
                            if options.contains(DocumentHeadingSearchOptions.schedule) && heading.schedule != nil { return true }
                            if options.contains(DocumentHeadingSearchOptions.planning) && heading.planning != nil { return true }
                            return false
                        }
                        .map { heading in
                            DocumentHeading(documentString: string, headingToken: heading, url: url)
                        }
                        
                        if documentSearchResult.count > 0 {
                            if let filter = filter {
                                resultAdded(documentSearchResult.filter(filter))
                            } else {
                                resultAdded(documentSearchResult)
                            }
                        }
                        
                        parseDelegate.headings = []
                    }
                }
                
                DispatchQueue.main.async { complete() }
            } catch { DispatchQueue.main.async { failed(error) } }
        }
        
        self._headingSearchOperationQueue.addOperation(operation)
    }
    
    public func headingHasPlanning(contained in: [String], text: String, heading: [String: NSRange]) -> Bool {
        if let planningRange = heading[OutlineParser.Key.Element.Heading.planning] {
            return `in`.contains(text.substring(planningRange))
        } else {
            return false
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
    
    private func _handleDocumentHeadingsChange(event: DocumentHeadingChangeEvent) {
        let newHeadings = event.newHeadings.map { (headingToken: HeadingToken) -> DocumentSearchResult in
            // 这里能收到 heading change 的 document 肯定是已经 open 了的，因为发 heading change 事件是在 OutlineTextStorage 文档解析完成的时候
            let headingString = self._editorContext.request(url: event.url).string.substring(headingToken.range)
            return DocumentSearchResult(url: event.url, highlightRange: headingToken.range.offset(-headingToken.range.location), context: headingString, heading: headingToken)
        }
        
        let oldHeadings = event.oldHeadings.map { (headingToken: HeadingToken) -> DocumentSearchResult in
            // 这里能收到 heading change 的 document 肯定是已经 open 了的，因为发 heading change 事件是在 OutlineTextStorage 文档解析完成的时候
            let headingString = self._editorContext.request(url: event.url).string.substring(headingToken.range)
            return DocumentSearchResult(url: event.url, highlightRange: headingToken.range.offset(-headingToken.range.location), context: headingString, heading: headingToken)
        }
        
        let documentSearchHeadingChangeEvent = DocumentSearchHeadingUpdateEvent(oldHeadings: oldHeadings, newHeadings: newHeadings)
        self._eventObserver.emit(documentSearchHeadingChangeEvent)
    }
}
