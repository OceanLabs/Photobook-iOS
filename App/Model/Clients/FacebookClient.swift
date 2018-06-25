//
//  FacebookClient.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 09/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import FBSDKLoginKit

class FacebookClient {
    
    struct Constants {
        static let serviceName = "Facebook"
    }
    
    static let shared = FacebookClient()
}

extension FacebookClient: AccountClient {
    
    func logout() {
        FBSDKLoginManager().logOut()
    }
    
    var serviceName: String {
        return Constants.serviceName
    }
}
