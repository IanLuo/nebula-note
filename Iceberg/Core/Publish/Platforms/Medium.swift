//
//  Medium.swift
//  Core
//
//  Created by ian luo on 2020/9/20.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import OAuthSwift
import RxSwift

public struct Medium: Publishable, OAuth2Connectable {
    enum ErrorType: Error {
        case failToFetchUserInfo
    }
    
    public var callback: String = "oauth-x3note://callback"
    
    public var state: String = "x3"
    
    public var scope: String = "basicProfile,publishPost"
    
    public let from: UIViewController
    
    public let oauth = OAuth2Swift(consumerKey: "ac8eb589ac0c",
                                    consumerSecret: "f2d4aeb61334ff373ff908127042c2a9542db5ef",
                                    authorizeUrl: "https://medium.com/m/oauth/authorize",
                                    responseType: "code")
    
    public func publish(title: String, markdown: String) -> Observable<Void> {
        self.oauth
            .tryAuthorize(obj: self)
            .flatMap({
                self.authorId.ifEmpty(switchTo:
                                        self.userDetail()
                                        .map({ _ in "" }))
            })
            .flatMap { post(title: title, markdown: markdown, authorId: $0).map { _ in } }
    }
    
    private var userId: String?
    
    public init(from: UIViewController) {
        self.from = from
        let viewController = AuthViewController()
        self.oauth.authorizeURLHandler = viewController
    }
    
    private var authorId: Observable<String> {
        return self.userId == nil ? Observable.empty() : Observable.just(self.userId!)
    }
    
    public func userDetail() -> Observable<OAuthSwiftResponse> {
        return self.oauth.startAuthRequest(url: "https://api.medium.com/v1/me", method: OAuthSwiftHTTPRequest.Method.GET, parameters: [:])
    }
    
    public func post(title: String, markdown: String, authorId: String) -> Observable<OAuthSwiftResponse> {
        return self.oauth.startAuthRequest(url: "https://api.medium.com/v1/users/\(authorId)/posts",
                                           method: OAuthSwiftHTTPRequest.Method.POST,
                                           parameters: ["title": title,
                                                        "content": markdown,
                                                        "contentFormat": "markdown",
                                                        "publishStatus": "public"])
    }
}
