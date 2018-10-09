//
//  AccountClient.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 09/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

enum AccountError: Error {
    case notLoggedIn
}

protocol AccountClient {
    func logout()
    var serviceName: String { get }
}

protocol LogoutHandler where Self: UIViewController {
    func prepareToHandleLogout(accountManager: AccountClient)
    func popToLandingScreen()
}
