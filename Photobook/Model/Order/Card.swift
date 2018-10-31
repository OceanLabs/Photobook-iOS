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

import UIKit

struct Card {

    private var isAmex: Bool {
        return number.cardType() == .amex
    }

    static var currentCard: Card? = nil
    
    var number: String
    var numberMasked: String {
        let dots = isAmex ? "•••• •••••• " : "•••• •••• •••• "
        if let index = number.range(of: " ", options: .backwards)?.upperBound {
            return dots + number[index...]
        }
        let offset = isAmex ? -5 : -4
        return dots + String(number[number.index(number.endIndex, offsetBy: offset)...])
    }
    var expireMonth: Int
    var expireYear: Int
    var cvv2: String
    
    var cardIcon: UIImage {
        guard let cardType = number.cardType() else {
            return UIImage(namedInPhotobookBundle: "generic-card")!
        }
        
        switch cardType {
        case .amex:
            return UIImage(namedInPhotobookBundle: "amex-logo")!
        case .visa:
            return UIImage(namedInPhotobookBundle: "visa-logo")!
        case .mastercard:
            return UIImage(namedInPhotobookBundle: "mastercard-logo")!
        default:
            return UIImage(namedInPhotobookBundle: "generic-card")!
        }
    }
    
    init(number: String, expireMonth: Int, expireYear: Int, cvv2: String) {
        self.number = number
        self.expireMonth = expireMonth
        self.expireYear = expireYear
        self.cvv2 = cvv2
    }
}
