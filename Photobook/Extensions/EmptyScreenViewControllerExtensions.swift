//
//  EmptyScreenViewControllerExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 19/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

extension EmptyScreenViewController {
    func show(_ errorMessage: ErrorMessage) {
        show(message: errorMessage.message, title:errorMessage.title, buttonTitle: errorMessage.buttonTitle, buttonAction: errorMessage.buttonAction)
    }
}
