//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import KeychainSwift
import OAuthSwift

class InstagramClient: OAuth2Swift {
    
    struct Constants {
        static let serviceName = "Instagram"
        static let clientId = "9e18da2dd4fa41e495cf769a18259595"
        static let secret = "7cf3519040074be78bf47d4270556937"
        static let instagramAuthUrlString = "https://api.instagram.com/oauth/authorize"
        static let keychainInstagramTokenKey = "InstagramTokenKey"
        static let redirectUri = "https://kite.ly/instagram-callback/photobook-ios"
        static let scope = "basic"
    }
    
    static let shared = InstagramClient()
    
    init() {
        super.init(consumerKey: Constants.clientId, consumerSecret: Constants.secret, authorizeUrl: Constants.instagramAuthUrlString, responseType: "token")
    }
    
}

extension InstagramClient: AccountClient {
    
    var serviceName: String {
        return Constants.serviceName
    }
    
    func logout() {
        KeychainSwift().delete(Constants.keychainInstagramTokenKey)
    }
}
