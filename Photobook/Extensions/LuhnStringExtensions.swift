//
//  Luhn.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 05/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

enum CreditCardType {
    case amex
    case visa
    case mastercard
    case discover
    case dinersClub
    case jcb
    case unsupported
    case invalid
    
    static func all() -> [CreditCardType]{
        return [CreditCardType.amex, CreditCardType.visa, CreditCardType.mastercard, CreditCardType.discover, CreditCardType.dinersClub, CreditCardType.jcb]
    }
}

extension String {
    
    fileprivate func formattingForProcessing() -> String {
        let illegalCharacters = CharacterSet.decimalDigits.inverted
        let componentsArray = components(separatedBy: illegalCharacters)
        
        return componentsArray.joined(separator: "")
    }
    
    func isValidCreditCardNumber() -> Bool{
        let formattedString = formattingForProcessing()
        guard formattedString.count >= 9 else { return false}
        
        var reversedString = String()
        
        (formattedString as NSString).enumerateSubstrings(in: NSMakeRange(0, formattedString.count), options: [.reverse, .byComposedCharacterSequences], using: {(substring:String?, substringRange:NSRange, enclosureRange:NSRange, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            if let substring = substring{
                reversedString.append(substring)
            }
        })
        
        var oddSum = 0, evenSum = 0
        
        for var i in 0 ..< reversedString.count {
            guard let digit = Int(String(reversedString[index(startIndex, offsetBy: i)])) else { return false }
            
            if i % 2 == 0{
                evenSum += digit
            }
            else{
                oddSum += digit / 5 + (2 * digit) % 10
            }
            
            i += 1
        }
        
        return (oddSum + evenSum) % 10 == 0
    }
    
    func creditCardType() -> CreditCardType {
        let valid = self.isValidCreditCardNumber()
        if !valid { return .invalid }
        
        let formattedString = formattingForProcessing()
        guard formattedString.count >= 9 else { return .invalid }
        
        for creditCardType in CreditCardType.all(){
            let currentTypePredicate = predicate(type: creditCardType)
            if let isCurrent = currentTypePredicate?.evaluate(with: formattedString), isCurrent == true{
                return creditCardType
            }
        }
        
        return .invalid
    }
}

fileprivate func predicate(type:CreditCardType) -> NSPredicate?{
    if type == .invalid || type == .unsupported{
        return nil
    }
    
    var regex: String
    
    switch type {
    case .amex:
        regex = "^3[47][0-9]{5,}$"
    case .dinersClub:
        regex = "^3(?:0[0-5]|[68][0-9])[0-9]{4,}$"
    case .discover:
        regex = "^6(?:011|5[0-9]{2})[0-9]{3,}$"
    case .jcb:
        regex = "^(?:2131|1800|35[0-9]{3})[0-9]{3,}$"
    case .mastercard:
        regex = "^5[1-5][0-9]{5,}$"
    case .visa:
        regex = "^4[0-9]{6,}$"
    default:
        regex = ""
    }
    
    return NSPredicate(format: "SELF MATCHES %@", regex)
}
