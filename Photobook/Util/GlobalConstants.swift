//
//  GlobalConstants.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 09/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

let photobookBundle = Bundle(for: Photobook.self)
let photobookMainStoryboard =  UIStoryboard(name: "Main", bundle: photobookBundle)

struct CommonLocalizedStrings {
    static let somethingWentWrong = NSLocalizedString("GenericError/Something Went Wrong", value: "Something went wrong", comment: "Generic error message")
    static let alertOK = NSLocalizedString("Generic/OKButtonTitle", value: "OK", comment: "Acknowledgement to an alert dialog")
    static let retry = NSLocalizedString("General/RetryButtonTitle", value: "Retry", comment: "Button title to retry operation")
    static let cancel = NSLocalizedString("General/CancelButtonTitle", value: "Cancel", comment: "Cancel an action")
    static let yes = NSLocalizedString("General/YesButtonTitle", value: "Yes", comment: "Agree to an action")
    static let no = NSLocalizedString("General/NoButtonTitle", value: "No", comment: "Don't agree to an action")
    static let checkConnectionAndRetry = NSLocalizedString("Generic/CheckConnectionAndRetry", value: "Please check your internet connectivity and try again.", comment: "Message instructing the user to check their Internet connection.")

    static func serviceAccessError(serviceName: String) -> String {
        return NSLocalizedString("Generic/AccessError", value: "There was an error when trying to access \(serviceName)", comment: "Generic error when trying to access a social service eg Instagram/Facebook")
    }
}
