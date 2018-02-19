//
//  ErrorMessageExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 19/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

extension ErrorMessage {
    init(message: String, retryButtonAction: @escaping () -> ()) {
        title = NSLocalizedString("GenericError/Something Went Wrong", value: "Something went wrong", comment: "Generic error message")
        self.message = message
        buttonTitle = NSLocalizedString("General/RetryButtonTitle", value: "Retry", comment: "Button title to retry operation")
        buttonAction = retryButtonAction
    }
}


