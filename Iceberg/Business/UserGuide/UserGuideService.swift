//
//  UserGuideService.swift
//  Business
//
//  Created by ian luo on 2020/1/7.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import RxSwift

public struct UserGuideService {
    public init() {}
    public func createGuideDocument(documentManager: DocumentManager) -> Observable<[URL]> {
        let createActions = self.localizedGuideFileContents
            .map {
                createDocument(documentManager: documentManager, title: $0.0, content: $0.1)
            }
        
        return Observable.combineLatest(createActions)
    }
    
    private let zhFiles: [String] = ["开始使用", "一句话功能介绍"]
    private let enFiles: [String] = ["Start Writing", "Function List"]
    private let fileExtension: String = "org"
    
    private func createDocument(documentManager: DocumentManager, title: String, content: String) -> Observable<URL> {
        return Observable.create { observer in
            
            documentManager.add(title: title, below: nil, content: content) { url in
                if let url = url {
                    observer.onNext(url)
                    
                } else {
                    observer.onError(DocumentError.failedToCreateDocument)
                }
                
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    private var localizedGuideFileContents: [(String, String)] {
        let getFiles: () -> [String] = {
            if let language = Locale.current.languageCode {
                if language.contains("zh") {
                    return self.zhFiles
                } else {
                    return self.enFiles
                }
            } else {
                return self.enFiles
            }
        }
        
        return getFiles()
            .reduce(Array<(String, URL)>()) { last , next in
                var result = last
                if let url = Bundle(for: _BundleToken.self).url(forResource: next, withExtension: fileExtension) {
                    result.append((next, url))
                }
                
                return result
        }.map {
            do {
                return ($0.0, try String(contentsOf: $0.1))
            } catch {
                log.error(error)
                return ($0.0, "")
            }
        }.filter {
            $0.1.count > 0
        }
    }
}

private class _BundleToken {}
