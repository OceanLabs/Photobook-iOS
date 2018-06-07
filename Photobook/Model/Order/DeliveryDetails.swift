//
//  DeliveryDetails.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 23/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class DeliveryDetails: NSCopying, Codable {
    
    static let savedDetailsKey = "ly.kite.sdk.savedDetailsKey"
    
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var address: Address?
    
    var isValid: Bool {
        get {
            guard let firstName = firstName, !firstName.isEmpty,
                let lastName = lastName, !lastName.isEmpty,
                let address = address, address.isValid,
                let email = email, email.isValidEmailAddress(),
                let phone = phone, phone.count >= FormConstants.minPhoneNumberLength
                else { return false }
            
            return true
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = DeliveryDetails()
        copy.firstName = firstName
        copy.lastName = lastName
        copy.email = email
        copy.phone = phone
        copy.address = address?.copy() as? Address
        
        return copy
    }
    
    func saveDetailsAsLatest() {
        guard let detailsData = try? PropertyListEncoder().encode(self) else { return }
        
        UserDefaults.standard.set(detailsData, forKey: DeliveryDetails.savedDetailsKey)
        UserDefaults.standard.synchronize()
    }
    
    static func loadLatestDetails() -> DeliveryDetails? {
        guard let detailsData = UserDefaults.standard.object(forKey: DeliveryDetails.savedDetailsKey) as? Data else { return nil }
        return try? PropertyListDecoder().decode(DeliveryDetails.self, from: detailsData)
    }
    
    var fullName: String? {
        guard !(firstName == nil && lastName == nil) else { return nil }
        return String(format: "%@ %@", firstName ?? "", lastName ?? "").trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

func ==(lhs: DeliveryDetails, rhs: DeliveryDetails) -> Bool{
    return lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.email == rhs.email
        && lhs.phone == rhs.phone
        && lhs.address == rhs.address
}

extension DeliveryDetails: Hashable {
    
    /// Only the address matters
    var hashValue: Int {
        return address?.hashValue ?? 0
    }
    
}

