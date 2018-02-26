//
//  Analytics.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 26/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit
import KeychainSwift

class Analytics {
    
    private struct Constants {
        static let userIdKeychainKey = "userIdKeychainKey"
    }
    
    static let shared = Analytics()
    
    var userDistinctId: String {
        let keychain = KeychainSwift()
        keychain.synchronizable = true
        
        var userId: String! = keychain.get(Constants.userIdKeychainKey)
        if userId == nil {
            userId = UIDevice.current.identifierForVendor?.uuidString ?? UUID.init().uuidString
            keychain.set(userId, forKey: Constants.userIdKeychainKey)
        }
        
        return userId
    }

}
