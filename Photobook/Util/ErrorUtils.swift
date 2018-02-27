//
//  ErrorUtils.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

class ErrorUtils {
    
    static func genericRetryErrorMessage(message: String, action: @escaping () -> ()) -> ActionableErrorMessage {
        let title = CommonLocalizedStrings.somethingWentWrong
        let buttonTitle = CommonLocalizedStrings.retry
        return ActionableErrorMessage(title: title, message: message, buttonTitle: buttonTitle, buttonAction: action)
    }

}
