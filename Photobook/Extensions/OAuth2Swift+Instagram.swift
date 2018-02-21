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
        static let clientId = "94de981b3c744775a41c24ceac0c7609"
        static let secret = "df7bd131253043e693c266a3b4105149"
        static let instagramAuthUrlString = "https://api.instagram.com/oauth/authorize"
        static let keychainInstagramTokenKey = "InstagramTokenKey"
        static let redirectUri = "https://kite.ly/instagram-callback"
        static let scope = "basic"
    }
    
    static func instagramClient() -> OAuth2Swift {
        return OAuth2Swift(consumerKey: Constants.clientId, consumerSecret: Constants.secret, authorizeUrl: Constants.instagramAuthUrlString, responseType: "token")
    }

}
