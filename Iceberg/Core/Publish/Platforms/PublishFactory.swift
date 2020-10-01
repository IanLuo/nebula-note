//
//  PublishFactory.swift
//  Core
//
//  Created by ian luo on 2020/9/20.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import RxSwift
import OAuthSwift

public protocol Publishable {
    func publish(title: String, markdown: String) -> Observable<Void>
}

public protocol Uploadable {
    func upload(url: URL) -> Observable<String>
}

public protocol OAuth2Connectable {
    var callback: String { get }
    var state: String { get }
    var scope: String { get }
    var oauth: OAuth2Swift { get }
    var from: UIViewController { get }
}

public struct PublishFactory {
    public enum Publisher: CaseIterable {
        case medium
        
        public var title: String {
            switch self {
            case .medium:
                return "Mediumn"
            }
        }
        
        public func publishableBuilder(from: UIViewController) -> Publishable {
            switch self {
            case .medium:
                return Medium(from: from)
            }
        }
        
    }
    
    public enum Uploader: CaseIterable {
        case oneDrive
        case dropbox
        
        public func attachmentUploaderBuilder(from: UIViewController) -> Uploadable {
            // TODO:
            return OneDrive(from: from)
        }
        
    }
    
    public func createPublishBuilder(publisher: Publisher, uploader: Uploader, from: UIViewController) -> (String, String, [Attachment]?) -> Observable<Void> {
        let publisher = publisher.publishableBuilder(from: from)
        let uploader = uploader.attachmentUploaderBuilder(from: from)
        
        return { (title: String, content: String, attachments: [Attachment]?) in
            var content = content
            
            let uploadObservables = attachments?.map { attachment in
                uploader.upload(url: attachment.url).do(onNext: { path in
                    content = (content as NSString).replacingOccurrences(of: attachment.serialize, with: path)
                })
            }
            
            let publishObservable = publisher.publish(title: title, markdown: content)
            
            if let uploadObservables = uploadObservables {
                return Observable.combineLatest(uploadObservables).flatMap({ _ in
                    publishObservable
                })
            } else {
                return publishObservable
            }
        }
    }
    
    public var allPublishers: [Publisher] {
        return Publisher.allCases
    }
    
    public init() {}
}

extension OAuth2Swift {
    private func logon(obj: OAuth2Connectable) -> Observable<OAuthSwiftCredential> {
        return self.authorize(callbackURL: obj.callback, scope: obj.scope, state: obj.state)
    }
    
    public var getToken: Observable<String> {
        if self.client.credential.oauthToken.count > 0 {
            return Observable.just(self.client.credential.oauthToken)
        } else {
            return Observable.empty()
        }
    }
    
    public func tryAuthorize(obj: OAuth2Connectable) -> Observable<Void> {
        return self.getToken
            .ifEmpty(switchTo: self.logon(obj: obj)
                        .map({ $0.oauthToken })).map { _ in }
    }
    
    public func startAuthRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: ConfigParameters) -> Observable<OAuthSwiftResponse> {
        return Observable.create { observer -> Disposable in
            self.startAuthorizedRequest(url,
                                        method: method,
                                        parameters: parameters,
                                        completionHandler: { result in
                                            switch result {
                                            case .success(let response):
                                                observer.onNext(response)
                                                observer.onCompleted()
                                            case .failure(let error):
                                                observer.onError(error)
                                            }
                                        })
            return Disposables.create()
        }
    }
    
    public func authorize(callbackURL: String, scope: String, state: String) -> Observable<OAuthSwiftCredential> {
        return Observable.create { observer -> Disposable in
            self.authorize(withCallbackURL: callbackURL, scope: scope, state: state) { result in
                switch result {
                case .success(let (credential, _, _)):
                    observer.onNext(credential)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
        
    }
}
