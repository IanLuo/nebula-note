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
import Interface

enum PublishErrorType: Error {
    case failToFetchUserInfo(String)
    case otherError(String)
}

enum UploadError: Error {
    case failToUpload
    case uploaderIsNotSet
}

public protocol Publishable {
    func publish(title: String, content: String) -> Observable<Void>
}

public protocol Uploadable {
    func upload(attachment: Attachment) -> Observable<(String, String)>
}

public protocol OAuth2Connectable {
    var callback: String { get }
    var state: String { get }
    var scope: String { get }
    var oauth: OAuth2Swift { get }
    var from: UIViewController { get }
}

public struct PublishFactory {
    public static let callbacks: [String] = [
        "https://x3note-callback",
        "oauth-x3note://callback",
    ]
    
    public enum Publisher: CaseIterable {
        case medium
        case wordpress
        
        public var title: String {
            switch self {
            case .medium:
                return "Mediumn"
            case .wordpress:
                return "Wordpress"
            }
        }
        
        public func publishableBuilder(from: UIViewController) -> Publishable {
            switch self {
            case .medium:
                return Medium(from: from)
            case .wordpress:
                return Wordpress(from: from)
            }
        }
        
        public var exportFileType: ExportType {
            switch self {
            case .medium:
                return .markdown
            case .wordpress:
                return .html
            }
        }
    }
    
    public enum Uploader: CaseIterable {
        case oneDrive
        case dropbox
        
        public var title: String {
            switch self {
            case .dropbox: return "Dropbox"
            case .oneDrive: return "One Drive"
            }
        }
        
        public func attachmentUploaderBuilder(from: UIViewController) -> Uploadable {
            switch self {
            case .dropbox:
                return Dropbox(from: from)
            case .oneDrive:
                return OneDrive(from: from)
            }
        }
    }
    
    public func createPublishBuilder(publisher: Publisher, uploader: Uploader?, from: UIViewController) -> (String, String, [Attachment]?) -> Observable<Void> {
        let publisher = publisher.publishableBuilder(from: from)
        
        return { (title: String, content: String, attachments: [Attachment]?) in
            
            // if there's attachments, choose a uploader first, then use that to upload the attachment, then replace the uploaded link in the document
            if let attachments = attachments {
                if let uploader = uploader {
                    let uploadable = uploader.attachmentUploaderBuilder(from: from)
                    
                    let uploadObservables = attachments.map { attachment in
                        uploadable.upload(attachment: attachment)
                    }
                    
                    return Observable.combineLatest(uploadObservables).flatMap({ paths -> Observable<Void> in
                        var content = content
                        for path in paths {
                            content = (content as NSString).replacingOccurrences(of: path.1, with: path.0)
                        }
                        return publisher.publish(title: title, content: content)
                    })
                } else {
                    var content = content
                    for attachment in attachments {
                        content = (content as NSString).replacingOccurrences(of: attachment.serialize, with: "")
                    }
                    return publisher.publish(title: title, content: content)
                }
            } else {
                return publisher.publish(title: title, content: content)
            }
        }
    }
    
    public var allPublishers: [Publisher] {
        return Publisher.allCases
    }
    
    public init() {}
}

// MARK: - Auth convenience functions

extension OAuth2Swift {
    private func logon(obj: OAuth2Connectable, parameters: [String: Any] = [:]) -> Observable<OAuthSwiftCredential> {
        return self.authorize(callbackURL: obj.callback, scope: obj.scope, state: obj.state, parameter: parameters)
    }
    
    public var getToken: Observable<String> {
        if self.client.credential.oauthToken.count > 0 {
            return Observable.just(self.client.credential.oauthToken)
        } else {
            return Observable.empty()
        }
    }
    
    public func tryAuthorize(obj: OAuth2Connectable, parameters: [String: Any] = [:]) -> Observable<Void> {
        return self.getToken
            .ifEmpty(switchTo: self.logon(obj: obj, parameters: parameters)
                        .map({ $0.oauthToken })).map { _ in }
    }
    
    public func startAuthRequest(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: OAuthSwift.Parameters, headers: OAuthSwift.Headers? = nil, body: Data? = nil) -> Observable<OAuthSwiftResponse> {
        return Observable.create { observer -> Disposable in
            self.startAuthorizedRequest(url,
                                        method: method,
                                        parameters: parameters,
                                        headers: headers,
                                        body: body,
                                        completionHandler: { result in
                                            switch result {
                                            case .success(let response):
                                                observer.onNext(response)
                                                observer.onCompleted()
                                            case .failure(let error):
                                                if let code = ((error as NSError).userInfo["error"] as? NSError)?.code, [401, 403].contains(code) {
                                                    self.removeSavedCredential(consumerKey: self.client.credential.consumerKey)
                                                } else if error.description.contains(self.accessTokenUrl ?? "") {
                                                    self.removeSavedCredential(consumerKey: self.client.credential.consumerKey)
                                                }
                                                                                                
                                                if let underlineError = error.underlyingError {
                                                    observer.onError(underlineError)
                                                } else {
                                                    observer.onError(error)
                                                }
                                            }
                                        })
            return Disposables.create()
        }
    }
    
    public func saveCrendential(_ credential: OAuthSwiftCredential) -> Result<Void, Error> {
        let jsonEncoder = JSONEncoder()
        
        do {
            let json = try jsonEncoder.encode(credential)
            UserDefaults.standard.set(json, forKey: credential.consumerKey)
            UserDefaults.standard.synchronize()
            return Result.success(())
        } catch {
            return Result.failure(error)
        }
    }
    
    public func removeSavedCredential(consumerKey: String) {
        UserDefaults.standard.set(nil, forKey: consumerKey)
        UserDefaults.standard.synchronize()
    }
    
    public func loadSavedCredential(consumerKey: String) -> Result<OAuthSwiftCredential?, Error> {
        let jsonDecoder = JSONDecoder()
        
        do {
            let credential = try UserDefaults.standard.data(forKey: consumerKey)
                .map { try jsonDecoder.decode(OAuthSwiftCredential.self, from: $0) }
            return Result.success(credential)
        } catch {
            return Result.failure(error)
        }
    }
    
    public func authorize(callbackURL: String, scope: String, state: String, parameter: [String: Any] = [:]) -> Observable<OAuthSwiftCredential> {
        return Observable.create { observer -> Disposable in
            self.authorize(withCallbackURL: callbackURL, scope: scope, state: state, parameters: parameter) { [weak self] result in
                switch result {
                case .success(let (credential, _, _)):
                    _ = self?.saveCrendential(credential)
                    observer.onNext(credential)
                    observer.onCompleted()
                case .failure(let error):
                    log.error(error)
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
        
    }
}
