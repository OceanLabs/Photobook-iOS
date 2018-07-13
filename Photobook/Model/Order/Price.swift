//
//  Price.swift
//  Photobook
//
//  Created by Julian Gruber on 05/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

struct Price: Codable {
    
    let currencyCode: String
    let value: Decimal
    let formatted: String
    private let formattingLocale: Locale
    
    init?(currencyCode: String, value: Decimal, formattingLocale: Locale = Locale.current) {
        var decimalNumberValue = value as NSDecimalNumber
        decimalNumberValue = decimalNumberValue.rounding(accordingToBehavior: CurrencyRoundingBehavior())
        
        self.currencyCode = currencyCode
        self.value = decimalNumberValue as Decimal
        self.formattingLocale = formattingLocale
        
        if value > 0 {
            self.formatted = value.formattedCost(currencyCode: currencyCode, locale: formattingLocale)
        } else {
            self.formatted = NSLocalizedString("Model/Order/Price/FormattedFree", value: "Free", comment: "Text that gets displayed if a price is 0.0").uppercased()
        }
    }
    
    static func parse(_ dictionary: [String: Any], currencyCode: String? = nil, formattingLocale: Locale = Locale.current) -> Price? {
        
        guard let valuesDict = dictionary as? [String: Double] else {
            return nil
        }
        
        var currencyCodes = OrderManager.shared.prioritizedCurrencyCodes
        if let currencyCode = currencyCode {
            currencyCodes.insert(currencyCode, at: 0)
        }
        
        for currencyCode in currencyCodes {
            if let value = valuesDict[currencyCode] {
                return Price(currencyCode: currencyCode, value: Decimal(value), formattingLocale: formattingLocale)
            }
        }
        
        return nil
        
    }
    
    static func parse(_ dictionaries: [[String: Any]], currencyCode: String? = nil, formattingLocale: Locale = Locale.current) -> Price? {
        
        var currencyCodes = OrderManager.shared.prioritizedCurrencyCodes
        if let currencyCode = currencyCode {
            currencyCodes.insert(currencyCode, at: 0)
        }
        
        for currencyCode in currencyCodes {
            for dictionary in dictionaries {
                if let currency = dictionary["currency"] as? String,
                    currency == currencyCode,
                    let value = dictionary["amount"] as? Double {
                    return Price(currencyCode: currencyCode, value: Decimal(value), formattingLocale: formattingLocale)
                }
            }
        }
        
        return nil
    }
    
}

extension Price : Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return
            lhs.currencyCode == rhs.currencyCode &&
                lhs.value ==~ rhs.value
    }
}
