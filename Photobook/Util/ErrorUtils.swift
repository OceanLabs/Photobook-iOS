//
//  ErrorUtils.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

class ErrorUtils {
    
    static func genericRetryErrorMessage(message: String, action: @escaping () -> ()) -> ErrorMessage {
        let title = NSLocalizedString("GenericError/Something Went Wrong", value: "Something went wrong", comment: "Generic error message")
        let buttonTitle = NSLocalizedString("General/RetryButtonTitle", value: "Retry", comment: "Button title to retry operation")
        return ErrorMessage(title: title, message: message, buttonTitle: buttonTitle, buttonAction: action)
    }

}
