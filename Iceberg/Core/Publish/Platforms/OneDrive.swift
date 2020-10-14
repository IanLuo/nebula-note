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

enum UploadError: Error {
    case failToUpload
}

public struct OneDrive: Uploadable, OAuth2Connectable {
    public func upload(attachment: Attachment) -> Observable<String> {
        return self.oauth
            .tryAuthorize(obj: self)
            .flatMap { createFolderIfNeeded() }
            .flatMap { uploadFile(url: attachment.url, kind: attachment.kind) }
            .flatMap { createShareLink(id: $0) }
    }
    
    public var callback: String = "oauth-x3note://callback"
    
    public var state: String = "x3"
    
    public var scope: String = "user.read Files.ReadWrite openid profile offline_access"
    
    public var from: UIViewController
    
    private static let tenant: String = "consumers"
    
    private let folderName = "x3 note"
    
    public let oauth = OAuth2Swift(consumerKey: "46f3d8ed-65a5-4c85-a105-1676b8cea77d",
                                    consumerSecret: "",
                                    authorizeUrl: "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize",
                                    accessTokenUrl: "https://login.microsoftonline.com/consumers/oauth2/v2.0/token",
                                    responseType: "code")
    
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
    
    private func createFolderIfNeeded() -> Observable<Void> {
        return listAllFolders().flatMap { (folders: [String]) -> Observable<Void> in
            if folders.contains(folderName) {
                return Observable.just(())
            } else {
                return createFolder()
            }
        }
    }
    
    private func listAllFolders() -> Observable<[String]> {
        let endpoint = Endpoint.folders
        return self.oauth.startAuthRequest(url: endpoint.url, method: endpoint.method, parameters: endpoint.parameter)
            .flatMap { response -> Observable<[String]> in
                do {
                    if let json = (try JSONSerialization.jsonObject(with: response.data, options: [])) as? JSONDict,
                       let values = Parser([JSONDict].self, key: "value")(json) {
                        
                        let folderNames = values
                            .filter({Parser(JSONDict.self, key: "folder")($0) != nil})
                            .compactMap({Parser(String.self, key: "name")($0)})
                        
                        return Observable.just(folderNames)
                    } else {
                        return Observable.just([])
                    }
                } catch {
                    return Observable.error(error)
                }
            }
    }
    
    private func createFolder() -> Observable<Void> {
        let endpoint = Endpoint.createFolder(folderName)
        
        return self.oauth.startAuthRequest(url: endpoint.url, method: endpoint.method, parameters: endpoint.parameter, headers: endpoint.header)
            .map({ _ in })
    }
    
    private func uploadFile(url: URL, kind: Attachment.Kind) -> Observable<String> {
        let endpoint = Endpoint.upload(url, folderName, kind)
        
        return self.oauth.startAuthRequest(url: endpoint.url,
                                           method: endpoint.method,
                                           parameters: endpoint.parameter,
                                           headers: endpoint.header,
                                           body: endpoint.body)
            .flatMap { response -> Observable<String> in
                do {
                    if let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? JSONDict,
                       let id = Parser(String.self, key: "id")(json) {
                        return Observable.just(id)
                    } else {
                        return Observable.error(UploadError.failToUpload)
                    }
                } catch {
                    return Observable.error(error)
                }
            }
    }
    
    private func createShareLink(id: String) -> Observable<String> {
        let endpoint = Endpoint.createLink(id)
        
        return self.oauth.startAuthRequest(url: endpoint.url, method: endpoint.method, parameters: endpoint.parameter, headers: endpoint.header, body: endpoint.body)
            .flatMap { response -> Observable<String> in
                do {
                    if let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? JSONDict,
                       let url = KeypathParser(String.self, key: "link.webUrl")(json) {
                        return Observable.just(url)
                    } else {
                        return Observable.error(UploadError.failToUpload)
                    }
                } catch {
                    return Observable.error(error)
                }
            }
    }
}

private enum Endpoint {
    case folders
    case upload(URL, String, Attachment.Kind)
    case createFolder(String)
    case createLink(String)
    
    var parameter:  OAuthSwift.Parameters {
        switch self {
        case .folders:
            return [:]
        case .upload(_, _, _):
            return [:]
        case .createFolder(let name):
            return [
                "name": name,
                "folder": [:],
                "@microsoft.graph.conflictBehavior": "fail"
            ]
        case .createLink:
            return [
                "type": "embed",
            ]
        }
    }
    
    var method: OAuthSwiftHTTPRequest.Method {
        switch self {
        case .folders:
            return .GET
        case .upload(_, _, _):
            return .PUT
        case .createFolder(_):
            return .POST
        case .createLink:
            return .POST
        }
    }
    
    var path: String {
        switch self {
        case .folders:
            return "/me/drive/root/children"
        case .upload(let url, let folder, _):
            return "/me/drive/root:/\(folder.escapedSpace)/\(url.lastPathComponent):/content"
        case .createFolder(_):
            return "/me/drive/root/children"
        case .createLink(let id):
            return "/me/drive/items/\(id)/createLink"
        }
    }
    
    var body: Data? {
        switch self {
        case .folders:
            return nil
        case .upload(let url, _, _):
            return try? Data(contentsOf: url)
        case .createFolder(_):
            return nil
        case .createLink:
            return nil
        }
    }
    
    var host: String {
        return "https://graph.microsoft.com/v1.0"
    }
    
    var url: String {
        return self.host + path
    }
    
    var header: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
