//
//  DecimalExtensions.swift
//  Shopify
//
//  Created by Jaime Landazuri on 20/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

extension Decimal {
    
    static let minPrecision: Decimal = 0.01
    
    func formattedCost(currencyCode: String, locale: Locale? = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.string(from: self as NSNumber)!
    }
    
    static func ==~(lhs: Decimal, rhs: Decimal) -> Bool {
        if lhs == rhs { return true }
        return abs(lhs - rhs) < minPrecision
    }
}
