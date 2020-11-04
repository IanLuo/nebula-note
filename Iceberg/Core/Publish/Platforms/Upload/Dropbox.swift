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
import SwiftyDropbox

public class Dropbox: Uploadable, OAuth2Connectable {
    public func upload(attachment: Attachment) -> Observable<(String, String)> {
        return self.oauth
            .tryAuthorize(obj: self, parameters: ["token_access_type": "offline"])
            .flatMap { self.createFolderIfNeeded() }
            .flatMap { self.uploadFile(url: attachment.url, attachment: attachment) }
            .flatMap { self.createShareLink(path: $0) }
            .map { $0.replacingOccurrences(of: "dl=0", with: "raw=1") }
            .map { ($0, attachment.url.lastPathComponent) }
    }
    
    public var callback: String = "https://x3note-callback"
    
    public var state: String = "x3"
    
    public var scope: String = "files.content.write file_requests.write sharing.write sharing.read file_requests.read files.metadata.read"
    
    public var from: UIViewController
    
    private static let tenant: String = "consumers"
    
    private let folderName = "x3 note"
    
    var dropboxClient: DropboxClient?
    
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
        return listAllFolders().flatMap { [weak self] (folders: [String]) -> Observable<Void> in
            guard let strongSelf = self else { return Observable.just(()) }
            
            if folders.contains(strongSelf.folderName) {
                return Observable.just(())
            } else {
                return strongSelf.createFolder()
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
    
    private func uploadFile(url: URL, attachment: Attachment) -> Observable<String> {
        
        if attachment.size / 1024 / 1024 >= 150 {
            return uploadLargeFile(url: url)
        } else {
            return uploadSmallFile(url: url, attachment: attachment)
        }
    }
    
    private func uploadSmallFile(url: URL, attachment: Attachment) -> Observable<String> {
        let endpoint = Endpoint.upload(url, folderName, attachment.kind)
        
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
    
    
    let chunkSize = 5 * 1024 * 1024 // 5MB
    var offset = 0
    var sessionId = ""
    private func uploadLargeFile(url: URL) -> Observable<String> {
        self.dropboxClient = DropboxClient(accessToken: self.oauth.client.credential.oauthToken)
        
        let data = NSData(contentsOf: url)!
        
        return Observable.create { observer -> Disposable in
            
            func uploadFirstChunk() {
                let size = min(self.chunkSize, data.count)
                self.dropboxClient!.files.uploadSessionStart(input: data.subdata(with: NSRange(location: 0, length: self.chunkSize)))
                    .response { response, error in
                        if let result = response {
                            self.sessionId = result.sessionId
                            self.offset += size
                            print("So far \(self.offset) bytes have been uploaded.")
                            uploadNextChunk()
                        } else if let error = error {
                            observer.onError(UploadError.failToUpload)
                        }
                    }
            }
            
            func uploadNextChunk() {
                if data.count - self.offset <= self.chunkSize {
                    let size = data.count - self.offset
                    self.dropboxClient!.files.uploadSessionFinish(
                        cursor: Files.UploadSessionCursor(
                            sessionId: self.sessionId, offset: UInt64(self.offset)),
                        commit: Files.CommitInfo(path: "/\(self.folderName)/\(url.lastPathComponent)"),
                        input: data.subdata(with: NSMakeRange(self.offset, size)))
                        .response { response, error in
                            if let error = error {
                                observer.onError(UploadError.failToUpload)
                            } else if let response = response {
                                observer.onNext(response.id)
                            }
                        }
                } else {
                    self.dropboxClient!.files.uploadSessionAppendV2(cursor: Files.UploadSessionCursor(sessionId: self.sessionId, offset: UInt64(self.offset)), input: data.subdata(with: NSRange(location: self.offset, length: self.chunkSize))).response { response, error in
                        if error != nil {
                            
                        } else {
                            self.offset += self.chunkSize
                            print("So far \(self.offset) bytes have been uploaded.")
                            uploadNextChunk()
                        }
                    }
                }
            }
        
            uploadFirstChunk()
            
            return Disposables.create()
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
