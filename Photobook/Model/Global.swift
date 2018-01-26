//
//  Config.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 06/10/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

struct Config {
    
    struct Constants {
        static let applePayPayTo = "Canon"
        static let applePayMerchantId = "merchant.ly.kite.sdk"
        
        static let stripePublicKey = "pk_test_fJtOj7oxBKrLFOneBFLj0OH3"
//        static let stripePublicKey = "pk_live_qQhXxzjS8inja3K31GDajdXo"
    }
    
}

struct Global {
    
    struct Constants {
        static let errorColor = UIColor(red:1, green:0.23, blue:0.19, alpha:1)
        static let requiredText = NSLocalizedString("UserInputRequired", value: "Required", comment: "User input required")
        static let minPhoneNumberLength = 5
    }
}
