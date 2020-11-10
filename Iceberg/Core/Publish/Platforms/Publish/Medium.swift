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
    
    public var callback: String = "oauth-x3note://callback"
    
    public var state: String = "x3"
    
    public var scope: String = "basicProfile,publishPost"
    
    public let from: UIViewController
    
    public let oauth = OAuth2Swift(consumerKey: "ac8eb589ac0c",
                                    consumerSecret: "f2d4aeb61334ff373ff908127042c2a9542db5ef",
                                    authorizeUrl: "https://medium.com/m/oauth/authorize",
                                    accessTokenUrl: "https://api.medium.com/v1/tokens",
                                    responseType: "code")
    
    public func publish(title: String, content: String) -> Observable<Void> {
        self.oauth
            .tryAuthorize(obj: self)
            .flatMap({ self.userDetail() })
            .flatMap { post(title: title, markdown: content, authorId: $0).map { _ in } }
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
    
    public func userDetail() -> Observable<String> {
        return self.oauth.startAuthRequest(url: "https://api.medium.com/v1/me",
                                           method: OAuthSwiftHTTPRequest.Method.GET,
                                           parameters: [:],
                                           headers: ["Content-Type": "application/json",
                                                     "Accept": "application/json",
                                                     "Accept-Charset": "utf-8"])
            .catchError { error in
                let error = error as NSError
                if error.code == 401 {
                    if error.description.contains("User not found") {
                        return Observable.error(PublishErrorType.failToFetchUserInfo("Your account may have problem"))
                    } else {
                        return Observable.error(PublishErrorType.failToFetchUserInfo(error.description))
                    }
                } else {
                    return Observable.error(PublishErrorType.otherError(error.localizedDescription))
                }
            }
            .flatMap { response -> Observable<[String: Any]> in
                do {
                    if let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any] {
                        return Observable.just(json)
                    } else {
                        return Observable.just([:])
                    }
                } catch {
                    return Observable.error(error)
                }
            }.map { json in
                return KeypathParser(String.self, key: "data.id")(json) ?? ""
            }
    }
    
    public func post(title: String, markdown: String, authorId: String) -> Observable<OAuthSwiftResponse> {
        return self.oauth.startAuthRequest(url: "https://api.medium.com/v1/users/\(authorId)/posts",
                                           method: OAuthSwiftHTTPRequest.Method.POST,
                                           parameters: ["title": title,
                                                        "content": markdown,
                                                        "contentFormat": "markdown",
                                                        "publishStatus": "public"],
                                           headers: ["Content-Type": "application/json"]).catchError { error in
                                            if let errorMessage = (error as NSError).userInfo["Response-Body"] as? String {
                                                return Observable.error(PublishErrorType.otherError(errorMessage))
                                            } else {
                                                return Observable.error(error)
                                            }
                                           }
    }
}
