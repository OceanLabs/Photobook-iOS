//
//  InstagramLoginViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 15/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import OAuthSwift

class InstagramLoginViewController: UIViewController {
    
    private struct Constants {
        static let clientId = "1af4c208cbdc4d09bbe251704990638f"
        static let secret = "c8a5b1b1806f4586afad2f277cee1d5c"
        static let redirectUri = "https://kite.ly/instagram-callback"
        static let instagramAuthUrlString = "https://api.instagram.com/oauth/authorize"
        static let scope = "basic"
    }

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    lazy var oauthswift: OAuth2Swift = {
        let oauthswift = OAuth2Swift(consumerKey: Constants.clientId, consumerSecret: Constants.secret, authorizeUrl: Constants.instagramAuthUrlString, responseType: "token")
        oauthswift.authorizeURLHandler = self
        
        return oauthswift
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

extension InstagramLoginViewController: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else { return true }
        
        if url.absoluteString.hasPrefix(Constants.redirectUri) {
            webView.stopLoading()
            
            OAuthSwift.handle(url: url)
        }
        
        activityIndicatorView.stopAnimating()
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activityIndicatorView.stopAnimating()
    }
    
}

extension InstagramLoginViewController: OAuthSwiftURLHandlerType {
    func handle(_ url: URL) {
        webView.loadRequest(URLRequest(url: url))
    }
    
    
}
