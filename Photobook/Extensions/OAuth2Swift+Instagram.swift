//
//  OAuth2Swift+Instagram.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 16/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import OAuthSwift

extension OAuth2Swift {
    
    private struct Constants {
        static let clientId = "1af4c208cbdc4d09bbe251704990638f"
        static let secret = "c8a5b1b1806f4586afad2f277cee1d5c"
        static let instagramAuthUrlString = "https://api.instagram.com/oauth/authorize"
    }
    
    static func instagramClient() -> OAuth2Swift {
        return OAuth2Swift(consumerKey: Constants.clientId, consumerSecret: Constants.secret, authorizeUrl: Constants.instagramAuthUrlString, responseType: "token")
    }

}
