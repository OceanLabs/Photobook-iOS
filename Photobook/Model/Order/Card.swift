//
//  Card.swift
//  Shopify
//
//  Created by Jaime Landazuri on 12/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

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
