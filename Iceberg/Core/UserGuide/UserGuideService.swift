//
//  UserGuideService.swift
//  Business
//
//  Created by ian luo on 2020/1/7.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import RxSwift
import Interface
import MHWebViewController

public enum HelpPage: String {
    case allUserGuide = "https://forum.nebulaapp.net/c/5"
    case editor = "https://forum.nebulaapp.net/t/12"
    case capture = "https://forum.nebulaapp.net/t/13"
    case documentManagement = "https://forum.nebulaapp.net/t/14"
    case entrance = "https://forum.nebulaapp.net/t/15"
    case dateAndTime = "https://forum.nebulaapp.net/t/16"
    case agenda = "https://forum.nebulaapp.net/t/17"
    case membership = "https://forum.nebulaapp.net/t/19";
    case syntax = "https://forum.nebulaapp.net/t/18";
    case privacyPolicy = "https://forum.nebulaapp.net/t/32";
    case termsOfService = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";
    
//    public func open() {
//        if let url = URL(string: self.rawValue), UIApplication.shared.canOpenURL(url) {
//            UIApplication.shared.open(url, options: [:], completionHandler: nil)
//        }
//    }
    
    public func open(from: UIViewController) {
        if isMacOrPad {
            UIApplication.shared.open(URL(string: self.rawValue)!, options: [:])
        } else {
            from.present(url: URL(string: self.rawValue)!, completion: nil)
        }
    }
    
    public static func open(from: UIViewController, url: String) {
        if let url = URL(string: url) {
            if isMacOrPad {
                UIApplication.shared.open(url, options: [:])
            } else {
                from.present(url: url, completion: nil)
            }
        }
    }
}

public struct UserGuideService {
    public init() {}
    public func createGuideDocument(documentManager: DocumentManager) -> Observable<[URL]> {
        let createActions = self.localizedGuideFileContents
            .map {
                createDocument(documentManager: documentManager, title: $0.0, content: $0.1)
            }
        
        return Observable.combineLatest(createActions)
    }
    
    private let zhFiles: [String] = ["开始使用", "功能介绍"]
    private let enFiles: [String] = ["Start Writing", "Function List"]
    private let fileExtension: String = "org"
    
    private func createDocument(documentManager: DocumentManager, title: String, content: String) -> Observable<URL> {
        return Observable.create { observer in
            let content = content.replacingOccurrences(of: "#date#", with: DateAndTimeType(date: Date(), includeTime: false, isSchedule: true).markString)
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
