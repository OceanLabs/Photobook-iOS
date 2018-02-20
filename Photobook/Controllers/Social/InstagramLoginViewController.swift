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

class InstagramLoginViewController: UIViewController {
    
    private var webView: WKWebView = WKWebView()
    
    private lazy var instagramClient: OAuth2Swift = {
        let client = OAuth2Swift.instagramClient()
        client.authorizeURLHandler = self
        return client
    }()
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
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
        
        // Before doing anything, clear any web data left over from a previous session
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), completionHandler: { records in
            for record in records {
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        })
        
        instagramClient.authorize(withCallbackURL: URL(string: OAuth2Swift.Constants.redirectUri)!, scope: OAuth2Swift.Constants.scope, state:"INSTAGRAM",
            success: { [weak welf = self] credential, response, parameters in
                KeychainSwift().set(credential.oauthToken, forKey: OAuth2Swift.Constants.keychainInstagramTokenKey)
                welf?.navigationController?.setViewControllers([AssetPickerCollectionViewController.instagramAssetPicker()], animated: false)                
        }, failure: { [weak welf = self] error in
            welf?.emptyScreenViewController.show(ErrorMessage(message: error.localizedDescription, retryButtonAction: { [weak welf = self] in
                welf?.emptyScreenViewController.hide()
                welf?.startAuthenticatingUser()
            }))
        })
    }
}

extension InstagramLoginViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        
        if url.absoluteString.hasPrefix(OAuth2Swift.Constants.redirectUri) {
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
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        emptyScreenViewController.show(ErrorMessage(message: error.localizedDescription, retryButtonAction: { [weak welf = self] in
            welf?.emptyScreenViewController.hide()
            welf?.startAuthenticatingUser()
        }))
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        emptyScreenViewController.show(ErrorMessage(message: error.localizedDescription, retryButtonAction: { [weak welf = self] in
            welf?.emptyScreenViewController.hide()
            welf?.startAuthenticatingUser()
        }))
    }
    
}

extension InstagramLoginViewController: OAuthSwiftURLHandlerType {
    func handle(_ url: URL) {
        webView.load(URLRequest(url: url))
    }
    
    
}
