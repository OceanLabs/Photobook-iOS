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
    
    func formattedCost(currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: self as NSNumber)!
    }
    
    static func ==~(lhs: Decimal, rhs: Decimal) -> Bool {
        let difference = abs(lhs - rhs)
        
        if lhs == rhs {
            return true
        } else if lhs == 0.0 || rhs == 0.0 || difference < Decimal.leastNormalMagnitude {
            return difference < (minPrecision * Decimal.leastNormalMagnitude)
        } else {
            let absA = abs(lhs)
            let absB = abs(rhs)
            
            return difference / (absA + absB) < minPrecision
        }
    }
}
