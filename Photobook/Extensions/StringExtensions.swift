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
