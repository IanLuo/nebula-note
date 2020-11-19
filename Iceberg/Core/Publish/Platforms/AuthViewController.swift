//
//  AuthViewController.swift
//  Core
//
//  Created by ian luo on 2020/9/20.
//  Copyright © 2020 wod. All rights reserved.
//

import Foundation
import OAuthSwift
import UIKit
import Interface

#if os(iOS)
    import UIKit
    import WebKit
    typealias WebView = WKWebView
#elseif os(OSX)
    import AppKit
    import WebKit
    typealias WebView = WKWebView
#endif

class AuthViewController: OAuthWebViewController {

    var targetURL: URL?
    let webView: WebView = WebView()
    let toolbar = UIToolbar()
    public var onCancel: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.frame = self.view.bounds
        self.webView.navigationDelegate = self
        self.webView.customUserAgent = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"

        self.view.addSubview(self.toolbar)
        self.view.addSubview(self.webView)
        
        self.toolbar.size(height: 44)
        self.toolbar.sideAnchor(for: [.top, .left, .right], to: self.view, edgeInset: 0)
        self.toolbar.columnAnchor(view: self.webView)
        self.webView.sideAnchor(for: [.left, .right, .bottom], to: self.view, edgeInset: 0)
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        #if os(iOS)
        loadAddressURL()
        #endif
        
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil),
                         UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(cancel))]
    }
    
    @objc private func cancel() {
        self.dismissWebViewController()
        onCancel?()
    }

    override func handle(_ url: URL) {
        targetURL = url
        super.handle(url)
        self.loadAddressURL()
    }
    
    func loadAddressURL() {
        guard let url = targetURL else {
            return
        }
        let req = URLRequest(url: url)
        DispatchQueue.main.async {
            self.webView.load(req)
        }
    }
}

// MARK: delegate

extension AuthViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // here we handle internally the callback url and call method that call handleOpenURL (not app scheme used)
        if let url = navigationAction.request.url , ["msauth.com.wod.x3note://auth", "oauth-x3note"].contains(url.scheme) || url.absoluteString.hasPrefix("https://x3note-callback") {
            decisionHandler(.cancel)
            OAuthSwift.handle(url: url)
            self.dismissWebViewController()
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("\(error)")
        self.dismissWebViewController()
        onCancel?()
        // maybe cancel request...
    }
}
