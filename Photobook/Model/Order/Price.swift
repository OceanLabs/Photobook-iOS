//
//  Price.swift
//  Photobook
//
//  Created by Julian Gruber on 05/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct Price: Codable {
    
    private static let currencyCodeDefault = "GBP"
    
    private(set) var currencyCode: String
    private(set) var value: Decimal
    private(set) var formatted: String
    
    init?(currencyCode: String, value: Decimal) {
        self.currencyCode = currencyCode
        self.value = value
        
        //formatted string
        if value > 0 {
            self.formatted = value.formattedCost(currencyCode: currencyCode)
        } else {
            self.formatted = NSLocalizedString("Model/Order/Price/FormattedFree", value: "Free", comment: "Text that gets displayed if a price is 0.0").uppercased()
        }
    }
    
    static func parse(_ dictionary: [String: Any], localeCurrencyCode: String? = Locale.current.currencyCode) -> Price? {
        
        guard let valuesDict = dictionary as? [String: Double] else {
            return nil
        }
        
        var currencyCode = currencyCodeDefault
        var value: Decimal?
        if let localeCurrency = localeCurrencyCode, let v = valuesDict[localeCurrency] { //locale currency available
            currencyCode = localeCurrency
            value = Decimal(v)
        } else if let v = valuesDict[currencyCode] { //default currency
            value = Decimal(v)
        } else { return nil } //failed to retrieve value
        
        return Price(currencyCode: currencyCode, value: value!)
    }
    
    static func parse(_ dictionaries: [[String: Any]], localeCurrencyCode: String? = Locale.current.currencyCode) -> Price? {
        
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
        
        return Price(currencyCode: currencyCode, value: Decimal(value))
    }
    
}

extension Price : Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return
            lhs.currencyCode == rhs.currencyCode &&
                lhs.value ==~ rhs.value &&
                lhs.formatted == rhs.formatted
    }
}
