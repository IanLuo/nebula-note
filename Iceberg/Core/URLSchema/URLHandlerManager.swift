//
//  URLHandlerManager.swift
//  Business
//
//  Created by ian luo on 2019/5/4.
//  Copyright © 2019 wod. All rights reserved.
//

import Foundation
import OAuthSwift

public class URLHandlerManager {
    
    private var _handlers: [URLHandler] = []
    
    private let documentManager: DocumentManager
    
    private let eventObserver: EventObserver
    
    public init(documentManager: DocumentManager, eventObserver: EventObserver) {
        self.documentManager = documentManager
        self.eventObserver = eventObserver
    }
    
    public func handle(url: URL, sourceApp: String) -> Bool {

        if url.host == "oauth-x3note" {
            OAuthSwift.handle(url: url)
        }
        
        let urlSchemeHandler = URLSchemeHandler(sourceApp: sourceApp, url: url)
        
        if !urlSchemeHandler.execute(documentManager: self.documentManager, eventObserver: self.eventObserver) {
            let xCallbackURLHandler = XCallbackURLlHandler(sourceApp: sourceApp, url: url)
            return xCallbackURLHandler.execute(documentManager: self.documentManager, eventObserver: self.eventObserver)
        } else {
            return true
        }
    }
}
