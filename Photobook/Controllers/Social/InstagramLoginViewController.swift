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
import KeychainSwift

let keychainInstagramTokenKey = "InstagramTokenKey"

class InstagramLoginViewController: UIViewController {
    
    private var webView: WKWebView = WKWebView()
    private struct Constants {
        static let redirectUri = "https://kite.ly/instagram-callback"
        static let scope = "basic"
    }
    
    private lazy var instagramClient: OAuth2Swift = {
        let client = OAuth2Swift.instagramClient()
        client.authorizeURLHandler = self
        return client
    }()

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.frame = view.bounds
        view.insertSubview(webView, at: 0)
        
        startAuthenticatingUser()
    }
    
    private func startAuthenticatingUser() {
        activityIndicatorView.startAnimating()
        
        instagramClient.authorize(withCallbackURL: URL(string: Constants.redirectUri)!, scope: Constants.scope, state:"INSTAGRAM",
            success: { [weak welf = self] credential, response, parameters in
                KeychainSwift().set(credential.oauthToken, forKey: keychainInstagramTokenKey)
                
                welf?.navigationController?.setViewControllers([AssetPickerCollectionViewController.instagramAssetPicker()], animated: false)                
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
            return
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
