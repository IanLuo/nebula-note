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
}

public protocol DocumentSearchDelegate: class {
    func didSelectDocument(url: URL)
}

public class DocumentSearchViewModel {
    public weak var delegate: DocumentSearchDelegate?
    private let operationQueue: OperationQueue
    
    public init() {
        self.operationQueue = OperationQueue()
        operationQueue.underlyingQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
    }
    
     // MARK: -
    public func search(contain: String,
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: ((Error) -> Void)?) {
        
        self.operationQueue.cancelAllOperations()
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
                                                let upperBound = min(range.upperBound + 10, string.count - 1)
                                                let contextRange = NSRange(location: lowerBound, length: upperBound - lowerBound)
                                                let highlightRange = NSRange(location: range.location - lowerBound, length: range.length)
                                                
                                                item.append(DocumentSearchResult(url: url,
                                                                                 highlightRange: highlightRange,
                                                                                 context: (string as NSString).substring(with: contextRange)))
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
        
        operationQueue.addOperation(operation)
    }
    
    // MARK: -
    public func search(tags: [String],
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: ((Error) -> Void)?) {
        
        self.doSearchHeading(resultAdded: resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [[String: NSRange]]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let tagsRange = heading[OutlineParser.Key.Element.Heading.tags],
                                        let headingRange = heading[OutlineParser.Key.Node.heading] {
                                        let tagString = (string as NSString).substring(with: tagsRange)
                                        for t in tags {
                                            let range = (tagString as NSString).range(of: t)
                                            if range.location != Int.max {
                                                searchResults.append(DocumentSearchResult(url: url,
                                                                                          highlightRange: range,
                                                                                          context: (string as NSString).substring(with: headingRange)))
                                            }
                                        }
                                    }
                                }
                                
                                return searchResults
        }

    }
    
    // MARK: -
    
    public func search(schedule: Date,
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: ((Error) -> Void)?) {
        let today = Date()
        
        self.doSearchHeading(resultAdded: resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [[String: NSRange]]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let scheduleRange = heading[OutlineParser.Key.Element.Heading.schedule],
                                        let headingRange = heading[OutlineParser.Key.Node.heading] {
                                        let headingString = (string as NSString).substring(with: headingRange)
                                        
                                        if let scheduleDate = Date.createFromSchedule(headingString) {
                                            if scheduleDate < today {
                                                searchResults.append(DocumentSearchResult(url: url,
                                                                                          highlightRange: scheduleRange,
                                                                                          context: (string as NSString).substring(with: headingRange)))
                                            }
                                        }
                                    }
                                }
                                
                                return searchResults
        }

    }
    
    // MARK: -
    public func search(due: Date,
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: ((Error) -> Void)?) {
        let today = Date()

        self.doSearchHeading(resultAdded:resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [[String: NSRange]]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let dueRange = heading[OutlineParser.Key.Element.Heading.due],
                                        let headingRange = heading[OutlineParser.Key.Node.heading] {
                                        let headingString = (string as NSString).substring(with: headingRange)
                                        
                                        if let dueDate = Date.createFromDue(headingString) {
                                            if dueDate <= today {
                                                searchResults.append(DocumentSearchResult(url: url,
                                                                                          highlightRange: dueRange,
                                                                                          context: (string as NSString).substring(with: headingRange)))
                                            }
                                        }
                                    }
                                }
                                
                                return searchResults
            }

    }
    
    // MARK: -
    public func search(plannings: [String],
                       resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                       complete: @escaping () -> Void,
                       failed: ((Error) -> Void)?) {
        
        self.doSearchHeading(resultAdded:resultAdded,
                             complete: complete,
                             failed: failed) { (string: String, url: URL, headings: [[String: NSRange]]) -> [DocumentSearchResult] in
                                var searchResults: [DocumentSearchResult] = []
                                for heading in headings {
                                    if let planningRange = heading[OutlineParser.Key.Element.Heading.planning],
                                        let headingRange = heading[OutlineParser.Key.Node.heading] {
                                        let planningString = (string as NSString).substring(with: planningRange)
                                        
                                        if plannings.contains(planningString) {
                                            searchResults.append(DocumentSearchResult(url: url,
                                                                                      highlightRange: planningRange,
                                                                                      context: (string as NSString).substring(with: headingRange)))
                                        }
                                    }
                                }
                                
                                return searchResults
        }

    }
    
     // MARK: - private
    private func doSearchHeading(resultAdded: @escaping ([DocumentSearchResult]) -> Void,
                                 complete: @escaping () -> Void,
                                 failed: ((Error) -> Void)?,
                                 onEachHeadingMatch: @escaping (String, URL, [[String: NSRange]]) -> [DocumentSearchResult]) {
        
        self.operationQueue.cancelAllOperations()
        let operation = BlockOperation()
        
        operation.completionBlock = {
            OperationQueue.main.addOperation {
                complete()
            }
        }
        
        operation.addExecutionBlock {
            
            class ParseDelegate: OutlineParserDelegate {
                var headings: [[String: NSRange]] = []
                func didFoundHeadings(text: String,
                                      headingDataRanges: [[String : NSRange]]) {
                    self.headings = headingDataRanges
                }
            }
            
            let parseDelegate = ParseDelegate()
            let parser = OutlineParser(delegate: parseDelegate)
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
        
        operationQueue.addOperation(operation)
    }
    
    internal func loadAllFiles() -> [URL] {
        var result: [URL] = []
          guard let enumerator = FileManager.default.enumerator(at: URL.filesFolder,
                                       includingPropertiesForKeys: nil,
                                       options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles,
                                       errorHandler: nil) else { return result}
        
        for file in enumerator {
            if let url = file as? URL, url.pathExtension == Document.fileExtension {
                result.append(url)
            }
        }
        
        return result
    }
}
