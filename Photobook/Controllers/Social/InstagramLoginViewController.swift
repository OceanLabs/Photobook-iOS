//
//  InstagramLoginViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 15/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import OAuthSwift
import WebKit

class InstagramLoginViewController: UIViewController {
    
    var webView: WKWebView = WKWebView()
    
    private struct Constants {
        static let clientId = "1af4c208cbdc4d09bbe251704990638f"
        static let secret = "c8a5b1b1806f4586afad2f277cee1d5c"
        static let redirectUri = "https://kite.ly/instagram-callback"
        static let instagramAuthUrlString = "https://api.instagram.com/oauth/authorize"
        static let scope = "basic"
    }

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    lazy var oauthswift: OAuth2Swift = {
        let oauthswift = OAuth2Swift(consumerKey: Constants.clientId, consumerSecret: Constants.secret, authorizeUrl: Constants.instagramAuthUrlString, responseType: "token")
        oauthswift.authorizeURLHandler = self
        
        return oauthswift
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.frame = view.bounds
        view.insertSubview(webView, at: 0)
        
        startAuthenticatingUser()
    }
    
    private func startAuthenticatingUser() {
        activityIndicatorView.startAnimating()
        
        oauthswift.authorize(withCallbackURL: URL(string: Constants.redirectUri)!, scope: Constants.scope, state:"INSTAGRAM",
            success: { credential, response, parameters in
                print(credential.oauthToken)
                // Do your request
        }, failure: { error in
                print(error.localizedDescription)
        })
    }
}

extension InstagramLoginViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        
        if url.absoluteString.hasPrefix(Constants.redirectUri) {
            webView.stopLoading()
            
            OAuthSwift.handle(url: url)
            decisionHandler(.cancel)
        }
        
        activityIndicatorView.stopAnimating()
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicatorView.stopAnimating()
    }
    
}

extension InstagramLoginViewController: OAuthSwiftURLHandlerType {
    func handle(_ url: URL) {
        webView.load(URLRequest(url: url))
    }
    
    
}
