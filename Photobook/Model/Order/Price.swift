//
//  Price.swift
//  Photobook
//
//  Created by Julian Gruber on 05/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

struct Price: Codable {
    
    private static let currencyCodeDefault = "GBP"
    
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
    
    static func parse(_ dictionary: [String: Any], localeCurrencyCode: String? = Locale.current.currencyCode, formattingLocale: Locale = Locale.current) -> Price? {
        
        guard let valuesDict = dictionary as? [String: Double] else {
            return nil
        }
        
        var currencyCode = currencyCodeDefault
        var value: Decimal
        if let localeCurrency = localeCurrencyCode, let v = valuesDict[localeCurrency] { //locale currency available
            currencyCode = localeCurrency
            value = Decimal(v)
        } else if let v = valuesDict[currencyCode] { //default currency
            value = Decimal(v)
        } else { return nil } //failed to retrieve value
        
        return Price(currencyCode: currencyCode, value: value, formattingLocale: formattingLocale)
    }
    
    static func parse(_ dictionaries: [[String: Any]], localeCurrencyCode: String? = Locale.current.currencyCode, formattingLocale: Locale = Locale.current) -> Price? {
        
        var relevantDictionary = dictionaries.first
        
        if let localCurrencyCode = localeCurrencyCode {
            for dictionary in dictionaries {
                if let currency = dictionary["currency"] as? String, currency == localCurrencyCode {
                    relevantDictionary = dictionary
                    break
                }
            }
        }
        
        guard let currencyCode = relevantDictionary?["currency"] as? String, let value = relevantDictionary?["amount"] as? Double else {
            return nil
        }
        
        return Price(currencyCode: currencyCode, value: Decimal(value), formattingLocale: formattingLocale)
    }
    
}

extension Price : Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return
            lhs.currencyCode == rhs.currencyCode &&
                lhs.value ==~ rhs.value
    }
}
