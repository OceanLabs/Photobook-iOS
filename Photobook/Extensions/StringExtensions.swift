//
//  StringExtensions.swift
//  Shopify
//
//  Created by Jaime Landazuri on 19/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

extension String {
    
    func capitaliseFirst() -> String {
        return self[self.startIndex ..< self.index(startIndex, offsetBy: 1)].uppercased() +
               self[self.index(startIndex, offsetBy: 1) ..< self.endIndex]
    }
    
    func isValidEmailAddress() -> Bool {
        let emailRegex = "(?:[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-zA-Z0-9](?:[a-z0-9-]*[a-zA-Z0-9])?\\.)+[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-zA-Z0-9-]*[a-zA-Z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with:self)
    }
    
    func creditCardFormatted() -> String {
        var input = self.replacingOccurrences(of: " ", with: "")
        input = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let isAmex = input.hasPrefix("34") || input.hasPrefix("37")
        
        var result = ""
        let count = input.count
        let maxCharacters = isAmex ? 15 : 16
        
        var i = 0
        let upperBound = min(count, maxCharacters)
        while i < upperBound {
            var step: Int
            if isAmex {
                step = i == 0 ? 4 : (i == 4 ? 6 : 5)
            } else {
                step = 4
            }
            
            let startIndex = input.index(input.startIndex, offsetBy: i)
            let endIndex = input.index(input.startIndex, offsetBy: min(i + step - 1, count - 1))
            result += input[startIndex...endIndex] + " "
            i += step
        }
        return result.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
}
