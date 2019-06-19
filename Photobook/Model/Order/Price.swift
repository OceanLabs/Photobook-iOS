//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

struct Price: Codable {
    
    let currencyCode: String
    let value: Decimal
    let formatted: String
    private let formattingLocale: Locale
    
    init(currencyCode: String, value: Decimal, formattingLocale: Locale = Locale.current) {
        var decimalNumberValue = value as NSDecimalNumber
        decimalNumberValue = decimalNumberValue.rounding(accordingToBehavior: CurrencyRoundingBehavior())
        
        self.currencyCode = currencyCode
        self.value = decimalNumberValue as Decimal
        self.formattingLocale = formattingLocale
        
        if value > 0 {
            formatted = value.formattedCost(currencyCode: currencyCode, locale: formattingLocale)
        } else {
            formatted = NSLocalizedString("Model/Order/Price/FormattedFree", value: "Free", comment: "Text that gets displayed if a price is 0.0").uppercased()
        }
    }
    
    func int() -> Int {
        if let intPrice = Int(formatted) {
            return intPrice * 100
        }
        return Int(formatted.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!
    }
    
    static func parse(_ dictionary: [String: Any], prioritizedCurrencyCodes: [String] = OrderManager.shared.prioritizedCurrencyCodes, formattingLocale: Locale = Locale.current) -> Price? {
        
        var prices: [String: Any]!
        if let doubleValues = dictionary as? [String: Double] {
            prices = doubleValues
        } else if let stringValues = dictionary as? [String: String] {
            prices = stringValues
        } else {
            return nil
        }
        
        for currencyCode in prioritizedCurrencyCodes {
            var value: Decimal!
            if let doubleValue = prices[currencyCode] as? Double {
                value = Decimal(doubleValue)
            } else if let stringValue = prices[currencyCode] as? String {
                value = Decimal(string: stringValue)
            }
            if value == nil { continue }
            return Price(currencyCode: currencyCode, value: value!, formattingLocale: formattingLocale)
        }
        
        return nil
    }
    
    static func parse(_ dictionaries: [[String: Any]], prioritizedCurrencyCodes: [String] = OrderManager.shared.prioritizedCurrencyCodes, formattingLocale: Locale = Locale.current) -> Price? {
        
        for currencyCode in prioritizedCurrencyCodes {
            for dictionary in dictionaries {
                if let currency = dictionary["currency"] as? String,
                    currency == currencyCode {
                    if let value = dictionary["amount"] as? Double {
                        return Price(currencyCode: currencyCode, value: Decimal(value), formattingLocale: formattingLocale)
                    }
                    if let valueString = dictionary["amount"] as? String,
                        let value = Double(valueString) {
                        return Price(currencyCode: currencyCode, value: Decimal(value), formattingLocale: formattingLocale)
                    }
                }
            }
        }
        
        return nil
    }
}

extension Price: Equatable {
    static func == (lhs: Price, rhs: Price) -> Bool {
        return
            lhs.currencyCode == rhs.currencyCode &&
                lhs.value ==~ rhs.value
    }
}
