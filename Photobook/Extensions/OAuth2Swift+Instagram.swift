//
//  OAuth2Swift+Instagram.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 16/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import OAuthSwift

extension OAuth2Swift {
    
    struct Constants {
        static let clientId = "9e18da2dd4fa41e495cf769a18259595"
        static let secret = "7cf3519040074be78bf47d4270556937"
        static let instagramAuthUrlString = "https://api.instagram.com/oauth/authorize"
        static let keychainInstagramTokenKey = "InstagramTokenKey"
        static let redirectUri = "https://kite.ly/instagram-callback/photobook-ios"
        static let scope = "basic"
    }
    
    static func instagramClient() -> OAuth2Swift {
        return OAuth2Swift(consumerKey: Constants.clientId, consumerSecret: Constants.secret, authorizeUrl: Constants.instagramAuthUrlString, responseType: "token")
    }

}
