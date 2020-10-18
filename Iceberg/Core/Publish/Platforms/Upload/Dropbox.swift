//
//  Dropbox.swift
//  Core
//
//  Created by ian luo on 2020/9/26.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import OAuthSwift
import RxSwift

public struct Dropbox: Uploadable, OAuth2Connectable {
    public func upload(attachment: Attachment) -> Observable<(String, String)> {
        return self.oauth
            .tryAuthorize(obj: self)
            .flatMap { createFolderIfNeeded() }
            .flatMap { uploadFile(url: attachment.url, kind: attachment.kind) }
            .flatMap { createShareLink(path: $0) }
            .map { $0.replacingOccurrences(of: "dl=0", with: "raw=1") }
            .map { ($0, attachment.url.lastPathComponent) }
    }
    
    public var callback: String = "https://x3note-callback"
    
    public var state: String = "x3"
    
    public var scope: String = "files.content.write file_requests.write sharing.write sharing.read file_requests.read files.metadata.read"
    
    public var from: UIViewController
    
    private static let tenant: String = "consumers"
    
    private let folderName = "x3 note"
    
    public let oauth = OAuth2Swift(consumerKey: "ltczw6l280yss4l",
                                    consumerSecret: "gif78p2xzv0fk4h",
                                    authorizeUrl: "https://www.dropbox.com/oauth2/authorize",
                                    accessTokenUrl: "https://api.dropboxapi.com/oauth2/token",
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
        }.catchError { error -> Observable<()> in
            // igore for duplicate file name
            if (error as NSError).code == 409 {
                return Observable.just(())
            } else {
                return Observable.error(error)
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
                       let id = Parser(String.self, key: "path_lower")(json) {
                        return Observable.just(id)
                    } else {
                        return Observable.error(UploadError.failToUpload)
                    }
                } catch {
                    return Observable.error(error)
                }
            }
    }
    
    private func getFileSharedLink(path: String) -> Observable<String> {
        let endpoint = Endpoint.getShareLink(path)
        
        return self.oauth.startAuthRequest(url: endpoint.url, method: endpoint.method, parameters: endpoint.parameter, headers: endpoint.header).flatMap { response -> Observable<String> in
            do {
                if let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? JSONDict,
                   let link = KeypathParser([JSONDict].self, key: "links")(json)?.first,
                   let url = KeypathParser(String.self, key: "url")(link) {
                    return Observable.just(url)
                } else {
                    return Observable.error(UploadError.failToUpload)
                }
            } catch {
                return Observable.error(error)
            }
        }
    }
    
    private func createShareLink(path: String) -> Observable<String> {
        let endpoint = Endpoint.createLink(path)
        
        return self.oauth.startAuthRequest(url: endpoint.url,
                                           method: endpoint.method,
                                           parameters: endpoint.parameter,
                                           headers: endpoint.header,
                                           body: endpoint.body)
            .flatMap { response -> Observable<String> in
                do {
                    if let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? JSONDict,
                       let images = KeypathParser([JSONDict].self, key: "value")(json)?.first,
                       let url = KeypathParser(String.self, key: "large.url")(images) {
                        return Observable.just(url)
                    } else {
                        return Observable.error(UploadError.failToUpload)
                    }
                } catch {
                    return Observable.error(error)
                }
            }.catchError { (error) -> Observable<String> in
                if (error as NSError).code == 409 {
                    return self.getFileSharedLink(path: path)
                } else {
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
    case getShareLink(String)
    
    var parameter:  OAuthSwift.Parameters {
        switch self {
        case .folders:
            return [:]
        case .upload:
            return [:]
        case .createFolder(let folerName):
            return [
                "path": "/" + folerName,
                "autorename": false
            ]
        case .createLink(let filePath):
            return [
                "path": "\(filePath)",
                "settings" : [
                    "requested_visibility": "public",
                    "audience": "public",
                    "access": "viewer"
                ]]
        case .getShareLink(let filePath):
            return [
                "path": filePath,
            ]
        }
    }
    
    var method: OAuthSwiftHTTPRequest.Method {
        switch self {
        case .folders:
            return .POST
        case .upload(_, _, _):
            return .POST
        case .createFolder(_):
            return .POST
        case .createLink:
            return .POST
        case .getShareLink(_):
            return .POST
        }
    }
    
    var path: String {
        switch self {
        case .folders:
            return "/file_requests/list_v2"
        case .upload:
            return "/files/upload"
        case .createFolder(_):
            return "/files/create_folder_v2"
        case .createLink:
            return "/sharing/create_shared_link_with_settings"
        case .getShareLink(_):
            return "/sharing/list_shared_links"
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
        case .getShareLink(_):
            return nil
        }
    }
    
    var host: String {
        switch self {
        case .upload:
            return "https://content.dropboxapi.com/2"
        default:
            return "https://api.dropboxapi.com/2"
        }
    }
    
    var url: String {
        return self.host + path
    }
    
    var header: [String: String]? {
        switch self {
        case .upload(let url, let folder, _):
            do {
                let arg = try JSONEncoder().encode(["path": "/\(folder)/\(url.lastPathComponent)",
                                                    "mode": "add",
                                                    "autorename": false,
                                                    "mute": true,
                                                    "strict_conflict": false
                ])
                
                let argString = String(data: arg, encoding: .utf8) ?? ""
                
                return ["Content-Type": "application/octet-stream",
                        "Dropbox-API-Arg": argString]
            } catch {
                return [:]
            }
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
