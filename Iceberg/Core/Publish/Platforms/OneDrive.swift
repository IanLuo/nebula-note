//
//  OneDrive.swift
//  Core
//
//  Created by ian luo on 2020/9/26.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import OAuthSwift
import RxSwift

public struct OneDrive: Uploadable, OAuth2Connectable {
    public func upload(url: URL) -> Observable<String> {
        return Observable.just("")
    }
    
    public var callback: String = "oauth-x3note://callback"
    
    public var state: String = "x3"
    
    public var scope: String = "user.read openid profile"
    
    public var from: UIViewController
    
    private static let tenant: String = "557593cd-ff77-46a7-b4f1-653d0d9dfaa2"
    
    public let oauth = OAuth2Swift(consumerKey: "46f3d8ed-65a5-4c85-a105-1676b8cea77d",
                                    consumerSecret: "f2d4aeb61334ff373ff908127042c2a9542db5ef",
                                    authorizeUrl: "https://login.microsoftonline.com/\(tenant)/oauth2/v2.0/devicecode",
                                    responseType: "code")
    
    private func uploadFile(url: URL) -> Observable<String> {
        return Observable.create { observer -> Disposable in
            
            return Disposables.create()
        }
    }
}
