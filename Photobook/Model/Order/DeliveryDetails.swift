//
//  DeliveryDetails.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 23/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class DeliveryDetails: NSObject, NSCopying, NSSecureCoding {
    static var supportsSecureCoding = true
    
    private struct Constants {
        static let savedDetailsKey = "savedDetailsKey"
    }
    static let minPhoneNumberLength = 5
    
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var address: Address?
    
    var isValid: Bool {
        get{
            guard let firstName = firstName, !firstName.isEmpty,
                let lastName = lastName, !lastName.isEmpty,
                let address = address, address.isValid,
                let email = email, email.isValidEmailAddress(),
                let phone = phone, phone.count >= DeliveryDetails.minPhoneNumberLength
                else { return false }
            
            return true
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder){
        self.init()
        self.firstName = aDecoder.decodeObject(forKey: "firstName") as? String
        self.lastName = aDecoder.decodeObject(forKey: "lastName") as? String
        self.email = aDecoder.decodeObject(forKey: "email") as? String
        self.phone = aDecoder.decodeObject(forKey: "phone") as? String
        self.address = aDecoder.decodeObject(forKey: "address") as? Address
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(firstName, forKey: "firstName")
        aCoder.encode(lastName, forKey: "lastName")
        aCoder.encode(email, forKey: "email")
        aCoder.encode(phone, forKey: "phone")
        aCoder.encode(address, forKey: "address")
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
        guard let details = ProductManager.shared.deliveryDetails else { return }
        let detailsData = NSKeyedArchiver.archivedData(withRootObject: details)
        UserDefaults.standard.set(detailsData, forKey: Constants.savedDetailsKey)
        UserDefaults.standard.synchronize()
    }
    
    static func loadLatestDetails() -> DeliveryDetails? {
        guard let detailsData = UserDefaults.standard.object(forKey: Constants.savedDetailsKey) as? Data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: detailsData) as? DeliveryDetails
    }
    
    func fullName() -> String?{
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

