//
//  Wordpress.swift
//  Core
//
//  Created by ian luo on 2020/9/20.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import OAuthSwift
import RxSwift
import Interface

public struct Wordpress: Publishable, OAuth2Connectable {
    public var callback: String = "oauth-x3note://callback"
    
    public var state: String = "x3"
    
    public var scope: String = "global"
    
    public let from: UIViewController
    
    public let oauth = OAuth2Swift(consumerKey: "70772",
                                    consumerSecret: "84iMbydl4NBre2PYb1ED2o88CP3w7vOksUfVuvVDvJvNwgnWevuq6IvXtQC6lTQZ",
                                    authorizeUrl: "https://public-api.wordpress.com/oauth2/authorize",
                                    accessTokenUrl: "https://public-api.wordpress.com/oauth2/token",
                                    responseType: "code")
    
    public func publish(title: String, content: String) -> Observable<Void> {
        self.oauth
            .tryAuthorize(obj: self)
            .flatMap({ self.getSite() })
            .flatMap { post(title: title, markdown: content, siteId: $0).map { _ in } }
    }
    
    public init(from: UIViewController) {
        self.from = from
        let viewController = AuthViewController()
        self.oauth.authorizeURLHandler = viewController
        
        switch oauth.loadSavedCredential(consumerKey: oauth.client.credential.consumerKey) {
        case .success(let credential):
            if let credential = credential {
                self.oauth.client = OAuthSwiftClient(credential: credential)
            }
        case .failure(let error):
            log.error(error)
        }
    }
    
    public func getSite() -> Observable<String> {
                
        return self.oauth.startAuthRequest(url: "https://public-api.wordpress.com/rest/v1.1/me/sites",
                                           method: OAuthSwiftHTTPRequest.Method.GET,
                                           parameters: [:],
                                           headers: ["Content-Type": "application/json",
                                                     "Accept": "application/json",
                                                     "Accept-Charset": "utf-8"])
            .flatMap { response -> Observable<JSONDict> in
                do {
                    if let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? JSONDict {
                        return Observable.just(json)
                    } else {
                        return Observable.just([:])
                    }
                } catch {
                    return Observable.error(error)
                }
            }.flatMap { json -> Observable<String> in
                let ids = (KeypathParser([JSONDict].self, key: "sites")(json) ?? []).compactMap { Parser(Int.self, key: "ID")($0) }.map { "\($0)" }
                
                if ids.count == 0 {
                    return Observable.error(PublishErrorType.failToFetchUserInfo("no site found on wordpress"))
                } else if ids.count < 2 {
                    return Observable.just(ids[0])
                } else {
                    let selector = SelectorViewController()
                    for item in ids {
                        selector.addItem(title: item)
                    }
                    self.from.present(selector, animated: true)
                    
                    return selector.rx.selectable().map({ (index: Int) -> String in ids[index] })
                }
            }
    }
    
    public func post(title: String, markdown: String, siteId: String) -> Observable<OAuthSwiftResponse> {
        return self.oauth.startAuthRequest(url: "https://public-api.wordpress.com/rest/v1.2/sites/\(siteId)/posts/new",
                                           method: OAuthSwiftHTTPRequest.Method.POST,
                                           parameters: ["title": title,
                                                        "content": markdown],
                                           headers: ["Content-Type": "application/json"]).catchError { error in
                                            if let errorMessage = (error as NSError).userInfo["Response-Body"] as? String {
                                                return Observable.error(PublishErrorType.otherError(errorMessage))
                                            } else {
                                                return Observable.error(error)
                                            }
                                           }
    }
}
