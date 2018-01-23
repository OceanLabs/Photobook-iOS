//
//  DecimalExtensions.swift
//  Shopify
//
//  Created by Jaime Landazuri on 20/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

extension Decimal {
    
    func formattedCost(currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: self as NSNumber)!
    }
    
}
